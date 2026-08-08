import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';

/// Shell do módulo Carteira — AppBar + segment bar fixo + corpo scrollável.
class CarteiraModuleScaffold extends ConsumerWidget {
  const CarteiraModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.forceSegment,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final CarteiraSegment? forceSegment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CarteiraSegment segment =
        forceSegment ?? ref.watch(carteiraSegmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        automaticallyImplyLeading: leading != null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: CarteiraSegmentBar(
                    selected: segment,
                    onSelected: (value) =>
                        _onSegmentSelected(context, ref, value),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  void _onSegmentSelected(
    BuildContext context,
    WidgetRef ref,
    CarteiraSegment value,
  ) {
    final location = GoRouterState.of(context).uri.path;
    final onClienteDetail = location.startsWith(
      '${AppRoutes.carteira}/cliente/',
    );
    final current = ref.read(carteiraSegmentProvider);

    if (current == value) {
      if (onClienteDetail && value == CarteiraSegment.clientes) {
        context.go(AppRoutes.carteira);
      }
      return;
    }

    HapticFeedback.selectionClick();
    ref.read(carteiraSegmentProvider.notifier).state = value;

    if (onClienteDetail || location != AppRoutes.carteira) {
      context.go(AppRoutes.carteira);
    }
  }
}
