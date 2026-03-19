/// Registro de venda realizada por cliente × categoria × safra.
///
/// O histórico de lançamentos constitui o "realizado" de cada categoria.
/// Progresso = SUM(lançamentos) / meta.quantidade × 100
/// ADR-022 — SoloForte
class CarteiraLancamento {
  final String id;
  final String userId;
  final String safraId;
  final String categoriaId;
  final String clienteId;
  final double quantidade;
  final String? observacao;
  final DateTime dataLancamento;
  final DateTime createdAt;

  const CarteiraLancamento({
    required this.id,
    required this.userId,
    required this.safraId,
    required this.categoriaId,
    required this.clienteId,
    required this.quantidade,
    this.observacao,
    required this.dataLancamento,
    required this.createdAt,
  });

  factory CarteiraLancamento.fromMap(Map<String, Object?> map) {
    return CarteiraLancamento(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      safraId: map['safra_id'] as String,
      categoriaId: map['categoria_id'] as String,
      clienteId: map['cliente_id'] as String,
      quantidade: (map['quantidade'] as num).toDouble(),
      observacao: map['observacao'] as String?,
      dataLancamento: DateTime.parse(map['data_lancamento'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'safra_id': safraId,
      'categoria_id': categoriaId,
      'cliente_id': clienteId,
      'quantidade': quantidade,
      'observacao': observacao,
      'data_lancamento': dataLancamento.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
