/// Plantio de um talhão do mapa, no calendário do produtor. ADR-062.
class ProducerCropPlanting {
  const ProducerCropPlanting({
    required this.fieldId,
    required this.fieldName,
    required this.farmName,
    required this.cultura,
    required this.safra,
    required this.dataPlantio,
    required this.dataEmergencia,
    required this.cicloDias,
    required this.canEdit,
  });

  final String fieldId;
  final String fieldName;
  final String farmName;
  final String? cultura;
  final String? safra;

  /// `yyyy-MM-dd`.
  final String? dataPlantio;

  /// `yyyy-MM-dd`.
  final String? dataEmergencia;
  final int? cicloDias;

  /// Talhão da propriedade própria. Vínculo do consultor fica somente leitura.
  final bool canEdit;
}

/// Calendário de plantio do produtor. Lê o talhão do mapa (`drawings`).
/// ADR-062.
abstract interface class IProducerCropCalendar {
  Future<List<ProducerCropPlanting>> listForProducer();

  /// Grava início, emergência e ciclo nas colunas que o talhão já tem.
  ///
  /// Null mantém o valor atual. String vazia em data não grava. [cicloDias]
  /// aceita dígitos; vazio não altera. Talhão de consultor lança [StateError].
  Future<void> saveOwnPlanting({
    required String fieldId,
    String? dataPlantio,
    String? dataEmergencia,
    String? cicloDias,
  });
}
