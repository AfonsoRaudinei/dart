// ADR-012 — planos/domain/entities/user_plan.dart
import '../enums/plano_tipo.dart';
import '../enums/plano_origem.dart';

/// Entidade de domínio — plano ativo de um usuário.
///
/// Fonte da verdade: Supabase (remoto). Sem cache local.
/// Verificação de plano é fluxo online-only (ADR-012).
class UserPlan {
  final String id;
  final String userId;
  final PlanoTipo plano;
  final PlanoOrigem origem;
  final bool ativo;
  final DateTime iniciouEm;
  final DateTime expiraEm;

  /// Nulo quando [origem] == [PlanoOrigem.indicacao].
  final String? paymentId;
  final DateTime criadoEm;

  const UserPlan({
    required this.id,
    required this.userId,
    required this.plano,
    required this.origem,
    required this.ativo,
    required this.iniciouEm,
    required this.expiraEm,
    this.paymentId,
    required this.criadoEm,
  });

  /// Dias restantes até expiração. Negativo = expirado.
  int get diasRestantes => expiraEm.difference(DateTime.now()).inDays;

  /// Verdadeiro se expira em até 7 dias (e ainda está ativo).
  bool get expiraEmBreve => ativo && diasRestantes >= 0 && diasRestantes <= 7;

  /// Verdadeiro se já passou da data de expiração.
  bool get expirado => expiraEm.isBefore(DateTime.now());

  /// Limite de cases ativos no mapa conforme o plano.
  int get limiteCases => plano.limiteCases;

  UserPlan copyWith({
    String? id,
    String? userId,
    PlanoTipo? plano,
    PlanoOrigem? origem,
    bool? ativo,
    DateTime? iniciouEm,
    DateTime? expiraEm,
    String? paymentId,
    DateTime? criadoEm,
  }) {
    return UserPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plano: plano ?? this.plano,
      origem: origem ?? this.origem,
      ativo: ativo ?? this.ativo,
      iniciouEm: iniciouEm ?? this.iniciouEm,
      expiraEm: expiraEm ?? this.expiraEm,
      paymentId: paymentId ?? this.paymentId,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  /// Deserializa do mapa JSON retornado pelo Supabase.
  factory UserPlan.fromJson(Map<String, dynamic> json) {
    return UserPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      plano: PlanoTipo.fromString(json['plano'] as String),
      origem: PlanoOrigem.fromString(json['origem'] as String),
      ativo: json['ativo'] as bool,
      iniciouEm: DateTime.parse(json['iniciou_em'] as String),
      expiraEm: DateTime.parse(json['expira_em'] as String),
      paymentId: json['payment_id'] as String?,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'plano': plano.name,
    'origem': origem.name,
    'ativo': ativo,
    'iniciou_em': iniciouEm.toIso8601String(),
    'expira_em': expiraEm.toIso8601String(),
    'payment_id': paymentId,
    'criado_em': criadoEm.toIso8601String(),
  };

  @override
  String toString() =>
      'UserPlan(id: $id, plano: ${plano.name}, ativo: $ativo, expiraEm: $expiraEm)';
}
