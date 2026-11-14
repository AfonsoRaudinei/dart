import '../../../core/contracts/i_producer_invite_writer.dart';

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
  final ProducerShareSelection share;

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
    this.share = const ProducerShareSelection(),
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
      share: ProducerShareSelection(
        farms: ProducerShareSelection.readFlag(map['share_farms']),
        fields: ProducerShareSelection.readFlag(map['share_fields']),
        occurrences: ProducerShareSelection.readFlag(map['share_occurrences']),
        reports: ProducerShareSelection.readFlag(map['share_reports']),
      ),
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
      share: ProducerShareSelection(
        farms: ProducerShareSelection.readFlag(map['share_farms']),
        fields: ProducerShareSelection.readFlag(map['share_fields']),
        occurrences: ProducerShareSelection.readFlag(map['share_occurrences']),
        reports: ProducerShareSelection.readFlag(map['share_reports']),
      ),
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
    'share_farms': share.farms ? 1 : 0,
    'share_fields': share.fields ? 1 : 0,
    'share_occurrences': share.occurrences ? 1 : 0,
    'share_reports': share.reports ? 1 : 0,
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

  /// Fazenda do consultor liberada pelo vínculo. O produtor vê e foca no
  /// mapa; a edição continua na conta do consultor.
  final bool sharedByConsultant;

  /// `client_id` do consultor quando [sharedByConsultant] é verdadeiro.
  final String? sourceClientId;

  const ProducerOwnFarm({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.areaHa,
    required this.fields,
    this.sharedByConsultant = false,
    this.sourceClientId,
  });
}

class ProducerOwnField {
  final String id;
  final String name;
  final double areaHa;
  final bool hasGeometry;

  /// GeoJSON do contorno, quando o vínculo já trouxe a geometria.
  final String? geometryJson;

