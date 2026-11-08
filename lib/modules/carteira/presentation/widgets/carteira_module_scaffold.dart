import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_keyboard_dismiss.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';

/// Shell do módulo Carteira — AppBar + segment bar fixo + corpo scrollável.
class CarteiraModuleScaffold extends ConsumerStatefulWidget {
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
  ConsumerState<CarteiraModuleScaffold> createState() =>
      _CarteiraModuleScaffoldState();
}

class _CarteiraModuleScaffoldState extends ConsumerState<CarteiraModuleScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CarteiraKeyboardDismiss.dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final CarteiraSegment segment =
        widget.forceSegment ?? ref.watch(carteiraSegmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: widget.leading,
        automaticallyImplyLeading: widget.leading != null,
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
          Expanded(
            child: CarteiraKeyboardDismiss(child: widget.body),
          ),
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
    final onOportunidadesDetail = location.startsWith(
      '${AppRoutes.carteira}/oportunidades/',
    );
    final current = ref.read(carteiraSegmentProvider);

    if (current == value) {
      if (onClienteDetail && value == CarteiraSegment.clientes) {
        CarteiraKeyboardDismiss.dismiss();
        context.go(AppRoutes.carteira);
      }
      if (onOportunidadesDetail && value == CarteiraSegment.oportunidades) {
        CarteiraKeyboardDismiss.dismiss();
        context.go(AppRoutes.carteira);
      }
      return;
    }

    HapticFeedback.selectionClick();
    CarteiraKeyboardDismiss.dismiss();
    ref.read(carteiraSegmentProvider.notifier).state = value;

    if (onClienteDetail ||
        onOportunidadesDetail ||
        location != AppRoutes.carteira) {
      context.go(AppRoutes.carteira);
    }
  }
}
