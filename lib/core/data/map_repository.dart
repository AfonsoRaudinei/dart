import 'dart:convert';
import '../infra/preferences_service.dart';
import '../services/connectivity_service.dart';
import '../domain/map_models.dart';
import '../domain/publicacao.dart';
import '../utils/app_logger.dart';
import '../utils/map_logger.dart';
import '../utils/map_metrics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapRepository {
  MapRepository(this._prefs, this._connectivity);

  final PreferencesService _prefs;
  final ConnectivityService _connectivity;

  static const String _kPublicationsCacheKey = 'cache_publications_v1';
  static const String _kLayersCacheKey = 'cache_layers_v1';

  // -- Publications Flow (Legacy — @deprecated, use fetchPublicacoes/addPublicacao) --

  @Deprecated('Use fetchPublicacoes() instead — ADR-007')
  Future<List<Publication>> fetchPublications() async {
    // Observability: Load metrics from disk on start
    await MapMetrics.loadMetrics(_prefs);

    final cachedString = _prefs.getString(_kPublicationsCacheKey);
    List<Publication>? cachedData;

    // 1. Local Source of Truth
    if (cachedString != null) {
      try {
        final decoded = jsonDecode(cachedString);
        final List dataList = decoded['data'];
        cachedData = dataList.map((e) => Publication.fromJson(e)).toList();

        MapLogger.logEvent(
          'Publications: Loaded ${cachedData.length} items from local cache',
        );

        // Trigger background sync if online
        _triggerBackgroundSync();

        return cachedData;
      } catch (e, s) {
        MapLogger.logError('Failed to parse local cache', s);
      }
    }

    final publicacoes = await fetchPublicacoes();
    final publications = publicacoes.map(_publicationFromPublicacao).toList();
    await _savePublicationsToCache(publications);
    MapLogger.logEvent(
      'Publications: Legacy cache vazio. Loaded ${publications.length} canonical items.',
    );
    return publications;
  }

  @Deprecated('Use addPublicacao() instead — ADR-007')
  Future<void> addPublication(Publication pub) async {
    final cachedString = _prefs.getString(_kPublicationsCacheKey);
    List<Publication> currentList = [];

    if (cachedString != null) {
      try {
        final decoded = jsonDecode(cachedString);
        currentList = (decoded['data'] as List)
            .map((e) => Publication.fromJson(e))
            .toList();
      } catch (e) {
        AppLogger.warning(
          'Cache de publications corrompido — descartando',
          tag: 'MapRepo',
          error: e,
        );
      }
    }

    // Add with Pending Status
    final newPub = pub.copyWith(syncStatus: SyncStatus.pending);
    currentList.add(newPub);

    await _savePublicationsToCache(currentList);
    MapLogger.logEvent('Publication Added Locally (Pending): ${newPub.id}');

    // Try Sync
    _triggerBackgroundSync();
  }

  Future<void> _triggerBackgroundSync() async {
    if (await _connectivity.isConnected) {
      await _syncPublications();
    } else {
      MapLogger.logEvent('Sync Skipped: Device Offline');
    }
  }

  Duration _calculateBackoffDelay(int retryCount) {
    if (retryCount <= 0) return Duration.zero;
    if (retryCount == 1) return const Duration(seconds: 5);
    if (retryCount == 2) return const Duration(seconds: 15);
    if (retryCount == 3) return const Duration(seconds: 60);
    return const Duration(minutes: 5);
  }

  Future<void> _syncPublications() async {
    MapLogger.logEvent('Starting Sync (Retry aware)...');

    final cachedString = _prefs.getString(_kPublicationsCacheKey);
    if (cachedString == null) return;

    try {
      final decoded = jsonDecode(cachedString);
      // ignore: deprecated_member_use_from_same_package
      List<Publication> currentList = (decoded['data'] as List)
          // ignore: deprecated_member_use_from_same_package
          .map((e) => Publication.fromJson(e))
          .toList();
      bool listModified = false;

      for (var i = 0; i < currentList.length; i++) {
        final pub = currentList[i];
        bool shouldAttemptSync = false;

        // 1. Pending items always sync
        if (pub.syncStatus == SyncStatus.pending) {
          shouldAttemptSync = true;
        }
        // 2. Error items sync only if backoff expired
        else if (pub.syncStatus == SyncStatus.error) {
          final backoff = _calculateBackoffDelay(pub.retryCount);
          final lastRetry =
              pub.lastRetryAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final diff = DateTime.now().difference(lastRetry);

          if (diff > backoff) {
            shouldAttemptSync = true;
            MapLogger.logEvent(
              'Retry Backoff Expired for ${pub.id}. Retrying (Attempt #${pub.retryCount + 1})...',
            );
          } else {
            MapLogger.logEvent(
              'Retry postponed for ${pub.id}. Wait ${backoff.inSeconds - diff.inSeconds}s more.',
            );
          }
        }

        if (shouldAttemptSync) {
          // Observability: Start
          MapMetrics.recordSyncAttempt();
          if (pub.retryCount > 0) {
            MapMetrics.recordRetry(pub.retryCount);
          }
          final stopwatch = Stopwatch()..start();

          try {
            // Simulate Upload
            await Future.delayed(
              const Duration(milliseconds: 300),
            ); // Network simulation

            // SUCCESS
            currentList[i] = pub.copyWith(
              syncStatus: SyncStatus.synced,
              // Optional: reset retry counts on success, or keep for audit
            );
            listModified = true;

            // Observability: Success
            stopwatch.stop();
            MapMetrics.recordSyncResult(
              success: true,
              latencyMs: stopwatch.elapsedMilliseconds,
            );
            MapLogger.logEvent('Synced Item: ${pub.id}');
          } catch (e) {
            // FAILURE
            stopwatch.stop();

            // Observability: Failure
            MapMetrics.recordSyncResult(
              success: false,
              latencyMs: stopwatch.elapsedMilliseconds,
            );

            final newCount = pub.retryCount + 1;
            currentList[i] = pub.copyWith(
              syncStatus: SyncStatus.error,
              retryCount: newCount,
              lastRetryAt: DateTime.now(),
            );
            listModified = true;
            MapLogger.logEvent(
              'Sync Failed for Item: ${pub.id}. New RetryCount: $newCount',
            );
          }
        }
      }

      if (listModified) {
        await _savePublicationsToCache(currentList);
        MapLogger.logEvent('Sync Complete. Local Cache Updated.');
      } else {
        MapLogger.logEvent('Sync Complete. No items processed.');
      }

      // Observability: Log Aggregated Metrics
      MapMetrics.logMetrics();
      await MapMetrics.persistMetrics(_prefs);
    } catch (e, s) {
      MapLogger.logError('Sync Process Error', s);
    }
  }

  // ignore: deprecated_member_use_from_same_package
  Future<void> _savePublicationsToCache(List<Publication> list) async {
    final cachePayload = {
      'timestamp': DateTime.now().toIso8601String(),
      'data': list.map((e) => e.toJson()).toList(),
    };
    await _prefs.setString(_kPublicationsCacheKey, jsonEncode(cachePayload));
  }

  // -- Layers (ReadOnly Config) --

  Future<List<MapLayer>> fetchLayers() async {
    final cachedString = _prefs.getString(_kLayersCacheKey);
    List<MapLayer>? cachedData;

    if (cachedString != null) {
      try {
        final decoded = jsonDecode(cachedString);
        final List dataList = decoded['data'];
        cachedData = dataList.map((e) => MapLayer.fromJson(e)).toList();
        // Since layers are read-only config, we might want to refresh from remote if TTL expired
        // But for v1.5 offline-first focus, we prioritize returning local.
        // We can background refresh if needed, but staying simple as per "read-through" v1.4 base.
        return cachedData;
      } catch (e, s) {
        MapLogger.logError('Failed to parse layers cache', s);
      }
    }

    // Fallback if empty or parsing failed
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final remoteData = _getDefaultLayers();
      final cachePayload = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': remoteData.map((e) => e.toJson()).toList(),
      };
      await _prefs.setString(_kLayersCacheKey, jsonEncode(cachePayload));
      return remoteData;
    } catch (e, s) {
      MapLogger.logError('Fetch Layers failed', s);
      return [];
    }
  }

  List<MapLayer> getAvailableLayers() {
    return _getDefaultLayers();
  }

  // -- Publicacoes (Canonical — ADR-007) --

  static const String _kPublicacoesCacheKey = 'cache_publicacoes_v2';

  Future<List<Publicacao>> fetchPublicacoes() async {
    await MapMetrics.loadMetrics(_prefs);

    final cachedData = _readPublicacoesCache();

    if (await _connectivity.isConnected) {
      try {
        final remoteData = await _fetchPublicacoesFromSupabase();
        await _savePublicacoesToCache(remoteData);
        MapLogger.logEvent(
          'Publicacoes: Loaded ${remoteData.length} items from Supabase',
        );
        return remoteData;
      } catch (e, s) {
        MapLogger.logError('Failed to fetch publicacoes from Supabase', s);
        if (cachedData != null) return cachedData;
      }
    }

    if (cachedData != null) return cachedData;

    MapLogger.logEvent(
      'Publicacoes: sem cache local e backend indisponível — retornando lista vazia.',
    );
    return [];
  }

  Future<List<Publicacao>> fetchPublicPublicacoes() async {
    final publicacoes = await fetchPublicacoes();
    return publicacoes
        .where((item) => item.isVisible && item.status == 'published')
        .toList(growable: false);
  }

  List<Publicacao>? _readPublicacoesCache() {
    final cachedString = _prefs.getString(_kPublicacoesCacheKey);

    if (cachedString != null) {
      try {
        final decoded = jsonDecode(cachedString);
        final List dataList = decoded['data'];
        final cachedData = dataList.map((e) => Publicacao.fromJson(e)).toList();

        MapLogger.logEvent(
          'Publicacoes: Loaded ${cachedData.length} items from local cache',
        );
        return cachedData;
      } catch (e, s) {
        MapLogger.logError('Failed to parse publicacoes cache', s);
      }
    }

    return null;
  }

  Future<List<Publicacao>> _fetchPublicacoesFromSupabase() async {
    final response = await Supabase.instance.client
        .from('publicacoes')
        .select()
        .order('created_at', ascending: false);

    return response
        .map((row) => _publicacaoFromBackendJson(row).ensureCover())
        .toList(growable: false);
  }

  Publicacao _publicacaoFromBackendJson(Map<String, dynamic> json) {
    final media = _parseMedia(json['media'] ?? json['foto_paths']);
    final createdAtValue = json['created_at'] ?? json['createdAt'];

    return Publicacao(
      id: json['id'] as String,
      latitude: _readDouble(json, const ['latitude', 'lat']),
      longitude: _readDouble(json, const ['longitude', 'long', 'lng']),
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
          : DateTime.now(),
      status: (json['status'] as String?) ?? 'draft',
      isVisible:
          (json['is_visible'] as bool?) ?? (json['isVisible'] as bool?) ?? true,
      type: _parsePublicacaoType(json['type'] as String?),
      title: (json['title'] ?? json['titulo']) as String?,
      description: (json['description'] ?? json['descricao']) as String?,
      clientName: (json['client_name'] ?? json['clientName']) as String?,
      areaName: (json['area_name'] ?? json['areaName']) as String?,
      media: media,
    );
  }

  double _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    throw FormatException(
      'Publicacao sem coordenada válida: ${keys.join('/')}',
    );
  }

  PublicacaoType _parsePublicacaoType(String? value) {
    if (value == null || value.isEmpty) return PublicacaoType.institucional;
    final normalized = value.replaceAll('_', '').toLowerCase();
    for (final type in PublicacaoType.values) {
      if (type.name.toLowerCase() == normalized) return type;
    }
    return PublicacaoType.institucional;
  }

  List<MediaItem> _parseMedia(dynamic value) {
    if (value == null) return const [];
    final dynamic decoded = value is String ? jsonDecode(value) : value;
    if (decoded is! List) return const [];

    return decoded
        .asMap()
        .entries
        .map((entry) {
          final item = entry.value;
          if (item is String) {
            return MediaItem(
              id: 'media_${entry.key}',
              path: item,
              isCover: entry.key == 0,
            );
          }
          return MediaItem.fromJson(Map<String, dynamic>.from(item as Map));
        })
        .toList(growable: false);
  }

  @Deprecated('Legacy adapter for Publication cache readers.')
  Publication _publicationFromPublicacao(Publicacao publicacao) {
    return Publication(
      id: publicacao.id,
      userName: publicacao.clientName ?? 'SoloForte',
      userRole: publicacao.areaName ?? 'Publicação',
      description: publicacao.description ?? publicacao.title ?? '',
      location: publicacao.location,
      imageUrl: publicacao.coverMedia.path.isEmpty
          ? null
          : publicacao.coverMedia.path,
      timestamp: publicacao.createdAt,
      updatedAt: publicacao.createdAt,
      syncStatus: SyncStatus.synced,
    );
  }

  Future<Publicacao?> getPublicacaoById(String id) async {
    final publicacoes = await fetchPublicacoes();
    for (final publicacao in publicacoes) {
      if (publicacao.id == id) return publicacao;
    }
    return null;
  }

  Future<void> addPublicacao(Publicacao pub) async {
    final cachedString = _prefs.getString(_kPublicacoesCacheKey);
    List<Publicacao> currentList = [];

    if (cachedString != null) {
      try {
        final decoded = jsonDecode(cachedString);
        currentList = (decoded['data'] as List)
            .map((e) => Publicacao.fromJson(e))
            .toList();
      } catch (e) {
        AppLogger.warning(
          'Cache de publicacoes corrompido — descartando',
          tag: 'MapRepo',
          error: e,
        );
      }
    }

    currentList.add(pub);
    await _savePublicacoesToCache(currentList);
    MapLogger.logEvent('Publicacao Added Locally: ${pub.id}');
  }

  Future<void> updatePublicacao(Publicacao pub) async {
    final publicacoes = await fetchPublicacoes();
    final index = publicacoes.indexWhere((item) => item.id == pub.id);
    if (index == -1) {
      throw StateError('Publicacao não encontrada: ${pub.id}');
    }

    publicacoes[index] = pub.ensureCover();
    await _savePublicacoesToCache(publicacoes);
    MapLogger.logEvent('Publicacao Updated Locally: ${pub.id}');
  }

  Future<void> _savePublicacoesToCache(List<Publicacao> list) async {
    final cachePayload = {
      'timestamp': DateTime.now().toIso8601String(),
      'data': list.map((e) => e.toJson()).toList(),
    };
    await _prefs.setString(_kPublicacoesCacheKey, jsonEncode(cachePayload));
  }

  List<MapLayer> _getDefaultLayers() {
    return [
      MapLayer(id: 'sat', name: 'Satélite', type: LayerType.satellite),
      MapLayer(id: 'ter', name: 'Relevo', type: LayerType.relevo),
    ];
  }
}
