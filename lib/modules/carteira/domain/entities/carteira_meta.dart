/// Meta global por categoria × safra.
///
/// A meta NÃO é por cliente — é o total que o agrônomo
/// quer vender naquela categoria durante a safra.
/// ADR-022 — SoloForte
class CarteiraMeta {
  final String id;
  final String userId;
  final String safraId;
  final String categoriaId;
  final double quantidade;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CarteiraMeta({
    required this.id,
    required this.userId,
    required this.safraId,
    required this.categoriaId,
    required this.quantidade,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarteiraMeta.fromMap(Map<String, Object?> map) {
    return CarteiraMeta(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      safraId: map['safra_id'] as String,
      categoriaId: map['categoria_id'] as String,
      quantidade: (map['quantidade'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'safra_id': safraId,
      'categoria_id': categoriaId,
      'quantidade': quantidade,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CarteiraMeta copyWith({double? quantidade}) {
    return CarteiraMeta(
      id: id,
      userId: userId,
      safraId: safraId,
      categoriaId: categoriaId,
      quantidade: quantidade ?? this.quantidade,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
