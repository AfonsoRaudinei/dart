import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_models.dart';
import 'package:soloforte_app/modules/produtor/data/producer_property_repository.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

final producerMapSelectedFarmIdProvider = StateProvider<String?>((ref) => null);
final producerMapSelectedFieldIdProvider = StateProvider<String?>(
  (ref) => null,
);

class ProducerMapContextCard extends ConsumerWidget {
  const ProducerMapContextCard({
    super.key,
    required this.onFocusFarm,
    required this.onFocusField,
  });

  final bool Function(List<Talhao> fields) onFocusFarm;
  final bool Function(Talhao field) onFocusField;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(producerPropertyDashboardProvider);

    return dashboardAsync.when(
      loading: () => const _GlassCard(child: _LoadingLine()),
      error: (_, __) => const SizedBox.shrink(),
      data: (dashboard) {
        final property = dashboard.ownProperty;
        final farms = property.farms;
        final selectedFarmId = ref.watch(producerMapSelectedFarmIdProvider);
        final selectedFieldId = ref.watch(producerMapSelectedFieldIdProvider);
        final selectedFarm = _selectedFarm(farms, selectedFarmId);
        final selectedField = _selectedField(selectedFarm, selectedFieldId);

        _syncMapFarmSelection(ref, farms, selectedFarmId);

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.62,
          ),
          child: _GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProducerLine(name: property.name),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Container(
                    height: 0.5,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                _PickerLine<ProducerOwnFarm>(
                  icon: Icons.landscape_outlined,
                  label: selectedFarm?.name ?? 'Sem fazenda',
                  enabled: farms.isNotEmpty,
                  items: farms,
                  itemLabel: (farm) => farm.name,
                  onSelected: (farm) =>
                      unawaited(_selectFarm(context, ref, property, farm)),
                ),
                const SizedBox(height: 3),
                _PickerLine<ProducerOwnField>(
                  icon: Icons.grid_view_rounded,
                  label: selectedField?.name ?? 'Sem talhão',
                  enabled:
                      selectedFarm != null && selectedFarm.fields.isNotEmpty,
                  items: selectedFarm?.fields ?? const [],
                  itemLabel: (field) => field.name,
                  trailing: selectedField?.hasGeometry == true
                      ? Icons.center_focus_strong_rounded
                      : null,
                  onSelected: selectedFarm == null
                      ? null
                      : (field) => unawaited(
                          _selectField(context, ref, selectedFarm, field),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ProducerOwnFarm? _selectedFarm(
    List<ProducerOwnFarm> farms,
    String? selectedFarmId,
  ) {
    if (farms.isEmpty) return null;
    if (selectedFarmId == null) return farms.first;
    return farms.where((farm) => farm.id == selectedFarmId).firstOrNull ??
        farms.first;
  }

  ProducerOwnField? _selectedField(
    ProducerOwnFarm? farm,
    String? selectedFieldId,
  ) {
    if (farm == null || farm.fields.isEmpty) return null;
    if (selectedFieldId == null) return null;
    return farm.fields
        .where((field) => field.id == selectedFieldId)
        .firstOrNull;
  }

  void _syncMapFarmSelection(
    WidgetRef ref,
    List<ProducerOwnFarm> farms,
    String? selectedFarmId,
  ) {
    if (farms.isEmpty) return;
    final selectedExists = farms.any((farm) => farm.id == selectedFarmId);
    if (selectedFarmId != null && selectedExists) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final farm = farms.first;
      ref.read(producerMapSelectedFarmIdProvider.notifier).state = farm.id;
      ref.read(producerMapSelectedFieldIdProvider.notifier).state = null;
      ref.read(selectedFarmIdProvider.notifier).state = farm.id;
      ref.read(selectedTalhaoIdProvider.notifier).state = null;
    });
  }

  Future<void> _selectFarm(
    BuildContext context,
    WidgetRef ref,
    ProducerOwnProperty property,
    ProducerOwnFarm farm,
  ) async {
    HapticFeedback.selectionClick();
    ref.read(producerMapSelectedFarmIdProvider.notifier).state = farm.id;
    ref.read(producerMapSelectedFieldIdProvider.notifier).state = null;
    ref.read(selectedFarmIdProvider.notifier).state = farm.id;
    ref.read(selectedTalhaoIdProvider.notifier).state = null;

    final fields = await ref.read(farmFieldsProvider(farm.id).future);
    if (!context.mounted) return;

    if (onFocusFarm(fields)) return;
    _showMapMessage(
      context,
      '${property.name} · ${farm.name} sem geometria no mapa.',
    );
  }

  Future<void> _selectField(
    BuildContext context,
    WidgetRef ref,
    ProducerOwnFarm farm,
    ProducerOwnField field,
  ) async {
    HapticFeedback.selectionClick();
    ref.read(producerMapSelectedFieldIdProvider.notifier).state = field.id;
    ref.read(selectedTalhaoIdProvider.notifier).state = field.id;

    final fields = await ref.read(farmFieldsProvider(farm.id).future);
    if (!context.mounted) return;

    final mapField = fields.where((item) => item.id == field.id).firstOrNull;
    if (mapField != null && onFocusField(mapField)) return;
    _showMapMessage(context, '${field.name} sem geometria no mapa.');
  }

  void _showMapMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black.withValues(alpha: 0.78),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 96,
      height: 18,
      child: LinearProgressIndicator(minHeight: 2),
    );
  }
}

class _ProducerLine extends StatelessWidget {
  const _ProducerLine({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                color: PremiumTokens.brandGreen.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
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
    );
  }
}

class _PickerLine<T> extends StatelessWidget {
  const _PickerLine({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T>? onSelected;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final textColor = enabled
        ? PremiumTokens.textPrimaryLight
        : PremiumTokens.textSecondaryLight;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textColor.withValues(alpha: 0.72)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 4),
          Icon(trailing, size: 13, color: PremiumTokens.brandGreen),
        ],
        const SizedBox(width: 4),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 15,
          color: textColor.withValues(alpha: enabled ? 0.72 : 0.36),
        ),
      ],
    );

    if (!enabled || onSelected == null) {
      return Opacity(opacity: 0.78, child: row);
    }

    return PopupMenuButton<T>(
      tooltip: label,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      child: row,
    );
  }
}
