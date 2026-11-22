import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/state/side_menu_state.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// Destino que o consultor pode deixar no bloco único do menu.
enum SideMenuQuickAction {
  novaVisita(
    id: 'nova_visita',
    label: 'Nova Visita',
    icon: Icons.event_available_outlined,
    route: '${AppRoutes.agenda}?novoEvento=true',
  ),
  novoCliente(
    id: 'novo_cliente',
    label: 'Novo Cliente',
    icon: Icons.person_add_alt_1_outlined,
    route: AppRoutes.clientNew,
  ),
  visitas(
    id: 'visitas',
    label: 'Visitas',
    icon: Icons.calendar_today_outlined,
    route: AppRoutes.agenda,
  ),
  clientes(
    id: 'clientes',
    label: 'Clientes',
    icon: Icons.people_outline_rounded,
    route: AppRoutes.clients,
  ),
  carteira(
    id: 'carteira',
    label: 'Carteira',
    icon: Icons.account_balance_wallet_outlined,
    route: AppRoutes.carteira,
  ),
  relatorios(
    id: 'relatorios',
    label: 'Relatórios',
    icon: Icons.analytics_outlined,
    route: AppRoutes.reports,
  );

  const SideMenuQuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;

  static SideMenuQuickAction? byId(String id) {
    for (final action in values) {
      if (action.id == id) return action;
    }
    return null;
  }
}

/// Prefixo da lista salva. O sufixo é o id do usuário, para não misturar contas.
const sideMenuQuickAccessStoragePrefix = 'side_menu_quick_access_ids_v1';

String sideMenuQuickAccessStorageKey(String? userId) =>
    '$sideMenuQuickAccessStoragePrefix:${userId ?? 'device'}';

/// `null` = ainda não escolheu: mostra o catálogo inteiro.
/// Lista vazia = o consultor tirou todos.
List<SideMenuQuickAction> decodeSideMenuQuickAccess(List<String>? raw) {
  if (raw == null) {
    return List<SideMenuQuickAction>.of(SideMenuQuickAction.values);
  }
  final seen = <SideMenuQuickAction>{};
  final selected = <SideMenuQuickAction>[];
  for (final id in raw) {
    final action = SideMenuQuickAction.byId(id);
    if (action == null || !seen.add(action)) continue;
    selected.add(action);
  }
  return selected;
}

class SideMenuQuickAccessNotifier extends Notifier<List<SideMenuQuickAction>> {
  @override
  List<SideMenuQuickAction> build() {
    final userId = ref.watch(currentUserProfileProvider).asData?.value?.id;
    final stored = ref
        .read(preferencesServiceProvider)
        .getStringList(sideMenuQuickAccessStorageKey(userId));
    return decodeSideMenuQuickAccess(stored);
  }

  Future<void> setEnabled(SideMenuQuickAction action, bool enabled) async {
    final next = <SideMenuQuickAction>[
      for (final item in SideMenuQuickAction.values)
        if (item == action ? enabled : state.contains(item)) item,
    ];
    state = next;
    final userId = ref.read(currentUserProfileProvider).asData?.value?.id;
    await ref
        .read(preferencesServiceProvider)
        .setStringList(
          sideMenuQuickAccessStorageKey(userId),
          next.map((item) => item.id).toList(),
        );
  }
}

final sideMenuQuickAccessProvider =
    NotifierProvider<SideMenuQuickAccessNotifier, List<SideMenuQuickAction>>(
      SideMenuQuickAccessNotifier.new,
    );

/// Bloco único que substitui Acesso rápido e Atalhos.
class SideMenuQuickAccessBlock extends ConsumerWidget {
  const SideMenuQuickAccessBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(sideMenuQuickAccessProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ACESSO RÁPIDO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            TextButton(
              key: const Key('side_menu_quick_access_edit'),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => showSideMenuQuickAccessEditor(context),
              child: const Text(
                'Editar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (selected.isEmpty)
          _QuickAccessEmpty(
            onChoose: () => showSideMenuQuickAccessEditor(context),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final action in selected)
                    _QuickAccessTile(
                      action: action,
                      onTap: () => _closeAndOpen(context, ref, action.route),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickAccessEmpty extends StatelessWidget {
  const _QuickAccessEmpty({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('side_menu_quick_access_empty'),
        borderRadius: BorderRadius.circular(16),
        onTap: onChoose,
        child: SizedBox(
          height: 76,
          child: Center(
            child: Text(
              'Escolher atalhos',
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.action, required this.onTap});

  final SideMenuQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 76,
      height: 64,
      child: Semantics(
        button: true,
        label: action.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('side_menu_quick_${action.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, size: 20, color: accent),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.premiumTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _closeAndOpen(BuildContext context, WidgetRef ref, String route) {
  ref.read(sideMenuOpenProvider.notifier).state = false;
  final router = GoRouter.of(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    router.go(route);
  });
}

Future<void> showSideMenuQuickAccessEditor(BuildContext context) {
  return showSoloForteSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    maxHeightFraction: 0.72,
    builder: (_) => const SideMenuQuickAccessEditor(),
  );
}

class SideMenuQuickAccessEditor extends ConsumerWidget {
  const SideMenuQuickAccessEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visuals = SoloForteSheetVisuals.of(context);
    final selected = ref.watch(sideMenuQuickAccessProvider);

    return Material(
      color: visuals.sheetBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, kFabSafeArea),
        children: [
          Text(
            'Acesso rápido',
            style: TextStyle(
              fontSize: visuals.titleFontSize,
              fontWeight: visuals.titleWeight,
              color: visuals.titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Escolha o que fica neste bloco.',
            style: TextStyle(fontSize: 13, color: visuals.subtitleColor),
          ),
          const SizedBox(height: 12),
          for (final action in SideMenuQuickAction.values)
            _EditorRow(
              action: action,
              enabled: selected.contains(action),
              visuals: visuals,
              onChanged: (value) {
                ref
                    .read(sideMenuQuickAccessProvider.notifier)
                    .setEnabled(action, value);
              },
            ),
        ],
      ),
    );
  }
}

class _EditorRow extends StatelessWidget {
  const _EditorRow({
    required this.action,
    required this.enabled,
    required this.visuals,
    required this.onChanged,
  });

  final SideMenuQuickAction action;
  final bool enabled;
  final SoloForteSheetVisuals visuals;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: visuals.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: visuals.iconStroke, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: visuals.titleColor,
                  ),
                ),
              ),
              Switch(
                key: Key('side_menu_quick_access_toggle_${action.id}'),
                value: enabled,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.6, color: visuals.dividerColor),
      ],
    );
  }
}
