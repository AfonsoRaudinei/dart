// ADR-032 — settings/domain/repositories/i_user_profile_repository.dart
//
// Interface do repositório de perfil do usuário.
// Implementação: user_profile_repository_impl.dart
//
// Contrato interno ao módulo settings — não exposto em core/contracts/
// (settings é bounded context satélite, sem dependências cruzadas).

import '../entities/user_profile.dart';
import '../../data/models/user_profile_audit_entry.dart';

abstract class IUserProfileRepository {
  /// Retorna o perfil mesclado: Supabase Auth + tabela `perfis` + cache SQLite.
  ///
  /// Retorna null se não houver usuário autenticado.
  /// Merge rule: cache local (sync_status=1) prevalece sobre remoto.
  Future<UserProfile?> getCurrentProfile();

  /// Atualiza campos editáveis do perfil.
  ///
  /// [updated] — perfil com novos valores aplicados via copyWith.
  /// [changedFields] — mapa de {nomeDoCampo: valorAnterior} dos campos alterados.
  ///   Ex: {'fullName': 'João', 'phone': null}
  ///
  /// Comportamento:
  /// - Persiste no SQLite (offline-first) com sync_status=1
  /// - Gera 1 UserProfileAuditEntry por campo em changedFields (append-only)
  /// - Se online: sincroniza com Supabase e atualiza sync_status=0
  Future<void> updateProfile({
    required UserProfile updated,
    required Map<String, String?> changedFields,
  });

  /// Retorna as últimas [limit] alterações do perfil em ordem cronológica reversa.
  Future<List<UserProfileAuditEntry>> getAuditTrail({int limit = 20});
}