  const ProducerOwnField({
    required this.id,
    required this.name,
    required this.areaHa,
    this.hasGeometry = false,
    this.geometryJson,
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
  final List<ProducerLinkedOccurrence> occurrences;

  const ProducerLinkedClient({
    required this.link,
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
    required this.state,
    required this.farms,
    required this.reports,
    this.occurrences = const [],
  });
}

class ProducerLinkedOccurrence {
  final String id;
  final String title;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  const ProducerLinkedOccurrence({
    required this.id,
    required this.title,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    return lat != 0 || lng != 0;
  }
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

  /// GeoJSON do contorno (`fields.bordadura_geo` ou desenho do vínculo).
  /// Leitura. O produtor não grava de volta na conta do consultor.
  final String? geometryJson;

  /// Desenho já baixado para o mapa. A camada de vínculo não redesenha
  /// esse contorno — quem desenha é a camada de drawings.
  final bool fromDrawing;

  const ProducerLinkedField({
    required this.id,
    required this.name,
    required this.areaHa,
    this.geometryJson,
    this.fromDrawing = false,
  });

  bool get hasGeometry {
    final raw = geometryJson?.trim() ?? '';
    return raw.isNotEmpty;
  }
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

/// Desenho do consultor (tabela `drawings`) para entrar no talhão da fazenda.
class ProducerLinkedDrawing {
  final String id;
  final String name;
  final double areaHa;
  final String? farmId;
  final String? groupName;
  final String? geometryJson;

  const ProducerLinkedDrawing({
    required this.id,
    required this.name,
    required this.areaHa,
    this.farmId,
    this.groupName,
    this.geometryJson,
  });
}

/// Fazendas que o produtor enxerga no card e em Minha área.
///
/// A propriedade própria vem primeiro. Fazendas do vínculo entram em seguida,
/// sem duplicar id e sem virar cadastro editável.
List<ProducerOwnFarm> producerFarmsForProducer({
  required ProducerOwnProperty own,
  required List<ProducerLinkedClient> linkedClients,
}) {
  final ownIds = own.farms.map((farm) => farm.id).toSet();
  final linked = <ProducerOwnFarm>[];
  for (final client in linkedClients) {
    if (!client.link.share.farms && !client.link.share.fields) continue;
    for (final farm in client.farms) {
      if (farm.id.isEmpty || ownIds.contains(farm.id)) continue;
      ownIds.add(farm.id);
      linked.add(
        ProducerOwnFarm(
          id: farm.id,
          name: farm.name,
          city: (farm.city ?? '').trim(),
          state: (farm.state ?? '').trim(),
          areaHa: farm.areaHa,
          sharedByConsultant: true,
          sourceClientId: client.link.clientId,
          fields: farm.fields
              .map(
                (field) => ProducerOwnField(
                  id: field.id,
                  name: field.name,
                  areaHa: field.areaHa,
                  hasGeometry: field.hasGeometry,
                  geometryJson: field.geometryJson,
                ),
              )
              .toList(growable: false),
        ),
      );
    }
  }
  return [...own.farms, ...linked];
}

/// Encaixa desenhos do vínculo nos talhões da fazenda.
///
/// `fazenda_id` manda. Sem id, o grupo igual ao nome da fazenda manda.
/// O que sobrar sem dono vai para a única fazenda, ou para a primeira
/// quando nenhum desenho casou com fazenda nenhuma.
List<ProducerLinkedFarm> attachDrawingsToLinkedFarms({
  required List<ProducerLinkedFarm> farms,
  required List<ProducerLinkedDrawing> drawings,
}) {
  if (farms.isEmpty || drawings.isEmpty) return farms;
  final usable = drawings.where((drawing) => drawing.id.trim().isNotEmpty);
  if (usable.isEmpty) return farms;

  final assigned = <String, List<ProducerLinkedDrawing>>{
    for (final farm in farms) farm.id: <ProducerLinkedDrawing>[],
  };
  final orphans = <ProducerLinkedDrawing>[];

  for (final drawing in usable) {
    final farmId = drawing.farmId?.trim() ?? '';
    if (farmId.isNotEmpty && assigned.containsKey(farmId)) {
      assigned[farmId]!.add(drawing);
      continue;
    }
    final group = _normalizeFarmLabel(drawing.groupName ?? '');
    if (group.isNotEmpty) {
      final matches = farms
          .where((farm) => _normalizeFarmLabel(farm.name) == group)
          .toList(growable: false);
      if (matches.length == 1) {
        assigned[matches.single.id]!.add(drawing);
        continue;
      }
    }
    orphans.add(drawing);
  }

  final anyAssigned = assigned.values.any((list) => list.isNotEmpty);
  if (orphans.isNotEmpty && farms.length == 1) {
    assigned[farms.single.id]!.addAll(orphans);
  } else if (orphans.isNotEmpty && !anyAssigned) {
    assigned[farms.first.id]!.addAll(orphans);
  }

  return farms
      .map(
        (farm) => _mergeDrawingsIntoFarm(farm, assigned[farm.id] ?? const []),
      )
      .toList(growable: false);
}

ProducerLinkedFarm _mergeDrawingsIntoFarm(
  ProducerLinkedFarm farm,
  List<ProducerLinkedDrawing> drawings,
) {
  if (drawings.isEmpty) return farm;
  final byId = <String, ProducerLinkedDrawing>{
    for (final drawing in drawings) drawing.id: drawing,
  };
  final fields = <ProducerLinkedField>[];
  final seen = <String>{};

  for (final field in farm.fields) {
    seen.add(field.id);
    final drawing = byId[field.id];
    if (drawing == null || field.hasGeometry) {
      fields.add(field);
      continue;
    }
    final geometry = drawing.geometryJson?.trim() ?? '';
    if (geometry.isEmpty) {
      fields.add(field);
      continue;
    }
    fields.add(
      ProducerLinkedField(
        id: field.id,
        name: field.name,
        areaHa: field.areaHa,
        geometryJson: geometry,
        fromDrawing: true,
      ),
    );
  }

  for (final drawing in drawings) {
    if (seen.contains(drawing.id)) continue;
    seen.add(drawing.id);
    final name = drawing.name.trim();
    fields.add(
      ProducerLinkedField(
        id: drawing.id,
        name: name.isEmpty ? 'Talhão' : name,
        areaHa: drawing.areaHa,
        geometryJson: drawing.geometryJson,
        fromDrawing: true,
      ),
    );
  }

  return ProducerLinkedFarm(
    id: farm.id,
    name: farm.name,
    city: farm.city,
    state: farm.state,
    areaHa: farm.areaHa,
    fields: fields,
  );
}

String _normalizeFarmLabel(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
