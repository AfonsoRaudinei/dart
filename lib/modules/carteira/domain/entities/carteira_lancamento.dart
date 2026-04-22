/// Registro de venda realizada por cliente × categoria × safra.
///
/// O histórico de lançamentos constitui o "realizado" de cada categoria.
/// Progresso = SUM(lançamentos) / meta.quantidade × 100
/// ADR-022 — SoloForte
enum TipoFechamento {
  vendido,
  perdido;

  String get dbValue {
    switch (this) {
      case TipoFechamento.vendido:
        return 'vendido';
      case TipoFechamento.perdido:
        return 'perdido';
    }
  }

  static TipoFechamento? fromDb(String? value) {
    switch (value) {
      case 'vendido':
        return TipoFechamento.vendido;
      case 'perdido':
        return TipoFechamento.perdido;
      default:
        return null;
    }
  }
}

class CarteiraLancamento {
  final String id;
  final String userId;
  final String safraId;
  final String categoriaId;
  final String clienteId;
  final double quantidade;
  final double closedPercent; // 0.0 a 100.0
  final String? observacao;
  final TipoFechamento? tipoFechamento;
  final String? nomeConcorrente;
  final String? motivoFechamento;
  final DateTime? dataFechamento;
  final DateTime dataLancamento;
  final DateTime createdAt;

  const CarteiraLancamento({
    required this.id,
    required this.userId,
    required this.safraId,
    required this.categoriaId,
    required this.clienteId,
    required this.quantidade,
    this.closedPercent = 0.0,
    this.observacao,
    this.tipoFechamento,
    this.nomeConcorrente,
    this.motivoFechamento,
    this.dataFechamento,
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
      closedPercent: (map['closed_percent'] as num?)?.toDouble() ?? 0.0,
      observacao: map['observacao'] as String?,
      tipoFechamento: TipoFechamento.fromDb(map['tipo_fechamento'] as String?),
      nomeConcorrente: map['nome_concorrente'] as String?,
      motivoFechamento: map['motivo_fechamento'] as String?,
      dataFechamento: map['data_fechamento'] != null
          ? DateTime.tryParse(map['data_fechamento'] as String)
          : null,
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
      'closed_percent': closedPercent,
      'observacao': observacao,
      'tipo_fechamento': tipoFechamento?.dbValue,
      'nome_concorrente': nomeConcorrente,
      'motivo_fechamento': motivoFechamento,
      'data_fechamento': dataFechamento?.toIso8601String(),
      'data_lancamento': dataLancamento.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  CarteiraLancamento copyWith({
    String? id,
    String? userId,
    String? safraId,
    String? categoriaId,
    String? clienteId,
    double? quantidade,
    double? closedPercent,
    String? observacao,
    TipoFechamento? tipoFechamento,
    String? nomeConcorrente,
    String? motivoFechamento,
    DateTime? dataFechamento,
    DateTime? dataLancamento,
    DateTime? createdAt,
  }) {
    return CarteiraLancamento(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      safraId: safraId ?? this.safraId,
      categoriaId: categoriaId ?? this.categoriaId,
      clienteId: clienteId ?? this.clienteId,
      quantidade: quantidade ?? this.quantidade,
      closedPercent: closedPercent ?? this.closedPercent,
      observacao: observacao ?? this.observacao,
      tipoFechamento: tipoFechamento ?? this.tipoFechamento,
      nomeConcorrente: nomeConcorrente ?? this.nomeConcorrente,
      motivoFechamento: motivoFechamento ?? this.motivoFechamento,
      dataFechamento: dataFechamento ?? this.dataFechamento,
      dataLancamento: dataLancamento ?? this.dataLancamento,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
