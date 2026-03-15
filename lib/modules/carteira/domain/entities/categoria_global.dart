class CategoriaGlobal {
  final String id;
  final String userId;
  final String nome;
  final String cor;
  final bool ativo;
  final int ordem;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoriaGlobal({
    required this.id,
    required this.userId,
    required this.nome,
    required this.cor,
    required this.ativo,
    required this.ordem,
    required this.createdAt,
    required this.updatedAt,
  });
}
