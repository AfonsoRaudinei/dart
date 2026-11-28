import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/user_plan.dart';

/// Carimba [UserPlan.isAdmin] com a mesma regra de sessão + `perfis` usada em
/// produtor (occurrence gate). ADR-066 exige paridade antes de ler cotas.
class UserPlanAdminResolver {
  const UserPlanAdminResolver._();

  @visibleForTesting
  static bool isAdminRole(String? role) =>
      role != null && role.trim().toLowerCase() == 'admin';

  /// JWT (`appMetadata` / `userMetadata`) — síncrono.
  @visibleForTesting
  static UserPlan stampJwt(UserPlan plan, User? user) {
    final sessionRole =
        (user?.appMetadata['role'] as String?)?.trim().toLowerCase() ??
        (user?.userMetadata?['role'] as String?)?.trim().toLowerCase();
    if (isAdminRole(sessionRole)) {
      return plan.copyWith(isAdmin: true);
    }
    return plan;
  }

  static Future<UserPlan> stamp(SupabaseClient client, UserPlan plan) async {
    final jwtStamped = stampJwt(plan, client.auth.currentUser);
    if (jwtStamped.isAdmin) return jwtStamped;

    final userId = plan.userId.trim();
    if (userId.isEmpty) return jwtStamped;

    try {
      final perfil = await client
          .from('perfis')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      final perfilRole = (perfil?['role'] as String?)?.trim().toLowerCase();
      if (isAdminRole(perfilRole)) {
        return jwtStamped.copyWith(isAdmin: true);
      }
    } catch (_) {
      return jwtStamped;
    }
    return jwtStamped;
  }
}