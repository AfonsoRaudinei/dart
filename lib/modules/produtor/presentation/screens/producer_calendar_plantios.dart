import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/contracts/i_producer_crop_calendar.dart';
import '../../../../core/contracts/i_producer_crop_calendar_provider.dart';
import '../../../../core/domain/soy_phenology.dart';

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

class _PlantingCard extends ConsumerWidget {
  const _PlantingCard({required this.planting});

  final ProducerCropPlanting planting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final emergencia = parseSoyIsoDate(planting.dataEmergencia);
    final dae = soyCalendarAgeDays(emergencia, today);
    final estadio = suggestedEstadioForDae(dae: dae, cultura: planting.cultura);
    final harvest = approximateSoyHarvestDate(
      dataEmergenciaIso: planting.dataEmergencia,
      dataPlantioIso: planting.dataPlantio,
      cicloDias: planting.cicloDias,
    );
    final culturaSafra = [
      planting.cultura,
      planting.safra,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(planting.fieldName, style: theme.textTheme.titleMedium),
            if (planting.farmName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(planting.farmName),
            ],
            if (culturaSafra.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(culturaSafra),
            ],
            const SizedBox(height: 12),
            Text('Plantio: ${_formatIso(planting.dataPlantio, dateFormat)}'),
            const SizedBox(height: 4),
            Text(
              'Emergência: ${_formatIso(planting.dataEmergencia, dateFormat)}',
            ),
            const SizedBox(height: 8),
            _StageLine(estadio: estadio, dae: dae, cultura: planting.cultura),
            const SizedBox(height: 8),
            if (harvest != null)
              Text('Colheita aproximada: ${dateFormat.format(harvest)}')
            else if (planting.cicloDias == null)
              const Text('Ciclo não informado.'),
            if (_needsRegistration(planting)) ...[
              const SizedBox(height: 12),
              _OwnPlantingForm(planting: planting),
            ],
          ],
        ),
      ),
    );
  }
}

class _StageLine extends StatelessWidget {
  const _StageLine({
    required this.estadio,
    required this.dae,
    required this.cultura,
  });

  final EstadioData? estadio;
  final int? dae;
  final String? cultura;

  @override
  Widget build(BuildContext context) {
    final stage = estadio;
    if (stage != null) {
      return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(stage.name),
        subtitle: dae == null ? null : Text('$dae dias após a emergência'),
        children: [
          for (final note in stage.attention)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(note),
              ),
            ),
        ],
      );
    }

    final crop = cultura?.trim().toLowerCase() ?? '';
    if (dae != null && crop.isNotEmpty && !crop.contains('soja')) {
      return const Text('Estádio não estimado para esta cultura.');
    }
    return const Text('Sem emergência para estimar o estádio.');
  }
}

class _OwnPlantingForm extends ConsumerStatefulWidget {
  const _OwnPlantingForm({required this.planting});

  final ProducerCropPlanting planting;

  @override
  ConsumerState<_OwnPlantingForm> createState() => _OwnPlantingFormState();
}

class _OwnPlantingFormState extends ConsumerState<_OwnPlantingForm> {
  late DateTime? _plantio;
  late DateTime? _emergencia;
  late final TextEditingController _ciclo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _plantio = parseSoyIsoDate(widget.planting.dataPlantio);
    _emergencia = parseSoyIsoDate(widget.planting.dataEmergencia);
    _ciclo = TextEditingController(
      text: widget.planting.cicloDias?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registrar plantio',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _DateButton(
          label: 'Início do plantio',
          value: _plantio,
          format: dateFormat,
          onPick: (value) => setState(() => _plantio = value),
        ),
        _DateButton(
          label: 'Emergência',
          value: _emergencia,
          format: dateFormat,
          onPick: (value) => setState(() => _emergencia = value),
        ),
        TextField(
          controller: _ciclo,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Ciclo (dias)'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Salvando' : 'Salvar'),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final plantio = _plantio;
    if (plantio == null) {
      _show('Informe o início do plantio.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(producerCropCalendarProvider)
          .saveOwnPlanting(
            fieldId: widget.planting.fieldId,
            dataPlantio: _isoDate(plantio),
            dataEmergencia: _isoDate(_emergencia),
            cicloDias: _ciclo.text.trim(),
          );
      ref.invalidate(producerCropPlantingsProvider);
    } catch (error) {
      if (!mounted) return;
      _show(
        error is StateError
            ? error.message
            : 'Não foi possível salvar o plantio.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.format,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final DateFormat format;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final current = value;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: current ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) onPick(picked);
        },
        child: Text(
          current == null ? label : '$label: ${format.format(current)}',
        ),
      ),
    );
  }
}

bool _needsRegistration(ProducerCropPlanting planting) {
  return planting.canEdit &&
      (planting.dataPlantio == null ||
          planting.dataEmergencia == null ||
          planting.cicloDias == null);
}

String _formatIso(String? iso, DateFormat format) {
  final date = parseSoyIsoDate(iso);
  if (date == null) return 'Não informado';
  return format.format(date);
}

String? _isoDate(DateTime? date) {
  if (date == null) return null;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
