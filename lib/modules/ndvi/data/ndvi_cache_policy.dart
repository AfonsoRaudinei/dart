import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';

const Duration kNdviCacheTtl = Duration(hours: 24);

/// Controla TTL e invalidação do cache NDVI por talhão.
abstract interface class NdviCachePolicy {
  Future<bool> shouldInvalidate(String fieldId, String originFingerprint);

  Future<void> markSynced(String fieldId, String originFingerprint);

  Future<void> clear(String fieldId);
}

String ndviOriginFingerprint(FieldSummary summary) {
  final bbox = summary.bbox?.join(',') ?? '';
  final geometry = summary.geometry ?? '';
  return '$bbox|$geometry';
}

class PreferencesNdviCachePolicy implements NdviCachePolicy {
  PreferencesNdviCachePolicy(this._prefs);

  final PreferencesService _prefs;

  String _fingerprintKey(String fieldId) => 'ndvi_fp_$fieldId';
  String _syncedAtKey(String fieldId) => 'ndvi_sync_$fieldId';

  @override
  Future<bool> shouldInvalidate(String fieldId, String originFingerprint) async {
    final storedFingerprint = _prefs.getString(_fingerprintKey(fieldId));
    final syncedAtRaw = _prefs.getString(_syncedAtKey(fieldId));
    if (storedFingerprint == null || syncedAtRaw == null) return true;
    if (storedFingerprint != originFingerprint) return true;

    final syncedAt = DateTime.tryParse(syncedAtRaw);
    if (syncedAt == null) return true;
    return DateTime.now().difference(syncedAt) > kNdviCacheTtl;
  }

  @override
  Future<void> markSynced(String fieldId, String originFingerprint) async {
    await _prefs.setString(_fingerprintKey(fieldId), originFingerprint);
    await _prefs.setString(
      _syncedAtKey(fieldId),
      DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> clear(String fieldId) async {
    await _prefs.remove(_fingerprintKey(fieldId));
    await _prefs.remove(_syncedAtKey(fieldId));
  }
}

/// Política em memória para testes unitários.
class InMemoryNdviCachePolicy implements NdviCachePolicy {
  final Map<String, String> fingerprints = {};
  final Map<String, DateTime> syncedAt = {};
  Duration ttl = kNdviCacheTtl;
  DateTime Function() clock = DateTime.now;

  @override
  Future<bool> shouldInvalidate(String fieldId, String originFingerprint) async {
    final storedFingerprint = fingerprints[fieldId];
    final synced = syncedAt[fieldId];
    if (storedFingerprint == null || synced == null) return true;
    if (storedFingerprint != originFingerprint) return true;
    return clock().difference(synced) > ttl;
  }

  @override
  Future<void> markSynced(String fieldId, String originFingerprint) async {
    fingerprints[fieldId] = originFingerprint;
    syncedAt[fieldId] = clock();
  }

  @override
  Future<void> clear(String fieldId) async {
    fingerprints.remove(fieldId);
    syncedAt.remove(fieldId);
  }
}
