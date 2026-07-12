import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/infra/preferences_service.dart';
import '../../../core/session/pending_signup_role_store.dart';
import '../../../core/session/profile_role_resolver.dart';
import '../../../core/session/user_role.dart';
import '../../../core/network/network_policy.dart';
import '../models/register_dto.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

part 'auth_service.g.dart';

@riverpod
class AuthService extends _$AuthService {
  @override
  void build() {}

  SupabaseClient get _client => Supabase.instance.client;

  String get _oauthRedirectUrl => '${AppConfig.supabaseUrl}/auth/v1/callback';

  Future<AuthResponse> login(String email, String password) async {
    try {
      AppConfig.validate();
      final result = await NetworkPolicy.withTimeout(
        () => _client.auth.signInWithPassword(email: email, password: password),
      );
      await ensureProfileComplete();
      return result;
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      AppConfig.validate();
      await NetworkPolicy.withTimeout(
        () => _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: _oauthRedirectUrl,
        ),
      );
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
  }

  Future<void> loginWithApple() async {
    try {
      AppConfig.validate();
      await NetworkPolicy.withTimeout(
        () => _client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: _oauthRedirectUrl,
        ),
      );
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
  }

  Future<AuthResponse> register(RegisterDto dto) async {
    try {
      AppConfig.validate();
      final result = await NetworkPolicy.withTimeout(
        () => _client.auth.signUp(
          email: dto.email,
          password: dto.password,
          data: {'full_name': dto.name, 'role': dto.role},
        ),
      );

      try {
        await _pendingSignupRoleStore().save(email: dto.email, role: dto.role);
      } catch (e) {
        AppLogger.error('cache local do papel falhou', tag: 'AuthService', error: e);
      }

      // Se sessão ativa (email-confirm desativado), completar perfil agora
      final userId = result.user?.id;
      if (result.session != null && userId != null) {
        try {
          await _completeProfile(userId: userId, dto: dto);
          await _pendingSignupRoleStore().clear(dto.email);
        } catch (e) {
          AppLogger.error('_completeProfile falhou', tag: 'AuthService', error: e);
          // Não bloquear cadastro por falha no perfil
        }
      }

      return result;
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
  }

  Future<void> recoverPassword(String email) async {
    try {
      AppConfig.validate();
      await NetworkPolicy.withTimeout(
        () => _client.auth.resetPasswordForEmail(
          email,
          redirectTo: 'soloforte://reset-password',
        ),
      );
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      AppConfig.validate();
      final result = await NetworkPolicy.withTimeout(
        () => _client.auth.updateUser(UserAttributes(password: newPassword)),
      );
      return result;
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
  }

  Future<void> logout() async {
    try {
      AppConfig.validate();
      await NetworkPolicy.withTimeout(() => _client.auth.signOut());
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
  }

  /// Garante que o perfil do usuário logado está completo.
  ///
  /// Idempotente: nunca sobrescreve dados válidos já existentes.
  /// Seguro para múltiplas execuções (login + bootstrap Map).
  ///
  /// Perfil mínimo funcional: `id` + `role` (obrigatórios).
  /// `name` é visual — não bloqueia funcionalidade se ausente.
  Future<void> ensureProfileComplete() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Buscar perfil atual
      final profile = await NetworkPolicy.withTimeout(
        () => _client
            .from('perfis')
            .select('name, role')
            .eq('id', user.id)
            .maybeSingle(),
      );

      final currentName = profile?['name'] as String?;
      final currentRole = profile?['role'] as String?;
      final metadataName = user.userMetadata?['full_name'] as String?;
      final metadataRole = user.userMetadata?['role'] as String?;
      final pendingSignupRole = await _readPendingSignupRole(user.email);
      final resolvedRole = ProfileRoleResolver.resolve(
        pendingSignupRole: pendingSignupRole,
        metadataRole: metadataRole,
        profileRole: currentRole,
      );

      if (profile == null) {
        // Perfil não existe (edge case — trigger falhou?) — criar via upsert
        AppLogger.debug('Perfil não encontrado. Criando...', tag: 'AuthService');
        await NetworkPolicy.withTimeout(
          () => _client.from('perfis').upsert({
            'id': user.id,
            'name': metadataName ?? '',
            'role': resolvedRole,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }),
        );
        if (metadataRole.toUserRole() != resolvedRole.toUserRole()) {
          await _syncAuthRole(resolvedRole);
        }
        await _pendingSignupRoleStore().clear(user.email);
        return;
      }

      // Só atualizar campos vazios — nunca sobrescrever dados válidos
      final updates = <String, dynamic>{};

      if (currentName == null || currentName.isEmpty) {
        updates['name'] = metadataName ?? '';
      }
      if (ProfileRoleResolver.shouldUpdateProfileRole(
        pendingSignupRole: pendingSignupRole,
        metadataRole: metadataRole,
        profileRole: currentRole,
      )) {
        updates['role'] = resolvedRole;
      }

      if (updates.isEmpty) {
        if (metadataRole.toUserRole() != resolvedRole.toUserRole()) {
          await _syncAuthRole(resolvedRole);
        }
        await _pendingSignupRoleStore().clear(user.email);
        return; // Perfil já completo — noop
      }

      await NetworkPolicy.withTimeout(
        () => _client.from('perfis').update(updates).eq('id', user.id),
      );
      if (metadataRole.toUserRole() != resolvedRole.toUserRole()) {
        await _syncAuthRole(resolvedRole);
      }
      await _pendingSignupRoleStore().clear(user.email);
      AppLogger.debug('Perfil completado: ${updates.keys}', tag: 'AuthService');
    } on PostgrestException catch (e) {
      // Não bloquear login por falha no perfil
      AppLogger.error('Erro ao completar perfil', tag: 'AuthService', error: e);
    } catch (e) {
      AppLogger.error('Erro inesperado no perfil', tag: 'AuthService', error: e);
    }
  }

  /// Preenche perfil com dados completos (nome, telefone, role, avatar).
  /// Chamado quando sessão está disponível (email confirmation desativada
  /// ou após login confirmado).
  Future<void> _completeProfile({
    required String userId,
    required RegisterDto dto,
  }) async {
    String? photoUrl;

    // Upload da imagem se existir
    if (dto.photo != null) {
      final fileExt = dto.photo!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      try {
        await NetworkPolicy.withTimeout(
          () => _client.storage
              .from('avatars')
              .upload(
                filePath,
                dto.photo!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              ),
        );

        photoUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      } catch (e) {
        AppLogger.error('Erro no upload de avatar', tag: 'AuthService', error: e);
        photoUrl = null;
      }
    }

    // UPDATE (não INSERT) — perfil já criado pelo trigger
    try {
      await NetworkPolicy.withTimeout(
        () => _client
            .from('perfis')
            .update({
              'name': dto.name,
              'phone': dto.phone,
              'role': dto.role,
              'photo_url': photoUrl,
            })
            .eq('id', userId),
      );
      await _syncAuthRole(dto.role);
    } on PostgrestException catch (e) {
      AppLogger.error('Erro ao atualizar perfil', tag: 'AuthService', error: e);
      // Não bloquear cadastro por falha no update de perfil
    }
  }

  Future<void> _syncAuthRole(String role) async {
    final normalizedRole = role.toUserRole().isUnknown
        ? UserRole.produtor.value
        : role.toUserRole().value;
    try {
      await NetworkPolicy.withTimeout(
        () => _client.auth.updateUser(
          UserAttributes(data: {'role': normalizedRole}),
        ),
      );
    } catch (e) {
      AppLogger.error('Falha ao sincronizar role na sessão', tag: 'AuthService', error: e);
    }
  }

  PendingSignupRoleStore _pendingSignupRoleStore() {
    return PendingSignupRoleStore(ref.read(preferencesServiceProvider));
  }

  Future<String?> _readPendingSignupRole(String? email) async {
    try {
      return _pendingSignupRoleStore().readValidRole(email);
    } catch (_) {
      return null;
    }
  }

  // --- auxiliar ---

  String _traduzirAuthException(AuthException error) {
    if (error is AuthRetryableFetchException) {
      return 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.';
    }

    if (error is AuthUnknownException) {
      return 'Não foi possível concluir a autenticação agora. Tente novamente em instantes.';
    }

    final lower = error.message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'Email ou senha incorretos.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'Este email já está cadastrado.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email não confirmado. Verifique sua caixa de entrada.';
    }
    if (lower.contains('password should be at least')) {
      return 'A senha deve ter pelo menos 8 caracteres.';
    }
    if (lower.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('host lookup') ||
        lower.contains('connection')) {
      return 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }

  String _traduzirErroDesconhecido(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('supabase_url') ||
        lower.contains('supabase_anon_key') ||
        lower.contains('seu-projeto.supabase.co')) {
      return 'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.';
    }
    if (lower.contains('host lookup') ||
        lower.contains('socket') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable')) {
      return 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.';
    }
    return 'Não foi possível completar a operação. Tente novamente.';
  }
}
