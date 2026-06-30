import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_presenter_provider.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/visit_client_hierarchy.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

final _visitClientHierarchyProvider = FutureProvider.autoDispose
    .family<VisitClientHierarchy?, String>((ref, clientId) {
      return ref.watch(visitClientLookupProvider).getClientHierarchy(clientId);
    });

/// Card compacto de visita ativa — canto superior esquerdo do mapa.
///
/// ADR-045: dados de cliente via IVisitClientLookup; NDVI via INdviFieldPresenter.
class VisitActiveCard extends ConsumerWidget {
  const VisitActiveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(visitControllerProvider);
    final session = sessionAsync.valueOrNull;

    if (session == null) return const SizedBox.shrink();

    final hierarchyAsync = ref.watch(
      _visitClientHierarchyProvider(session.producerId),
    );

    return hierarchyAsync.when(
      loading: () => _GlassChip(child: _LoadingRow()),
      error: (_, __) => const SizedBox.shrink(),
      data: (hierarchy) {
        if (hierarchy == null) return const SizedBox.shrink();

        VisitFarmDetailSummary? currentFarm = hierarchy.farms
            .where((farm) => farm.id == session.farmId)
            .firstOrNull;
        VisitFieldDetailSummary? currentTalhao;
        for (final farm in hierarchy.farms) {
          for (final talhao in farm.fields) {
            if (talhao.id == session.areaId) {
              currentFarm = farm;
              currentTalhao = talhao;
              break;
            }
          }
          if (currentTalhao != null) break;
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.62,
          ),
          child: _GlassChip(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: PremiumTokens.brandGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: PremiumTokens.brandGreen.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        hierarchy.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: PremiumTokens.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Container(
                    height: 0.5,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                _EditableRow(
                  label: currentFarm?.name ?? '—',
                  icon: Icons.landscape_outlined,
                  onTap: () => _showFarmSheet(
                    context,
                    ref,
                    hierarchy,
                    currentFarm,
                    currentTalhao,
                  ),
                ),
                const SizedBox(height: 3),
                _EditableRow(
                  label: currentTalhao?.name ?? '—',
                  icon: Icons.grid_view_rounded,
                  onTap: currentFarm == null
                      ? null
                      : () => _showTalhaoSheet(
                          context,
                          ref,
                          currentFarm!,
                          currentTalhao,
                        ),
                ),
                if (session.areaId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(ndviFieldPresenterProvider)
                          .showTalhaoSheet(
                            context,
                            fieldId: session.areaId!,
                            fieldName: currentTalhao?.name ?? session.areaId!,
                            areaHa: currentTalhao?.areaHa,
                          ),
                      icon: const Icon(Icons.satellite_alt_outlined, size: 16),
                      label: const Text('NDVI'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFarmSheet(
    BuildContext context,
    WidgetRef ref,
    VisitClientHierarchy hierarchy,
    VisitFarmDetailSummary? currentFarm,
    VisitFieldDetailSummary? currentTalhao,
  ) {
    HapticFeedback.lightImpact();
    showSoloForteSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (_) => _SelectionSheet(
        title: 'Selecionar Fazenda',
        items: hierarchy.farms.map((f) => f.name).toList(),
        selectedIndex: currentFarm == null
            ? null
            : hierarchy.farms.indexWhere((f) => f.id == currentFarm.id),
        onSelect: (index) async {
          final newFarm = hierarchy.farms[index];
          final controller = ref.read(visitControllerProvider.notifier);
          await controller.updateFarm(newFarm.id);
          if (newFarm.fields.isNotEmpty) {
            await controller.updateArea(
              newFarm.fields.first.id,
              farmId: newFarm.id,
            );
          }
        },
      ),
    );
  }

  void _showTalhaoSheet(
    BuildContext context,
    WidgetRef ref,
    VisitFarmDetailSummary farm,
    VisitFieldDetailSummary? currentTalhao,
  ) {
    HapticFeedback.lightImpact();
    showSoloForteSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (_) => _SelectionSheet(
        title: 'Selecionar Talhão',
        items: farm.fields.map((t) => t.name).toList(),
        selectedIndex: currentTalhao == null
            ? null
            : farm.fields.indexWhere((t) => t.id == currentTalhao.id),
        onSelect: (index) {
          final newTalhao = farm.fields[index];
          ref
              .read(visitControllerProvider.notifier)
              .updateArea(newTalhao.id, farmId: farm.id);
        },
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final Widget child;

  const _GlassChip({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.07),
                offset: Offset(0, 8),
                blurRadius: 28,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _EditableRow({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: PremiumTokens.textPrimaryLight.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: onTap != null
                    ? PremiumTokens.brandGreen
                    : const Color(0xFF3C3C43),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.expand_more_rounded,
              size: 13,
              color: PremiumTokens.brandGreen.withValues(alpha: 0.8),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: PremiumTokens.brandGreen.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Carregando...',
          style: TextStyle(
            fontSize: 12,
            color: PremiumTokens.textPrimaryLight.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SelectionSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _SelectionSheet({
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC5C5C7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => Container(
                height: 0.5,
                color: Colors.black.withValues(alpha: 0.07),
              ),
              itemBuilder: (_, index) {
                final isSelected = index == selectedIndex;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    items[index],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? PremiumTokens.brandGreen
                          : PremiumTokens.textPrimaryLight,
                      letterSpacing: -0.3,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: PremiumTokens.brandGreen,
                        )
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(index);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
