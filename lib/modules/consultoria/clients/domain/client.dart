import 'agronomic_models.dart';

class Client {
  // ── Campos originais ──────────────────────────────────────────────
  final String id;
  final String name;
  final String phone;
  final String city;
  final String state;
  final String? email;
  final String? observation;
  final String? photoPath;
  final bool active;
  final DateTime createdAt;
  final List<Farm> farms;

  // ── Campos novos — dados pessoais ─────────────────────────────────
  final DateTime? dataNascimento;
  final String? cpfCnpj; // apenas dígitos

  // ── Campos novos — propriedade ────────────────────────────────────
  final double? areaTotal; // hectares totais
  final String? tipoPropriedade; // 'propria' | 'arrendada' | 'mista'
  final String? sistemaIrrigacao; // 'sequeiro' | 'irrigado' | 'misto'
  final String? soloTipo; // 'arenoso' | 'argiloso' | 'misto' | 'outro'
  final String? regiaoAgricola;
  final String? safraAtual; // ex: '2024/2025'

  // ── Campos novos — assistência técnica ───────────────────────────
  final bool? usaAssistenciaTecnica;
  final String? tecnicoResponsavel;

  // ── Campos de controle ────────────────────────────────────────────
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.state,
    this.email,
    this.observation,
    this.photoPath,
    this.active = true,
    required this.createdAt,
    this.farms = const [],
    // novos
    this.dataNascimento,
    this.cpfCnpj,
    this.areaTotal,
    this.tipoPropriedade,
    this.sistemaIrrigacao,
    this.soloTipo,
    this.regiaoAgricola,
    this.safraAtual,
    this.usaAssistenciaTecnica,
    this.tecnicoResponsavel,
    this.updatedAt,
    this.deletedAt,
  });

  factory Client.fromMap(Map<String, Object?> map) {
    return Client(
      id: map['id'] as String,
      name: map['nome'] as String,
      phone: (map['telefone'] as String?) ?? '',
      city: (map['cidade'] as String?) ?? '',
      state: (map['uf'] as String?) ?? '',
      email: map['email'] as String?,
      observation: map['observacoes'] as String?,
      photoPath: map['foto_path'] as String?,
      active: (map['ativo'] as int? ?? 1) == 1 && map['deleted_at'] == null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.tryParse(map['deleted_at'] as String)
          : null,
      // novos
      dataNascimento: map['data_nascimento'] != null
          ? DateTime.tryParse(map['data_nascimento'] as String)
          : null,
      cpfCnpj: map['cpf_cnpj'] as String?,
      areaTotal: (map['area_total'] as num?)?.toDouble(),
      tipoPropriedade: map['tipo_propriedade'] as String?,
      sistemaIrrigacao: map['sistema_irrigacao'] as String?,
      soloTipo: map['solo_tipo'] as String?,
      regiaoAgricola: map['regiao_agricola'] as String?,
      safraAtual: map['safra_atual'] as String?,
      usaAssistenciaTecnica: map['usa_assistencia_tecnica'] != null
          ? (map['usa_assistencia_tecnica'] as int) == 1
          : null,
      tecnicoResponsavel: map['tecnico_responsavel'] as String?,
      farms: const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': name,
      'documento': null,
      'telefone': phone,
      'email': email,
      'cidade': city,
      'uf': state,
      'observacoes': observation,
      'foto_path': photoPath,
      'ativo': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'sync_status': 1,
      // novos
      'data_nascimento': dataNascimento?.toIso8601String(),
      'cpf_cnpj': cpfCnpj,
      'area_total': areaTotal,
      'tipo_propriedade': tipoPropriedade,
      'sistema_irrigacao': sistemaIrrigacao,
      'solo_tipo': soloTipo,
      'regiao_agricola': regiaoAgricola,
      'safra_atual': safraAtual,
      'usa_assistencia_tecnica': usaAssistenciaTecnica == null
          ? null
          : (usaAssistenciaTecnica! ? 1 : 0),
      'tecnico_responsavel': tecnicoResponsavel,
    };
  }

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? city,
    String? state,
    String? email,
    String? observation,
    String? photoPath,
    bool? active,
    DateTime? createdAt,
    List<Farm>? farms,
    // novos
    DateTime? dataNascimento,
    String? cpfCnpj,
    double? areaTotal,
    String? tipoPropriedade,
    String? sistemaIrrigacao,
    String? soloTipo,
    String? regiaoAgricola,
    String? safraAtual,
    bool? usaAssistenciaTecnica,
    String? tecnicoResponsavel,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      state: state ?? this.state,
      email: email ?? this.email,
      observation: observation ?? this.observation,
      photoPath: photoPath ?? this.photoPath,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      farms: farms ?? this.farms,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      areaTotal: areaTotal ?? this.areaTotal,
      tipoPropriedade: tipoPropriedade ?? this.tipoPropriedade,
      sistemaIrrigacao: sistemaIrrigacao ?? this.sistemaIrrigacao,
      soloTipo: soloTipo ?? this.soloTipo,
      regiaoAgricola: regiaoAgricola ?? this.regiaoAgricola,
      safraAtual: safraAtual ?? this.safraAtual,
      usaAssistenciaTecnica:
          usaAssistenciaTecnica ?? this.usaAssistenciaTecnica,
      tecnicoResponsavel: tecnicoResponsavel ?? this.tecnicoResponsavel,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
