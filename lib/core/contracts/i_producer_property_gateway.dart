class ProducerPropertySnapshot {
  const ProducerPropertySnapshot({
    required this.clientId,
    required this.name,
    required this.email,
    required this.farms,
  });

  final String clientId;
  final String name;
  final String? email;
  final List<ProducerFarmSnapshot> farms;
}

class ProducerFarmSnapshot {
  const ProducerFarmSnapshot({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.areaHa,
    required this.fields,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final double areaHa;
  final List<ProducerFieldSnapshot> fields;
}

class ProducerFieldSnapshot {
  const ProducerFieldSnapshot({
    required this.id,
    required this.name,
    required this.areaHa,
    required this.hasGeometry,
  });

  final String id;
  final String name;
  final double areaHa;
  final bool hasGeometry;
}

abstract interface class IProducerPropertyGateway {
  Future<ProducerPropertySnapshot> loadOwnProperty();

  Future<void> saveOwnFarm({
    String? farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  });

  Future<void> saveOwnField({
    String? fieldId,
    required String farmId,
    required String name,
    required double areaHa,
  });

  Future<void> deleteOwnFarm(String farmId);

  Future<void> deleteOwnField(String fieldId);
}
