import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/network_policy.dart';
import '../../core/state/map_state.dart';
import '../../modules/consultoria/publicacoes/providers/publicacao_repository_provider.dart';
import '../../modules/consultoria/relatorios/providers/relatorio_repository_provider.dart';
import '../../modules/map/presentation/providers/visit_completion_observer.dart';
import '../../modules/planos/presentation/providers/plano_providers.dart';
import '../database/database_helper.dart';
import 'session_models.dart';

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
      // retorna estado público seguro.
    }
    return const SessionPublic();
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
      await NetworkPolicy.withTimeout(
        () => Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        ),
      );
    } on AuthException catch (e) {
      throw Exception(_traduzirErro(e.message));
    } on TimeoutException {
      throw Exception(
        'Tempo esgotado. Verifique sua conexão e tente novamente.',
      );
    } catch (e) {
      throw Exception('Não foi possível fazer login. Verifique sua conexão.');
    }
    // O stream onAuthStateChange atualiza o state automaticamente.

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isNotEmpty) {
      try {
        await DatabaseHelper.instance.repairOrphanUserIds(userId);
      } catch (e, st) {
        debugPrint('[SessionController] repairOrphanUserIds falhou: $e\n$st');
      }
    }

    // Garantir que perfil criado pelo trigger está completo.
    // Se o cadastro foi feito com email confirmation, o perfil está vazio.
    // Esta chamada preenche os dados do user_metadata.
    try {
      await _ensureProfileComplete();
    } catch (_) {
      // Não bloquear login por falha no perfil
    }
  }

  /// Preenche perfil vazio (criado pelo trigger) com dados do user_metadata.
  /// Idempotente: nunca sobrescreve dados válidos já existentes.
  /// Seguro para múltiplas execuções (login + bootstrap Map).
  Future<void> _ensureProfileComplete() async {
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

    if (profile == null) return;

    final currentName = profile['name'] as String?;
    final currentRole = profile['role'] as String?;

    // Só atualizar campos que estão vazios — nunca sobrescrever dados válidos
    final updates = <String, dynamic>{};

    if (currentName == null || currentName.isEmpty) {
      updates['name'] = user.userMetadata?['full_name'] ?? '';
    }
    if (currentRole == null || currentRole.isEmpty) {
      updates['role'] = user.userMetadata?['role'] ?? 'produtor';
    }

    if (updates.isEmpty) return; // Perfil já completo — noop

    await NetworkPolicy.withTimeout(
      () => client.from('perfis').update(updates).eq('id', user.id),
    );
  }

  /// Cadastro real via Supabase Auth.
  Future<void> signup(String name, String email, String password) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': 'produtor'},
      );
    } on AuthException catch (e) {
      throw Exception(_traduzirErro(e.message));
    } catch (e) {
      throw Exception(
        'Não foi possível criar a conta. Verifique sua conexão.',
      );
    }
    // O stream onAuthStateChange atualiza o state automaticamente.
  }

  /// Logout real via Supabase Auth.
  Future<void> logout() async {
    try {
      await _clearLocalUserData();
    } catch (e, st) {
      debugPrint('[SessionController] clearLocalUserData falhou: $e\n$st');
    }

    _invalidateUserScopedProviders();

    await Supabase.instance.client.auth.signOut();
    // O stream onAuthStateChange seta state = SessionPublic() automaticamente.
  }

  void _invalidateUserScopedProviders() {
    // Invalidar via mecanismo de registro (providers que se auto-registraram)
    for (final entry in _logoutInvalidations.entries) {
      try {
        entry.value(ref);
      } catch (e, st) {
        debugPrint(
          '[SessionController] invalidate(${entry.key}) falhou: $e\n$st',
        );
      }
    }

    // P1.A — invalidar providers keepAlive com dados de usuário
    final List<ProviderOrFamily> userScopedProviders = [
      planoAtivoProvider,
      planoRepositoryProvider,
      relatorioRepositoryProvider,
      publicacaoRepositoryProvider,
      visitCompletionObserverProvider,
      activeLayerProvider,
      showMarkersProvider,
      publicationsDataProvider,
      publicacoesDataProvider,
    ];

    for (final provider in userScopedProviders) {
      try {
        ref.invalidate(provider);
      } catch (e, st) {
        debugPrint('[SessionController] invalidate($provider) falhou: $e\n$st');
      }
    }
  }

  Future<void> _clearLocalUserData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    await DatabaseHelper.instance.clearUserLocalData(userId);
  }

  String _traduzirErro(String message) {
    final lower = message.toLowerCase();
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
        lower.contains('connection')) {
      return 'Sem conexão com a internet. Verifique sua rede.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }
}
