// lib/core/contracts/i_visit_photo_read.dart
//
// Contrato neutro para leitura de fotos coletadas durante uma visita.
// Consumidores autorizados: map/ e consultoria/relatorios via providers.

class VisitPhotoSummary {
  const VisitPhotoSummary({
    required this.id,
    required this.localPath,
    required this.createdAt,
    this.lat,
    this.lng,
    this.type = 'normal',
  });

  final String id;
  final String localPath;
  final DateTime createdAt;
  final double? lat;
  final double? lng;
  final String type;
}

abstract interface class IVisitPhotoRead {
  Future<List<VisitPhotoSummary>> getBySessionId(String sessionId);
}
