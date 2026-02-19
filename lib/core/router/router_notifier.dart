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
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    // Escuta mudanças no SessionController e notifica o GoRouter.
    // fireImmediately: false — o router já lê o estado inicial no redirect.
    _ref.listen<SessionState>(
      sessionControllerProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;

  /// Retorna true se o usuário está autenticado no momento.
  bool get isAuthenticated =>
      _ref.read(sessionControllerProvider) is SessionAuthenticated;
}

/// Provider keepAlive para [RouterNotifier].
///
/// Não usa code-gen (@riverpod) para evitar que mudanças de hash
/// na função `router()` marquem este provider como stale.
final routerNotifierProvider = Provider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);
