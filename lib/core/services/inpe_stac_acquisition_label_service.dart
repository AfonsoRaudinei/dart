import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/cerrado_satellite_overlay.dart';

/// Rótulos de aquisição honestos via STAC INPE (cache em memória por sessão).
class InpeStacAcquisitionLabelService {
  InpeStacAcquisitionLabelService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  String? _cerradoCached;

  static const _cerradoCollectionUrl =
      'https://data.inpe.br/bdc/stac/v1/collections/mosaic-s2-cerrado-2m-1';

  Future<String> cerradoAcquisitionLabel() async {
    if (_cerradoCached != null) return _cerradoCached!;

    try {
      final response = await _client
          .get(Uri.parse(_cerradoCollectionUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return CerradoSatelliteOverlay.acquisitionLabel;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final extent = json['extent'] as Map<String, dynamic>?;
      final temporal = extent?['temporal'] as Map<String, dynamic>?;
      final interval = temporal?['interval'] as List<dynamic>?;
      if (interval != null && interval.isNotEmpty) {
        final first = interval.first;
        if (first is List && first.length >= 2) {
          final start = DateTime.tryParse(first[0].toString());
          final end = DateTime.tryParse(first[1].toString());
          if (start != null && end != null) {
            _cerradoCached = _formatMonthRange(start, end);
            return _cerradoCached!;
          }
        }
      }
    } catch (_) {
      // fallback estático documentado
    }
    return CerradoSatelliteOverlay.acquisitionLabel;
  }

  static String _formatMonthRange(DateTime start, DateTime end) {
    String monthYear(DateTime dt) {
      const months = [
        'jan',
        'fev',
        'mar',
        'abr',
        'mai',
        'jun',
        'jul',
        'ago',
        'set',
        'out',
        'nov',
        'dez',
      ];
      return '${months[dt.month - 1]}/${dt.year}';
    }

    return '${monthYear(start)} – ${monthYear(end)}';
  }
}
