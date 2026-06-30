class ClienteCategoria {
  final String id;
  final String userId;
  final String clienteId;
  final String categoriaId;
  final int percentualFechado;
  final String? observacao;
  final DateTime updatedAt;

  const ClienteCategoria({
    required this.id,
    required this.userId,
    required this.clienteId,
    required this.categoriaId,
    required this.percentualFechado,
    this.observacao,
    required this.updatedAt,
  });

  ClienteCategoria copyWith({int? percentualFechado, String? observacao}) {
    return ClienteCategoria(
      id: id,
      userId: userId,
      clienteId: clienteId,
      categoriaId: categoriaId,
      percentualFechado: percentualFechado ?? this.percentualFechado,
      observacao: observacao ?? this.observacao,
      updatedAt: DateTime.now(),
    );
  }
}
