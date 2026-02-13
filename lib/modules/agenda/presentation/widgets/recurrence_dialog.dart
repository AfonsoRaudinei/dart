// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/recurrence_pattern.dart';
import '../../domain/entities/event_recurrence.dart';

/// Dialog para configurar recorrência de eventos
class RecurrenceDialog extends ConsumerStatefulWidget {
  final EventRecurrence? initialRecurrence;

  const RecurrenceDialog({
    super.key,
    this.initialRecurrence,
  });

  @override
  ConsumerState<RecurrenceDialog> createState() => _RecurrenceDialogState();
}

class _RecurrenceDialogState extends ConsumerState<RecurrenceDialog> {
  late RecurrencePattern _pattern;
  late int _interval;
  DateTime? _endDate;
  int? _occurrences;
  bool _useEndDate = false;
  bool _useOccurrences = false;

  @override
  void initState() {
    super.initState();
    _pattern = widget.initialRecurrence?.pattern ?? RecurrencePattern.weekly;
    _interval = widget.initialRecurrence?.interval ?? 1;
    _endDate = widget.initialRecurrence?.endDate;
    _occurrences = widget.initialRecurrence?.occurrences;
    _useEndDate = _endDate != null;
    _useOccurrences = _occurrences != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Configurar Recorrência'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Padrão de recorrência
            Text(
              'Repetir',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RecurrencePattern>(
              value: _pattern,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: RecurrencePattern.values.map((pattern) {
                return DropdownMenuItem(
                  value: pattern,
                  child: Text(pattern.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _pattern = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Intervalo
            Text(
              'A cada',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: _interval.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() => _interval = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(_getIntervalLabel()),
              ],
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 8),

            // Finalização
            Text(
              'Termina',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            // Opção: Nunca
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Radio<String>(
                value: 'never',
                groupValue: _useEndDate
                    ? 'endDate'
                    : _useOccurrences
                        ? 'occurrences'
                        : 'never',
                onChanged: (_) {
                  setState(() {
                    _useEndDate = false;
                    _useOccurrences = false;
                  });
                },
              ),
              title: const Text('Nunca'),
              onTap: () {
                setState(() {
                  _useEndDate = false;
                  _useOccurrences = false;
                });
              },
            ),

            // Opção: Data específica
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Radio<String>(
                value: 'endDate',
                groupValue: _useEndDate
                    ? 'endDate'
                    : _useOccurrences
                        ? 'occurrences'
                        : 'never',
                onChanged: (_) {
                  setState(() {
                    _useEndDate = true;
                    _useOccurrences = false;
                    _endDate ??= DateTime.now().add(const Duration(days: 30));
                  });
                },
              ),
              title: const Text('Em'),
              onTap: () {
                setState(() {
                  _useEndDate = true;
                  _useOccurrences = false;
                  _endDate ??= DateTime.now().add(const Duration(days: 30));
                });
              },
            ),
            if (_useEndDate)
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _endDate != null
                        ? '${_endDate!.day.toString().padLeft(2, '0')}/'
                            '${_endDate!.month.toString().padLeft(2, '0')}/'
                            '${_endDate!.year}'
                        : 'Selecionar',
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                ),
              ),

            // Opção: Quantidade de ocorrências
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Radio<String>(
                value: 'occurrences',
                groupValue: _useEndDate
                    ? 'endDate'
                    : _useOccurrences
                        ? 'occurrences'
                        : 'never',
                onChanged: (_) {
                  setState(() {
                    _useEndDate = false;
                    _useOccurrences = true;
                    _occurrences ??= 10;
                  });
                },
              ),
              title: const Text('Após'),
              onTap: () {
                setState(() {
                  _useEndDate = false;
                  _useOccurrences = true;
                  _occurrences ??= 10;
                });
              },
            ),
            if (_useOccurrences)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: _occurrences?.toString() ?? '10',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0) {
                            setState(() => _occurrences = parsed);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('ocorrências'),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final recurrence = EventRecurrence(
              pattern: _pattern,
              interval: _interval,
              endDate: _useEndDate ? _endDate : null,
              occurrences: _useOccurrences ? _occurrences : null,
            );
            Navigator.pop(context, recurrence);
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  String _getIntervalLabel() {
    if (_interval == 1) {
      switch (_pattern) {
        case RecurrencePattern.daily:
          return 'dia';
        case RecurrencePattern.weekly:
          return 'semana';
        case RecurrencePattern.biweekly:
          return 'quinzena';
        case RecurrencePattern.monthly:
          return 'mês';
        case RecurrencePattern.yearly:
          return 'ano';
      }
    } else {
      switch (_pattern) {
        case RecurrencePattern.daily:
          return 'dias';
        case RecurrencePattern.weekly:
          return 'semanas';
        case RecurrencePattern.biweekly:
          return 'quinzenas';
        case RecurrencePattern.monthly:
          return 'meses';
        case RecurrencePattern.yearly:
          return 'anos';
      }
    }
  }
}
