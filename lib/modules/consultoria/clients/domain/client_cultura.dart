import 'enums/cultura_tipo.dart';

/// Sub-entidade que representa uma cultura cultivada por um cliente.
class ClientCultura {
  final String id;
  final String clientId;
  final String cultura; // CulturaTipo.name
  final double areaHa;
  final String? variedade;
  final String? safra;
  final String? observacao;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientCultura({
    required this.id,
    required this.clientId,
    required this.cultura,
    required this.areaHa,
    this.variedade,
    this.safra,
    this.observacao,
    required this.createdAt,
    required this.updatedAt,
  });

  CulturaTipo get culturaTipo => CulturaTipo.fromName(cultura);

  factory ClientCultura.fromMap(Map<String, Object?> map) {
    return ClientCultura(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      cultura: map['cultura'] as String,
      areaHa: (map['area_ha'] as num).toDouble(),
      variedade: map['variedade'] as String?,
      safra: map['safra'] as String?,
      observacao: map['observacao'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'cultura': cultura,
      'area_ha': areaHa,
      'variedade': variedade,
      'safra': safra,
      'observacao': observacao,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ClientCultura copyWith({
    String? id,
    String? clientId,
    String? cultura,
    double? areaHa,
    String? variedade,
    String? safra,
    String? observacao,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientCultura(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      cultura: cultura ?? this.cultura,
      areaHa: areaHa ?? this.areaHa,
      variedade: variedade ?? this.variedade,
      safra: safra ?? this.safra,
      observacao: observacao ?? this.observacao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
