// ADR-032 — settings/presentation/providers/user_profile_provider.dart
//
// Providers Riverpod (codegen) para perfil do usuário.
// autoDispose em todos — sem memory leak entre navegações.
//
// Uso:
//   ref.watch(currentUserProfileProvider)  → AsyncValue<UserProfile?>
//   ref.watch(profileAuditTrailProvider)   → AsyncValue<List<UserProfileAuditEntry>>
//   ref.invalidate(currentUserProfileProvider) após edição

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_models.dart';
import '../../../../core/session/user_role.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_user_profile_repository.dart';
import '../../data/models/user_profile_audit_entry.dart';

part 'user_profile_provider.g.dart';

// ─── Repositório (interno ao módulo) ─────────────────────────

@riverpod
IUserProfileRepository userProfileRepository(UserProfileRepositoryRef ref) {
  return UserProfileRepositoryImpl();
}

// ─── Perfil atual ─────────────────────────────────────────────

/// Perfil completo do usuário autenticado (Supabase Auth + perfis + cache).
///
/// autoDispose: true — descartado ao sair da tela de configurações.
/// Retorna null se não houver usuário autenticado.
@riverpod
Future<UserProfile?> currentUserProfile(CurrentUserProfileRef ref) async {
  final repo = ref.watch(userProfileRepositoryProvider);
  return repo.getCurrentProfile();
}

// ─── Trilha de auditoria ──────────────────────────────────────

/// Últimas 20 alterações de perfil em ordem cronológica reversa.
///
/// autoDispose: true — carregado apenas quando a seção de auditoria está visível.
@riverpod
Future<List<UserProfileAuditEntry>> profileAuditTrail(
  ProfileAuditTrailRef ref,
) async {
  final repo = ref.watch(userProfileRepositoryProvider);
  return repo.getAuditTrail(limit: 20);
}

// ─── Papel atual ─────────────────────────────────────────────

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  final profileRole = profile?.role.toUserRole();
  if (profileRole != null && !profileRole.isUnknown) {
    return profileRole;
  }

  final session = ref.watch(sessionControllerProvider);
  if (session is SessionAuthenticated) {
    final sessionRole =
        session.user.userMetadata?['role']?.toString().toUserRole() ??
        UserRole.unknown;
    if (!sessionRole.isUnknown) {
      return sessionRole;
    }
  }

  return UserRole.unknown;
});
