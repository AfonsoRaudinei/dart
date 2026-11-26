import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/carteira_providers.dart';
import 'safra_selector_sheet.dart';

/// Chip da safra ativa no topo da Carteira. Todos os números da Carteira são
/// da safra mostrada aqui; o toque abre o seletor de safra.
class CarteiraSafraChip extends ConsumerWidget {
  const CarteiraSafraChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final safraAsync = ref.watch(safraAtivaProvider);
    final safra = safraAsync.valueOrNull;
    final carregando = safraAsync.isLoading && safra == null;
    final rotulo = carregando ? 'Safra' : (safra?.nome ?? 'Criar safra');

    return Semantics(
      button: true,
      label: safra == null
          ? (carregando ? 'Safra' : 'Criar safra')
          : 'Safra ativa: ${safra.nome}. Toque para trocar.',
      excludeSemantics: true,
      child: Material(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        shape: StadiumBorder(
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showSafraSelectorSheet(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      rotulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
