import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../session/session_controller.dart';
import '../session/session_models.dart';

/// Ponte entre [SessionController] (Riverpod) e [GoRouter] (refreshListenable).
///
/// Ao registrar este notifier como `refreshListenable` no GoRouter,
/// mudanças de autenticação disparam apenas a função `redirect` —
/// sem recriar o GoRouter inteiro e sem destruir a navigation stack.
///
/// Por que ChangeNotifier e não ref.watch direto?
/// `ref.watch` dentro do provider factory invalida o provider inteiro,
/// forçando a recriação do GoRouter a cada troca de estado. Com este
/// notifier o router é instanciado uma única vez e apenas o redirect
/// é re-avaliado internamente pelo GoRouter.
///
/// 🛡 DEBOUNCE — Causa raiz do crash "Cannot use ref after disposed":
/// O Supabase `onAuthStateChange` emite dois eventos em sequência no
/// cold start (1º cache local → 2º validação de rede). Sem debounce,
/// os dois eventos disparam `notifyListeners()` em ~50ms, causando
/// create → dispose → create da `PrivateMapScreen`. O `addPostFrameCallback`
/// da instância descartada executava com ref inválido → crash.
/// O debounce de 300ms colapsa os dois eventos em um único redirect,
/// eliminando o ciclo de vida desnecessário da tela.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    // Escuta mudanças no SessionController e notifica o GoRouter
    // com debounce para evitar double-fire do Supabase no cold start.
    // fireImmediately: false — o router já lê o estado inicial no redirect.
    _ref.listen<SessionState>(
      sessionControllerProvider,
      (previous, next) {
        // 🛡 DEBOUNCE: cancela notificação anterior e agenda nova.
        // Colapsa eventos duplicados do Supabase (cache + rede) em
        // um único notifyListeners(), evitando create/dispose duplo
        // da PrivateMapScreen durante a inicialização.
        _debounce?.cancel();
        _debounce = Timer(_kDebounceDuration, () {
          if (!_isDisposed) notifyListeners();
        });
      },
      fireImmediately: false,
    );
  }

  final Ref _ref;

  /// Janela de debounce: 300ms é suficiente para colapsar o double-fire
  /// do Supabase (cache local ~0ms + validação de rede ~50–200ms)
  /// sem introduzir latência perceptível na troca de tela de login → mapa.
  static const _kDebounceDuration = Duration(milliseconds: 300);

  Timer? _debounce;
  bool _isDisposed = false;

  /// Retorna true se o usuário está autenticado no momento.
  bool get isAuthenticated =>
      _ref.read(sessionControllerProvider) is SessionAuthenticated;

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}

/// Provider keepAlive para [RouterNotifier].
///
/// Não usa code-gen (@riverpod) para evitar que mudanças de hash
/// na função `router()` marquem este provider como stale.
final routerNotifierProvider = Provider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);
