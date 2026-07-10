/// Tipo de produto / unidade de medida configurável por usuário.
///
/// Substitui o enum fixo [UnidadeCategoria] na UI — os tipos padrão
/// são seedados na migração V39 e novos podem ser criados pelo agrônomo.
class CarteiraTipoProduto {
  final String id;
  final String userId;

  /// Identificador persistido em `carteira_categorias.unidade`.
  final String codigo;

  /// Rótulo exibido nos chips (ex.: R$/ha, Litros/ha).
  final String label;

  /// Quando true, permite conversão valorReferencia / valorGrao → sacas/ha.
  final bool converteSacasHa;

  /// Tipos seedados pelo sistema — não podem ser desativados pela UI.
  final bool sistema;
  final bool ativo;
  final int ordem;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CarteiraTipoProduto({
    required this.id,
    required this.userId,
    required this.codigo,
    required this.label,
    this.converteSacasHa = false,
    this.sistema = false,
    this.ativo = true,
    this.ordem = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarteiraTipoProduto.fromMap(Map<String, Object?> map) {
    return CarteiraTipoProduto(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      codigo: map['codigo'] as String,
      label: map['label'] as String,
      converteSacasHa: (map['converte_sacas_ha'] as int? ?? 0) == 1,
      sistema: (map['sistema'] as int? ?? 0) == 1,
      ativo: (map['ativo'] as int? ?? 1) == 1,
      ordem: map['ordem'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'codigo': codigo,
      'label': label,
      'converte_sacas_ha': converteSacasHa ? 1 : 0,
      'sistema': sistema ? 1 : 0,
      'ativo': ativo ? 1 : 0,
      'ordem': ordem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CarteiraTipoProduto copyWith({
    String? label,
    bool? converteSacasHa,
    bool? ativo,
    int? ordem,
  }) {
    return CarteiraTipoProduto(
      id: id,
      userId: userId,
      codigo: codigo,
      label: label ?? this.label,
      converteSacasHa: converteSacasHa ?? this.converteSacasHa,
      sistema: sistema,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Gera slug estável a partir do rótulo informado pelo usuário.
  static String codigoFromLabel(String label) {
    final normalized = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'tipo' : normalized;
  }
}
