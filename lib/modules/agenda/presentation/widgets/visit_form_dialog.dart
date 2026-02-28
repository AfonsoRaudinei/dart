import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/event_type.dart';
import '../providers/agenda_provider.dart';
import 'distance_warning_dialog.dart';

/// Dialog para criar nova visita com horário e prioridade
class VisitFormDialog extends ConsumerStatefulWidget {
  const VisitFormDialog({super.key});

  @override
  ConsumerState<VisitFormDialog> createState() => _VisitFormDialogState();
}

class _VisitFormDialogState extends ConsumerState<VisitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  VisitPriority _priority = VisitPriority.normal;
  EventType _tipo = EventType.visitaTecnica;

  double? _latitude;
  double? _longitude;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Se endTime não está definido, define para 1 hora depois
        if (_endTime == null) {
          final endHour = (picked.hour + 1) % 24;
          _endTime = TimeOfDay(hour: endHour, minute: picked.minute);
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validação de horário
    if (_startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

      if (endMinutes <= startMinutes) {
        setState(() {
          _errorMessage = 'Horário de término deve ser maior que o de início';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verifica aviso de distância (não bloqueante)
      final distanceWarning = ref
          .read(agendaProvider.notifier)
          .checkDistanceWarning(
            date: _selectedDate,
            startTime: _startTime,
            endTime: _endTime,
            latitude: _latitude,
            longitude: _longitude,
          );

      // Se há aviso de distância, mostra dialog
      if (distanceWarning != null && mounted) {
        final shouldContinue = await DistanceWarningDialog.show(
          context,
          distanceWarning,
        );

        if (!shouldContinue) {
          setState(() {
            _isLoading = false;
          });
          return; // Usuário escolheu revisar
        }
      }

      final dataInicio = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime?.hour ?? 8,
        _startTime?.minute ?? 0,
      );

      final dataFim = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime?.hour ?? 17,
        _endTime?.minute ?? 0,
      );

      await ref
          .read(agendaProvider.notifier)
          .createEvent(
            tipo: _tipo,
            clienteId: 'temp-client-id', // TODO: selecionar cliente
            titulo: _tituloController.text,
            dataInicioPlanejada: dataInicio,
            dataFimPlanejada: dataFim,
            startTime: _startTime,
            endTime: _endTime,
            priority: _priority,
            latitude: _latitude,
            longitude: _longitude,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on StateError catch (e) {
      // Conflito de horário
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao criar visita: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Visita'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Título é obrigatório';
                  }
                  if (value.trim().length < 3) {
                    return 'Título deve ter no mínimo 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Data
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(_formatDate(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const Divider(),

              // Horário de início
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Horário de início'),
                subtitle: Text(_startTime?.format(context) ?? 'Não definido'),
                trailing: const Icon(Icons.access_time),
                onTap: _selectStartTime,
              ),
              const Divider(),

              // Horário de término
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Horário de término'),
                subtitle: Text(_endTime?.format(context) ?? 'Não definido'),
                trailing: const Icon(Icons.access_time),
                onTap: _selectEndTime,
              ),
              const Divider(),

              // Prioridade
              const SizedBox(height: 8),
              const Text(
                'Prioridade',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<VisitPriority>(
                segments: [
                  ButtonSegment(
                    value: VisitPriority.baixa,
                    label: Text(VisitPriority.baixa.label),
                    icon: Icon(
                      Icons.low_priority,
                      color: VisitPriority.baixa.color,
                    ),
                  ),
                  ButtonSegment(
                    value: VisitPriority.normal,
                    label: Text(VisitPriority.normal.label),
                    icon: Icon(Icons.circle, color: VisitPriority.normal.color),
                  ),
                  ButtonSegment(
                    value: VisitPriority.alta,
                    label: Text(VisitPriority.alta.label),
                    icon: Icon(
                      Icons.priority_high,
                      color: VisitPriority.alta.color,
                    ),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (Set<VisitPriority> selected) {
                  setState(() {
                    _priority = selected.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tipo de evento
              DropdownButtonFormField<EventType>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Evento',
                  border: OutlineInputBorder(),
                ),
                items: EventType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _tipo = value;
                    });
                  }
                },
              ),

              // Mensagem de erro
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar Visita'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
