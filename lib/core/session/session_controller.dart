import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../infra/preferences_service.dart';
import '../../core/network/network_policy.dart';
import '../../core/state/map_state.dart';
import '../database/database_helper.dart';
import 'pending_signup_role_store.dart';
import 'profile_role_resolver.dart';
import 'user_role.dart';
import 'session_models.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

part 'session_controller.g.dart';

typedef SessionLogoutInvalidation = void Function(Ref ref);

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  static final Map<String, SessionLogoutInvalidation> _logoutInvalidations =
      <String, SessionLogoutInvalidation>{};

  /// Registro global de invalidações a executar no logout.
  ///
  /// Deve ser chamado por providers keepAlive com dados específicos de usuário.
  static void registerLogoutInvalidation({
    required String key,
    required SessionLogoutInvalidation invalidate,
  }) {
    _logoutInvalidations[key] = invalidate;
  }

  StreamSubscription<AuthState>? _authSubscription;

  @override
  SessionState build() {
    // Inicia listener do stream de autenticação do Supabase.
    // O stream emite imediatamente com o estado atual e depois em cada mudança.
    _startListening();

    // Garante cancelamento ao dispor o provider.
    ref.onDispose(() => _authSubscription?.cancel());

    // Estado síncrono inicial baseado na sessão persistida pelo Supabase.
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        return SessionAuthenticated(currentUser);
      }
    } catch (_) {
      // Se Supabase não inicializou ou tem credenciais inválidas,
      // retorna estado de inicialização seguro.
    }
    // 🛡 gotrue 2.18.0: a sessão pode ser restaurada de forma assíncrona.
    // Retornar SessionUnknown em vez de SessionPublic garante que a janela
    // de bootstrap não seja confundida com "usuário deslogado" pelo router.
    // O onAuthStateChange atualizará para SessionAuthenticated ou SessionPublic
    // assim que a restauração do storage local for concluída.
    return const SessionUnknown();
  }

  void _startListening() {
    _authSubscription?.cancel();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        // P3.2 — estado preciso para recovery
        if (data.event == AuthChangeEvent.passwordRecovery) {
          final user = data.session?.user;
          if (user != null) {
            state = SessionPasswordRecovery(user);
          }
          return;
        }

        final user = data.session?.user;
        if (user != null) {
          state = SessionAuthenticated(user);
          unawaited(() async {
            try {
              await DatabaseHelper.instance.repairOrphanUserIds(user.id);
            } catch (e, st) {
              AppLogger.error('repairOrphanUserIds falhou', tag: 'SessionController', error: e, stackTrace: st);
            }
            try {
              await _ensureProfileComplete(loginEmail: user.email);
            } catch (_) {
              // Não bloquear autenticação por falha no bootstrap de perfil.
            }
          }());
        } else {
          state = const SessionPublic();
        }
      },
      onError: (error) {
        state = const SessionPublic();
      },
    );
  }

  /// Login real via Supabase Auth.
  /// Lança exceção com mensagem tratável em caso de falha.
  /// Após login, garante que o perfil está completo (trigger cria vazio,
  /// esta chamada preenche nome/role do user_metadata).
  Future<void> login(String email, String password) async {
    try {
      AppConfig.validate();
      await NetworkPolicy.withTimeout(
        () => Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        ),
      );
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } on TimeoutException {
      throw Exception(
        'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
    // O stream onAuthStateChange atualiza o state automaticamente.

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isNotEmpty) {
      try {
        await DatabaseHelper.instance.repairOrphanUserIds(userId);
      } catch (e, st) {
        AppLogger.error('repairOrphanUserIds falhou', tag: 'SessionController', error: e, stackTrace: st);
      }
    }

    // Garantir que perfil criado pelo trigger está completo.
    // Se o cadastro foi feito com email confirmation, o perfil está vazio.
    // Esta chamada preenche os dados do user_metadata.
    try {
      await _ensureProfileComplete(loginEmail: email);
    } catch (_) {
      // Não bloquear login por falha no perfil
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      AppConfig.validate();
      await NetworkPolicy.withTimeout(
        () => Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${AppConfig.supabaseUrl}/auth/v1/callback',
        ),
      );
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } on TimeoutException {
      throw Exception(
        'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
  }

  Future<void> loginWithApple() async {
    try {
      AppConfig.validate();
      await NetworkPolicy.withTimeout(
        () => Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: '${AppConfig.supabaseUrl}/auth/v1/callback',
        ),
      );
    } on AuthException catch (e) {
      throw Exception(_traduzirAuthException(e));
    } on StateError {
      throw Exception(
        'Configuração inválida do aplicativo. Reinstale a versão mais recente ou contate o suporte.',
      );
    } on TimeoutException {
      throw Exception(
        'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
      );
    } catch (e) {
      throw Exception(_traduzirErroDesconhecido(e));
    }
  }

  /// Preenche perfil vazio (criado pelo trigger) com dados do user_metadata.
  /// Idempotente: nunca sobrescreve dados válidos já existentes.
  /// Seguro para múltiplas execuções (login + bootstrap Map).
  Future<void> _ensureProfileComplete({String? loginEmail}) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final profile = await NetworkPolicy.withTimeout(
      () => client
          .from('perfis')
          .select('name, role')
          .eq('id', user.id)
          .maybeSingle(),
    );

    final metadataName = user.userMetadata?['full_name'] as String?;
    final metadataRole = user.userMetadata?['role'] as String?;
    final roleEmail = loginEmail ?? user.email;
    final pendingSignupRole = await _readPendingSignupRole(roleEmail);

    if (profile == null) {
      final resolvedRole = ProfileRoleResolver.resolve(
        pendingSignupRole: pendingSignupRole,
        metadataRole: metadataRole,
        profileRole: null,
      );
      await NetworkPolicy.withTimeout(
        () => client.from('perfis').upsert({
          'id': user.id,
          'name': metadataName ?? '',
          'role': resolvedRole,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      if (metadataRole.toUserRole() != resolvedRole.toUserRole()) {
        await _syncAuthRole(client, resolvedRole);
      }
      await _pendingSignupRoleStore().clear(roleEmail);
      return;
    }

    final currentName = profile['name'] as String?;
    final currentRole = profile['role'] as String?;
    final resolvedRole = ProfileRoleResolver.resolve(
      pendingSignupRole: pendingSignupRole,
      metadataRole: metadataRole,
      profileRole: currentRole,
    );

    // Só atualizar campos que estão vazios — nunca sobrescrever dados válidos
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
        await _syncAuthRole(client, resolvedRole);
      }
      await _pendingSignupRoleStore().clear(roleEmail);
      return; // Perfil já completo — noop
    }

    await NetworkPolicy.withTimeout(
      () => client.from('perfis').update(updates).eq('id', user.id),
    );

    if (metadataRole.toUserRole() != resolvedRole.toUserRole()) {
      await _syncAuthRole(client, resolvedRole);
    }
    await _pendingSignupRoleStore().clear(roleEmail);
  }

  Future<void> _syncAuthRole(SupabaseClient client, String role) async {
    try {
      await NetworkPolicy.withTimeout(
        () => client.auth.updateUser(UserAttributes(data: {'role': role})),
      );
    } catch (e, st) {
      AppLogger.error('sync role falhou', tag: 'SessionController', error: e, stackTrace: st);
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

  /// Cadastro real via Supabase Auth.
  Future<void> signup(String name, String email, String password) async {
    try {
      AppConfig.validate();
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
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
    // O stream onAuthStateChange atualiza o state automaticamente.
  }

  /// Logout real via Supabase Auth.
  Future<void> logout() async {
    _invalidateUserScopedProviders();

    await Supabase.instance.client.auth.signOut();
    // O stream onAuthStateChange seta state = SessionPublic() automaticamente.
  }

  /// Exclusão permanente da conta do usuário.
  ///
  /// Fluxo:
  /// 1. Chama Edge Function `delete-user` que remove dados em todas as tabelas
  /// 2. Limpa dados locais (SQLite, cache)
  /// 3. Invalida providers keepAlive
  /// 4. Faz signOut
  ///
  /// Apple Guidelines 5.1.1(v): obrigatório para apps com criação de conta.
  Future<void> deleteAccount() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null || userId.isEmpty) {
      throw Exception('Nenhum usuário autenticado.');
    }

    // 1. Chamar Edge Function que deleta dados do servidor
    final response = await client.functions.invoke('delete-user');

    if (response.status != 200) {
      final errorMsg = response.data is Map
          ? (response.data as Map)['error'] ?? 'Erro desconhecido'
          : 'Erro ao excluir conta';
      throw Exception('Falha ao excluir conta: $errorMsg');
    }

    // 2. Limpar dados locais
    try {
      await _clearLocalUserData();
    } catch (e, st) {
      AppLogger.error('clearLocalUserData falhou', tag: 'SessionController', error: e, stackTrace: st);
    }

    // 3. Invalidar providers
    _invalidateUserScopedProviders();

    // 4. SignOut (sessão já invalidada no servidor)
    try {
      await client.auth.signOut();
    } catch (_) {
      // Conta já deletada — signOut pode falhar, ok
    }

    state = const SessionPublic();
  }

  void _invalidateUserScopedProviders() {
    // Invalidar via mecanismo de registro (providers que se auto-registraram)
    for (final entry in _logoutInvalidations.entries) {
      try {
        entry.value(ref);
      } catch (e, st) {
        AppLogger.error(
          'invalidate(${entry.key}) falhou',
          tag: 'SessionController',
          error: e,
          stackTrace: st,
        );
      }
    }

    // P1.A — invalidar providers keepAlive com dados de usuário
    final List<ProviderOrFamily> userScopedProviders = [
      activeLayerProvider,
      showMarkersProvider,
      publicationsDataProvider,
      publicacoesDataProvider,
    ];

    for (final provider in userScopedProviders) {
      try {
        ref.invalidate(provider);
      } catch (e, st) {
        AppLogger.error('invalidate($provider) falhou', tag: 'SessionController', error: e, stackTrace: st);
      }
    }
  }

  Future<void> _clearLocalUserData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    await DatabaseHelper.instance.clearUserLocalData(userId);
  }

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
