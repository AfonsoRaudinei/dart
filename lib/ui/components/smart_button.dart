/*
════════════════════════════════════════════════════════════════════
SMART BUTTON — ARQUITETURA STACK-BASED (SOLOFORTE)
════════════════════════════════════════════════════════════════════

Botão global refatorado para arquitetura Stack.

PROBLEMAS RESOLVIDOS:
1. ✅ Não depende mais do Scaffold (não usa openEndDrawer)
2. ✅ Sempre visível - nunca coberto por drawer/modal
3. ✅ Comportamento 100% baseado na rota atual

CONTRATO OFICIAL:
┌─────────┬───────────────────────┬─────────┬───────────────────────────────┐
│ Nível   │ Rota                  │ Ícone   │ Ação                          │
├─────────┼───────────────────────┼─────────┼───────────────────────────────┤
│ L0      │ /map                  │ ☰       │ Abrir SideMenu (via provider) │
│ L1/L2+  │ Qualquer outra        │ ←       │ context.go(AppRoutes.map)     │
│ PUBLIC  │ /public-map, /login   │ CTA     │ "Acessar SoloForte"           │
└─────────┴───────────────────────┴─────────┴───────────────────────────────┘

PROIBIÇÕES ABSOLUTAS:
❌ Navigator.pop() ou context.pop()
❌ Scaffold.of(context).openEndDrawer()
❌ Lógica baseada em stack de navegação
❌ Múltiplos FABs no sistema

REGRA DE OURO:
"O botão não pertence ao Scaffold. Ele é um overlay global em Stack."
════════════════════════════════════════════════════════════════════
*/
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';
import 'package:soloforte_app/core/state/side_menu_state.dart';

const Color kSyncColorLilas = Color(0xFF7B5EA7);

enum _SyncBadgeState { synced, syncing, error, pending }

/// SmartButton — FAB global (ConsumerStatefulWidget)
///
/// Usa ConsumerStatefulWidget para ter acesso a [mounted].
/// Isso evita "Bad state: Cannot use ref after the widget was disposed"
/// quando callbacks de onPressed são invocados durante transições de rota.
///
/// REGRA: ref.read() é feito no build (síncrono e seguro).
/// Os callbacks NUNCA capturam [ref] — capturam apenas o notifier já lido.
class SmartButton extends ConsumerStatefulWidget {
  const SmartButton({super.key});

  @override
  ConsumerState<SmartButton> createState() => _SmartButtonState();
}

