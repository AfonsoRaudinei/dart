import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

/// Converte lat/lon em "Cidade, UF" usando os serviços nativos de
/// reverse geocoding do iOS (CLGeocoder) e Android (Geocoder).
///
/// Características:
/// - Cache em memória por sessão, com arredondamento da chave para evitar
///   chamadas redundantes quando o GPS oscila poucos metros.
/// - Timeout curto e fallback gracioso para `"Local atual"`. Nunca lança.
/// - Localização forçada em pt-BR para evitar nomes em inglês no iOS.
///
/// Pertence ao bounded context `clima/`. Não é exposto fora dele.
class ReverseGeocoder {
  ReverseGeocoder._();

  static final ReverseGeocoder instance = ReverseGeocoder._();

  static const Duration _timeout = Duration(seconds: 4);
  static const String _fallbackLabel = 'Local atual';

  /// Precisão da chave do cache (3 casas ≈ 110 m).
  /// Suficiente para um nome de cidade — evita lookups quando o GPS oscila.
  static const int _cacheKeyPrecision = 3;

  final Map<String, String> _cache = <String, String>{};

  /// Resolve lat/lon para "Cidade, UF" (ex.: "Porto Nacional, TO").
  /// Sempre retorna um valor — em caso de erro/timeout devolve `"Local atual"`.
  Future<String> resolveCityLabel({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey = _buildCacheKey(latitude, longitude);
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      // Localização em pt-BR para garantir "Tocantins" em vez de "Tocantins State".
      await setLocaleIdentifier('pt_BR');

      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(_timeout);

      final label = _composeLabel(placemarks);
      _cache[cacheKey] = label;
      return label;
    } on TimeoutException {
      debugPrint('[ReverseGeocoder] timeout em ($latitude, $longitude)');
      return _fallbackLabel;
    } catch (e) {
      debugPrint('[ReverseGeocoder] falha em ($latitude, $longitude): $e');
      return _fallbackLabel;
    }
  }

  /// Limpa o cache. Útil em testes.
  @visibleForTesting
  void clearCache() => _cache.clear();

  String _buildCacheKey(double lat, double lon) {
    final roundedLat = lat.toStringAsFixed(_cacheKeyPrecision);
    final roundedLon = lon.toStringAsFixed(_cacheKeyPrecision);
    return '$roundedLat,$roundedLon';
  }

  String _composeLabel(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return _fallbackLabel;

    // Itera nos placemarks (iOS pode retornar vários) escolhendo o primeiro
    // que tenha uma cidade utilizável.
    for (final p in placemarks) {
      final city = _pickCity(p);
      if (city == null) continue;

      final uf = _pickUf(p);
      return uf == null ? city : '$city, $uf';
    }

    return _fallbackLabel;
  }

  String? _pickCity(Placemark p) {
    final candidates = <String?>[
      p.subAdministrativeArea, // costuma ser o município no Brasil
      p.locality,
      p.administrativeArea,
    ];
    for (final c in candidates) {
      final trimmed = c?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  /// Tenta extrair a sigla de UF (2 letras) a partir do `administrativeArea`,
  /// que no Brasil traz nomes como "Tocantins" ou "TO".
  String? _pickUf(Placemark p) {
    final raw = p.administrativeArea?.trim();
    if (raw == null || raw.isEmpty) return null;

    if (raw.length == 2) return raw.toUpperCase();

    const map = <String, String>{
      'acre': 'AC',
      'alagoas': 'AL',
      'amapá': 'AP',
      'amapa': 'AP',
      'amazonas': 'AM',
      'bahia': 'BA',
      'ceará': 'CE',
      'ceara': 'CE',
      'distrito federal': 'DF',
      'espírito santo': 'ES',
      'espirito santo': 'ES',
      'goiás': 'GO',
      'goias': 'GO',
      'maranhão': 'MA',
      'maranhao': 'MA',
      'mato grosso': 'MT',
      'mato grosso do sul': 'MS',
      'minas gerais': 'MG',
      'pará': 'PA',
      'para': 'PA',
      'paraíba': 'PB',
      'paraiba': 'PB',
      'paraná': 'PR',
      'parana': 'PR',
      'pernambuco': 'PE',
      'piauí': 'PI',
      'piaui': 'PI',
      'rio de janeiro': 'RJ',
      'rio grande do norte': 'RN',
      'rio grande do sul': 'RS',
      'rondônia': 'RO',
      'rondonia': 'RO',
      'roraima': 'RR',
      'santa catarina': 'SC',
      'são paulo': 'SP',
      'sao paulo': 'SP',
      'sergipe': 'SE',
      'tocantins': 'TO',
    };
    return map[raw.toLowerCase()];
  }
}
