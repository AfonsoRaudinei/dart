import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

/// Forward geocoding: município + UF → coordenadas para previsão climática.
class CityGeocoder {
  CityGeocoder._();

  static final CityGeocoder instance = CityGeocoder._();

  static const Duration _timeout = Duration(seconds: 6);
  final Map<String, ClimaLatLon> _cache = {};

  /// Resolve `"Município, UF, Brasil"` para lat/lon. Retorna null se falhar.
  Future<ClimaLatLon?> resolve({
    required String municipio,
    required String uf,
  }) async {
    final cacheKey = '${municipio.trim().toLowerCase()}|$uf';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      await setLocaleIdentifier('pt_BR');
      final address = '$municipio, $uf, Brasil';
      final locations = await locationFromAddress(address).timeout(_timeout);
      if (locations.isEmpty) return null;

      final loc = locations.first;
      final result = (lat: loc.latitude, lon: loc.longitude);
      _cache[cacheKey] = result;
      return result;
    } on TimeoutException {
      AppLogger.debug('timeout para $municipio, $uf', tag: 'CityGeocoder');
      return null;
    } catch (e) {
      AppLogger.error('falha para $municipio, $uf', tag: 'CityGeocoder', error: e);
      return null;
    }
  }

  @visibleForTesting
  void clearCache() => _cache.clear();
}