class _SmartButtonState extends ConsumerState<SmartButton> {
  @override
  Widget build(BuildContext context) {
    // ═══════════════════════════════════════════════════════════════
    // 1. OBTER ROTA ATUAL (reativo via GoRouterState InheritedWidget)
    // ═══════════════════════════════════════════════════════════════
    final String uri = GoRouterState.of(context).uri.path;

    // ═══════════════════════════════════════════════════════════════
    // 2. CLASSIFICAR NÍVEL (DETERMINÍSTICO via AppRoutes)
    // ═══════════════════════════════════════════════════════════════
    final RouteLevel level = AppRoutes.getLevel(uri);

    // ═══════════════════════════════════════════════════════════════
    // 3. LER PROVIDERS NO BUILD (síncrono, seguro)
    // Nunca capturar `ref` em closures — capturar apenas o notifier.
    // ═══════════════════════════════════════════════════════════════
    final sideMenuNotifier = level == RouteLevel.l0
        ? ref.read(sideMenuOpenProvider.notifier)
        : null;

    // Accent visual do tema atual.
    final primaryColor = Theme.of(context).colorScheme.primary;
    final safeElevation = 2.0; // Sombra mínima conforme design

    // ═══════════════════════════════════════════════════════════════
    // 4. RENDERIZAR BASEADO NO NÍVEL
    // ═══════════════════════════════════════════════════════════════
    switch (level) {
      case RouteLevel.public:
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // PÚBLICO: CTA "Acessar SoloForte"
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        return FloatingActionButton.extended(
          heroTag: 'smart_button_cta',
          onPressed: () {
            if (!mounted) return;
            context.go(AppRoutes.login);
          },
          backgroundColor: primaryColor,
          elevation: safeElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          label: Text(
            'Acessar SoloForte',
            style: const TextStyle(
              fontSize: 14,
            ).copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          icon: const Icon(Icons.login, color: Colors.white),
        );

      case RouteLevel.l0:
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // L0: MAPA — ☰ Abre SideMenu via Provider
        // NÃO usa Scaffold.openEndDrawer() mais
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        final syncBadgeState = _resolveSyncBadgeState(ref);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton(
              heroTag: 'smart_button_menu',
              onPressed: () {
                // Guard: widget pode ter sido disposed durante transição de rota
                if (!mounted) return;
                // Abrir menu via notifier já capturado no build (sem ref)
                sideMenuNotifier?.state = true;
              },
              backgroundColor: primaryColor,
              elevation: safeElevation,
              shape:
                  const CircleBorder(), // Design: Botões flutuantes circulares
              child: const Icon(Icons.menu, color: Colors.white),
            ),
            Positioned(
              top: -1,
              right: -1,
              child: _SyncBadge(state: syncBadgeState),
            ),
          ],
        );

      case RouteLevel.l1:
      case RouteLevel.l2Plus:
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // L1/L2+: FORA DO MAPA — ← Retorna ao mapa via go()
        // CONTRATO MAP-FIRST: Navegação declarativa obrigatória
        // ❌ SEM pop() — ❌ SEM canPop() — ❌ SEM stack
        // ❌ SEM await — ❌ SEM ref no callback
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        return FloatingActionButton(
          heroTag: 'smart_button_back',
          onPressed: () {
            // Guard: widget pode ter sido disposed durante transição de rota
            if (!mounted) return;
            // Retorno EXPLÍCITO, SÍNCRONO e DECLARATIVO para o mapa
            context.go(AppRoutes.map);
          },
          backgroundColor: primaryColor,
          elevation: safeElevation,
          shape: const CircleBorder(),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        );
    }
  }

  _SyncBadgeState _resolveSyncBadgeState(WidgetRef ref) {
    final orchestrator = ref.watch(syncOrchestratorProvider);
    final connectivity = ref.watch(connectivityStateProvider);

    if (connectivity.asData?.value != true) {
      return _SyncBadgeState.pending;
    }
    if (orchestrator.isSyncing) {
      return _SyncBadgeState.syncing;
    }
    if (orchestrator.lastError != null) {
      return _SyncBadgeState.error;
    }
    return _SyncBadgeState.synced;
  }
}

class _SyncBadge extends StatefulWidget {
  final _SyncBadgeState state;

  const _SyncBadge({required this.state});

  @override
  State<_SyncBadge> createState() => _SyncBadgeStateWidget();
}

class _SyncBadgeStateWidget extends State<_SyncBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _updateRotation();
  }

  @override
  void didUpdateWidget(covariant _SyncBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateRotation();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _updateRotation() {
    if (widget.state == _SyncBadgeState.syncing) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color backgroundColor;
    final IconData icon;

    switch (widget.state) {
      case _SyncBadgeState.synced:
      case _SyncBadgeState.syncing:
        backgroundColor = kSyncColorLilas;
        icon = Icons.sync_rounded;
        break;
      case _SyncBadgeState.error:
        backgroundColor = theme.colorScheme.error;
        icon = Icons.sync_problem_rounded;
        break;
      case _SyncBadgeState.pending:
        backgroundColor = theme.disabledColor;
        icon = Icons.cloud_off_rounded;
        break;
    }

    final badgeIcon = Icon(icon, color: Colors.white, size: 11);

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: widget.state == _SyncBadgeState.syncing
          ? RotationTransition(turns: _rotationController, child: badgeIcon)
          : badgeIcon,
    );
  }
}
