class ProducerClientLink {
  final String id;
  final String consultorUserId;
  final String clientId;
  final String? producerUserId;
  final String status;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProducerClientLink({
    required this.id,
    required this.consultorUserId,
    required this.clientId,
    required this.producerUserId,
    required this.status,
    required this.expiresAt,
    required this.usedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProducerClientLink.fromRemote(Map<String, dynamic> map) {
    return ProducerClientLink(
      id: map['id'] as String,
      consultorUserId: map['consultor_user_id'] as String,
      clientId: map['client_id'] as String,
      producerUserId: map['producer_user_id'] as String?,
      status: map['status'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String).toUtc(),
      usedAt: map['used_at'] == null
          ? null
          : DateTime.parse(map['used_at'] as String).toUtc(),
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
    );
  }

  factory ProducerClientLink.fromCache(Map<String, dynamic> map) {
    return ProducerClientLink(
      id: map['id'] as String,
      consultorUserId: map['consultor_user_id'] as String,
      clientId: map['client_id'] as String,
      producerUserId: map['producer_user_id'] as String?,
      status: map['status'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String).toUtc(),
      usedAt: map['used_at'] == null
          ? null
          : DateTime.parse(map['used_at'] as String).toUtc(),
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toCache({required int syncStatus}) => {
    'id': id,
    'consultor_user_id': consultorUserId,
    'client_id': clientId,
    'producer_user_id': producerUserId,
    'status': status,
    'expires_at': expiresAt.toIso8601String(),
    'used_at': usedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'sync_status': syncStatus,
  };
}

class ProducerInvite {
  final String token;
  final DateTime expiresAt;

  const ProducerInvite({required this.token, required this.expiresAt});
}

class ProducerPropertyDashboard {
  final ProducerOwnProperty ownProperty;
  final List<ProducerLinkedClient> linkedClients;

  const ProducerPropertyDashboard({
    required this.ownProperty,
    required this.linkedClients,
  });

  bool get hasLinks => linkedClients.isNotEmpty;
}

class ProducerOwnProperty {
  final String clientId;
  final String name;
  final String? email;
  final List<ProducerOwnFarm> farms;

  const ProducerOwnProperty({
    required this.clientId,
    required this.name,
    required this.email,
    required this.farms,
  });

  bool get hasFarms => farms.isNotEmpty;
}

class ProducerOwnFarm {
  final String id;
  final String name;
  final String city;
  final String state;
  final double areaHa;
  final List<ProducerOwnField> fields;

  const ProducerOwnFarm({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.areaHa,
    required this.fields,
  });
}

class ProducerOwnField {
  final String id;
  final String name;
  final double areaHa;
  final bool hasGeometry;

  const ProducerOwnField({
    required this.id,
    required this.name,
    required this.areaHa,
    this.hasGeometry = false,
  });
}

class ProducerLinkedClient {
  final ProducerClientLink link;
  final String name;
  final String? phone;
  final String? email;
  final String? city;
  final String? state;
  final List<ProducerLinkedFarm> farms;
  final List<ProducerLinkedReport> reports;

  const ProducerLinkedClient({
    required this.link,
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
    required this.state,
    required this.farms,
    required this.reports,
  });
}

class ProducerLinkedFarm {
  final String id;
  final String name;
  final String? city;
  final String? state;
  final double areaHa;
  final List<ProducerLinkedField> fields;

  const ProducerLinkedFarm({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.areaHa,
    required this.fields,
  });
}

class ProducerLinkedField {
  final String id;
  final String name;
  final double areaHa;

  const ProducerLinkedField({
    required this.id,
    required this.name,
    required this.areaHa,
  });
}

class ProducerLinkedReport {
  final String id;
  final String title;
  final String farmName;
  final DateTime createdAt;

  const ProducerLinkedReport({
    required this.id,
    required this.title,
    required this.farmName,
    required this.createdAt,
  });
}
