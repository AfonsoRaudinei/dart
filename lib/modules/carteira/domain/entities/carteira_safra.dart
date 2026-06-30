/// Representa um período de safra para controle de metas.
///
/// Apenas uma safra pode estar ativa por usuário.
/// ADR-022 — SoloForte
class CarteiraSafra {
  final String id;
  final String userId;
  final String nome;
  final DateTime dataInicio;
  final DateTime dataFim;
  final bool ativa;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CarteiraSafra({
    required this.id,
    required this.userId,
    required this.nome,
    required this.dataInicio,
    required this.dataFim,
    required this.ativa,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarteiraSafra.fromMap(Map<String, Object?> map) {
    return CarteiraSafra(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      nome: map['nome'] as String,
      dataInicio: DateTime.parse(map['data_inicio'] as String),
      dataFim: DateTime.parse(map['data_fim'] as String),
      ativa: (map['ativa'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nome': nome,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
      'ativa': ativa ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CarteiraSafra copyWith({
    String? nome,
    DateTime? dataInicio,
    DateTime? dataFim,
    bool? ativa,
  }) {
    return CarteiraSafra(
      id: id,
      userId: userId,
      nome: nome ?? this.nome,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      ativa: ativa ?? this.ativa,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
