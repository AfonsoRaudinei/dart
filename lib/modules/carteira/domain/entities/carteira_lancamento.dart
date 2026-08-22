/// Registro de venda realizada por cliente × categoria × safra.
///
/// O histórico de lançamentos constitui o "realizado" de cada categoria.
/// Progresso = SUM(lançamentos.quantidade) / meta.quantidade × 100
///
/// [quantidade] nunca é input do usuário — derivada via [derivarQuantidade].
/// Ver `docs/CARTEIRA_CALCULOS.md` — Cálculo 3.
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
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;

  /// Compatibilidade com sistema legado de metas.
  /// Derivado de closedPercent — nunca lido do banco diretamente.
  int get percentualFechado {
    final rounded = closedPercent.round();
    if (rounded < 0) return 0;
    if (rounded > 100) return 100;
    return rounded;
  }

  /// Deriva volume realizado: `metaQuantidade × (closedPercent / 100)`.
  static double derivarQuantidade({
    required double metaQuantidade,
    required double closedPercent,
  }) {
    if (metaQuantidade <= 0) return 0.0;
    final pct = closedPercent.clamp(0.0, 100.0);
    return metaQuantidade * (pct / 100.0);
  }

  /// Volume residual em aberto para a meta informada.
  static double derivarOportunidadeVolume({
    required double metaQuantidade,
    required double closedPercent,
  }) {
    final realizado = derivarQuantidade(
      metaQuantidade: metaQuantidade,
      closedPercent: closedPercent,
    );
    return (metaQuantidade - realizado).clamp(0.0, double.infinity);
  }

  /// Valida combinação percentual × tipo de fechamento.
  ///
  /// - [tipoFechamento] null: negociação em aberto (percentual livre 0–100).
  /// - [vendido]: percentual livre 0–100 (venda parcial permitida).
  /// - [perdido]: percentual deve ser 0 (nada vendido para nós).
  static String? validarRegrasFechamento({
    required double closedPercent,
    required TipoFechamento? tipoFechamento,
  }) {
    final pct = closedPercent.clamp(0.0, 100.0);
    if (tipoFechamento == TipoFechamento.perdido && pct != 0) {
      return 'Perdido para concorrência exige 0% (nada vendido).';
    }
    return null;
  }

  /// Lançamento com tipo [vendido] não deve carregar dados de concorrente.
  static CarteiraLancamento sanitizarCamposConcorrente(
    CarteiraLancamento lancamento,
  ) {
    if (lancamento.tipoFechamento == TipoFechamento.perdido) {
      return lancamento;
    }
    return CarteiraLancamento(
      id: lancamento.id,
      userId: lancamento.userId,
      safraId: lancamento.safraId,
      categoriaId: lancamento.categoriaId,
      clienteId: lancamento.clienteId,
      quantidade: lancamento.quantidade,
      closedPercent: lancamento.closedPercent,
      observacao: lancamento.observacao,
      tipoFechamento: lancamento.tipoFechamento,
      dataLancamento: lancamento.dataLancamento,
      createdAt: lancamento.createdAt,
      updatedAt: lancamento.updatedAt,
      deletedAt: lancamento.deletedAt,
      syncStatus: lancamento.syncStatus,
    );
  }

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
    this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending_sync',
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
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.tryParse(map['deleted_at'] as String)
          : null,
      syncStatus: (map['sync_status'] as String?) ?? 'pending_sync',
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
      'updated_at': (updatedAt ?? createdAt).toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'sync_status': syncStatus,
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
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? syncStatus,
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
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
