import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/contracts/i_producer_crop_calendar.dart';
import '../../../../core/contracts/i_producer_crop_calendar_provider.dart';
import '../../../../core/domain/soy_phenology.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

final producerCropPlantingsProvider =
    FutureProvider.autoDispose<List<ProducerCropPlanting>>((ref) {
      return ref.read(producerCropCalendarProvider).listForProducer();
    });

class ProducerCalendarPlantios extends ConsumerWidget {
  const ProducerCalendarPlantios({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantings = ref.watch(producerCropPlantingsProvider);
    return plantings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Não foi possível carregar os plantios.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum talhão no mapa.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          key: const Key('producer-calendar-plantios'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, kFabSafeArea),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _PlantingCard(planting: entries[index]),
        );
      },
    );
  }
}

class _PlantingCard extends ConsumerStatefulWidget {
  const _PlantingCard({required this.planting});

  final ProducerCropPlanting planting;

  @override
  ConsumerState<_PlantingCard> createState() => _PlantingCardState();
}

class _PlantingCardState extends ConsumerState<_PlantingCard> {
  bool _busy = false;

  ProducerCropPlanting get planting => widget.planting;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final subtitle = _subtitle(planting);
    final plantio = _calendarDate(planting.dataPlantio);
    final emergencia = _calendarDate(planting.dataEmergencia);

    return Material(
      key: ValueKey(planting.fieldId),
      color: context.premiumSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planting.fieldName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: context.premiumTextPrimary,
                height: 1.2,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: context.premiumTextSecondary,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _PlantingLine(
              fieldKey: Key('producer-planting-plantio-${planting.fieldId}'),
              label: 'Plantio',
              value: plantio == null
                  ? _emptyValue(planting.canEdit)
                  : dateFormat.format(plantio),
              filled: plantio != null,
              enabled: planting.canEdit && !_busy,
              onTap: _editPlantio,
            ),
            const _InsetHairline(),
            _PlantingLine(
              fieldKey: Key('producer-planting-emergencia-${planting.fieldId}'),
              label: 'Emergência',
              value: emergencia == null
                  ? _emptyValue(planting.canEdit)
                  : dateFormat.format(emergencia),
              filled: emergencia != null,
              enabled: planting.canEdit && !_busy,
              onTap: _editEmergencia,
            ),
            const _InsetHairline(),
            _PlantingLine(
              fieldKey: Key('producer-planting-ciclo-${planting.fieldId}'),
              label: 'Ciclo',
              value: planting.cicloDias == null
                  ? _emptyValue(planting.canEdit)
                  : '${planting.cicloDias} dias',
              filled: planting.cicloDias != null,
              enabled: planting.canEdit && !_busy,
              onTap: _editCiclo,
            ),
            const SizedBox(height: 10),
            Text(
              _footer(planting, dateFormat),
              style: TextStyle(
                fontSize: 13,
                color: context.premiumTextSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPlantio() => _editDate(isPlantio: true);

  Future<void> _editEmergencia() => _editDate(isPlantio: false);

  Future<void> _editDate({required bool isPlantio}) async {
    if (!planting.canEdit || _busy) return;
    _busy = true;
    unawaited(HapticFeedback.selectionClick());
    try {
      final current = _calendarDate(
        isPlantio ? planting.dataPlantio : planting.dataEmergencia,
      );
      final picked = await showDatePicker(
        context: context,
        initialDate: current ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (!mounted || picked == null) return;
      final iso = _isoDate(picked);
      await _save(
        dataPlantio: isPlantio ? iso : null,
        dataEmergencia: isPlantio ? null : iso,
      );
    } finally {
      _release();
    }
  }

  Future<void> _editCiclo() async {
    if (!planting.canEdit || _busy) return;
    _busy = true;
    unawaited(HapticFeedback.selectionClick());
    try {
      final days = await showDialog<int>(
        context: context,
        builder: (context) => _CicloDialog(initial: planting.cicloDias),
      );
      if (!mounted || days == null) return;
      await _save(cicloDias: '$days');
    } finally {
      _release();
    }
  }

  Future<void> _save({
    String? dataPlantio,
    String? dataEmergencia,
    String? cicloDias,
  }) async {
    try {
      await ref
          .read(producerCropCalendarProvider)
          .saveOwnPlanting(
            fieldId: planting.fieldId,
            dataPlantio: dataPlantio,
            dataEmergencia: dataEmergencia,
            cicloDias: cicloDias,
          );
      if (!mounted) return;
      ref.invalidate(producerCropPlantingsProvider);
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message
          : 'Não foi possível salvar o plantio.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _release() {
    if (!mounted) {
      _busy = false;
      return;
    }
    setState(() => _busy = false);
  }
}

class _PlantingLine extends StatelessWidget {
  const _PlantingLine({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.filled,
    required this.enabled,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: fieldKey,
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.premiumTextSecondary,
                  height: 1.2,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                color: filled
                    ? context.themeAccent
                    : context.premiumTextTertiary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsetHairline extends StatelessWidget {
  const _InsetHairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: PremiumTokens.hairlineThickness,
      color: context.premiumHairline,
    );
  }
}

class _CicloDialog extends StatefulWidget {
  const _CicloDialog({required this.initial});

  final int? initial;

  @override
  State<_CicloDialog> createState() => _CicloDialogState();
}

class _CicloDialogState extends State<_CicloDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final text = widget.initial?.toString() ?? '';
    _controller = TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final days = int.tryParse(raw.trim());
    Navigator.pop(context, days != null && days > 0 ? days : null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.premiumSurface,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 72, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
        side: BorderSide(
          color: context.premiumHairline,
          width: PremiumTokens.hairlineThickness,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('producer-planting-ciclo-input'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: context.premiumTextPrimary,
              ),
              cursorColor: context.themeAccent,
              decoration: InputDecoration(
                hintText: 'Dias',
                hintStyle: TextStyle(color: context.premiumTextTertiary),
                border: InputBorder.none,
              ),
              onSubmitted: _submit,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('producer-planting-ciclo-ok'),
                onPressed: () => _submit(_controller.text),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: context.themeAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _emptyValue(bool canEdit) => canEdit ? 'Adicionar' : '—';

String _subtitle(ProducerCropPlanting planting) {
  return [
    planting.farmName,
    planting.cultura ?? '',
    planting.safra ?? '',
  ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' · ');
}

String _footer(ProducerCropPlanting planting, DateFormat format) {
  final today = DateTime.now();
  final emergencia = parseSoyIsoDate(planting.dataEmergencia);
  final dae = soyCalendarAgeDays(emergencia, today);
  final estadio = suggestedEstadioForDae(dae: dae, cultura: planting.cultura);
  if (estadio != null && dae != null) {
    return '${estadio.name} · $dae dias após a emergência';
  }
  final harvest = approximateSoyHarvestDate(
    dataEmergenciaIso: planting.dataEmergencia,
    dataPlantioIso: planting.dataPlantio,
    cicloDias: planting.cicloDias,
  );
  if (harvest != null) {
    return 'Colheita aproximada: ${format.format(harvest)}';
  }
  return 'Informe a emergência para ver o estádio.';
}

/// Data de calendário do ISO `yyyy-MM-dd`, sem deslocar o dia pelo fuso.
DateTime? _calendarDate(String? iso) {
  final parsed = parseSoyIsoDate(iso);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
