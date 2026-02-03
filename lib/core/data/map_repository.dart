import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/map_models.dart';
import '../utils/map_logger.dart';
import '../utils/map_metrics.dart';

class MapRepository {
  static const String _kPublicationsCacheKey = 'cache_publications_v1';
  static const String _kLayersCacheKey = 'cache_layers_v1';

  // -- Network State --

  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      MapLogger.logEvent('Network Check: ${isOnline ? "Online" : "Offline"}');
      return isOnline;
    } catch (_) {
      MapLogger.logEvent('Network Check: Offline (Error)');
      return false;
    }
  }

  // -- Publications Flow --

  Future<List<Publication>> fetchPublications() async {
    // Observability: Load metrics from disk on start
    await MapMetrics.loadMetrics();

    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_kPublicationsCacheKey);
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

    // 2. Initial Fallback (Only if cache empty)
    try {
      if (await _isOnline()) {
        MapLogger.logEvent('Local Cache Empty. Fetching Remote...');
        // Simulate remote extraction
        await Future.delayed(const Duration(milliseconds: 500));
        final remoteData = _getMockPublications();

        await _savePublicationsToCache(remoteData);
        return remoteData;
      } else {
        MapLogger.logEvent('Offline and Cache Empty.');
        return [];
      }
    } catch (e, s) {
      MapLogger.logError('Fetch Initial failed', s);
      return [];
    }
  }

  Future<void> addPublication(Publication pub) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_kPublicationsCacheKey);
    List<Publication> currentList = [];

    if (cachedString != null) {
      try {
        final decoded = jsonDecode(cachedString);
        currentList = (decoded['data'] as List)
            .map((e) => Publication.fromJson(e))
            .toList();
      } catch (_) {}
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
    if (await _isOnline()) {
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

    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_kPublicationsCacheKey);
    if (cachedString == null) return;

    try {
      final decoded = jsonDecode(cachedString);
      List<Publication> currentList = (decoded['data'] as List)
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
      await MapMetrics.persistMetrics();
    } catch (e, s) {
      MapLogger.logError('Sync Process Error', s);
    }
  }

  Future<void> _savePublicationsToCache(List<Publication> list) async {
    final prefs = await SharedPreferences.getInstance();
    final cachePayload = {
      'timestamp': DateTime.now().toIso8601String(),
      'data': list.map((e) => e.toJson()).toList(),
    };
    await prefs.setString(_kPublicationsCacheKey, jsonEncode(cachePayload));
  }

  // -- Layers (ReadOnly Config) --

  Future<List<MapLayer>> fetchLayers() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_kLayersCacheKey);
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
      final remoteData = _getMockLayers();
      final cachePayload = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': remoteData.map((e) => e.toJson()).toList(),
      };
      await prefs.setString(_kLayersCacheKey, jsonEncode(cachePayload));
      return remoteData;
    } catch (e, s) {
      MapLogger.logError('Fetch Layers failed', s);
      return [];
    }
  }

  List<MapLayer> getAvailableLayers() {
    return _getMockLayers();
  }

  // -- Mocks --

  List<Publication> _getMockPublications() {
    return [
      Publication(
        id: '1',
        userName: 'Carlos Silva',
        userRole: 'Consultor Técnico',
        description:
            'Praga identificada na soja. Recomendo aplicação imediata.',
        location: LatLng(-23.555, -46.638),
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        syncStatus: SyncStatus.synced, // Mock data is already synced
      ),
      Publication(
        id: '2',
        userName: 'Ana Souza',
        userRole: 'Agrônoma',
        description: 'Análise de solo concluída. pH ideal para plantio.',
        location: LatLng(-23.548, -46.628),
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Publication(
        id: '3',
        userName: 'Roberto Dias',
        userRole: 'Gerente',
        description: 'Visita de campo realizada. Tudo conforme o planejado.',
        location: LatLng(-23.560, -46.645),
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  List<MapLayer> _getMockLayers() {
    return [
      MapLayer(
        id: 'std',
        name: 'Padrão',
        type: LayerType.standard,
        isVisible: true,
      ),
      MapLayer(id: 'sat', name: 'Satélite', type: LayerType.satellite),
      MapLayer(id: 'ter', name: 'Relevo', type: LayerType.terrain),
    ];
  }
}
