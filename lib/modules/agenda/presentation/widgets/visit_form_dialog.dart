import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/visit.dart';
import '../../domain/enums/event_type.dart';
import '../providers/agenda_provider.dart';
import 'client_selector_dropdown.dart';
import 'distance_warning_dialog.dart';
import 'oportunidades_cliente_section.dart';

/// Dialog para criar nova visita com horário e prioridade
class VisitFormDialog extends ConsumerStatefulWidget {
  const VisitFormDialog({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<VisitFormDialog> createState() => _VisitFormDialogState();
}

class _VisitFormDialogState extends ConsumerState<VisitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  VisitPriority _priority = VisitPriority.normal;
  EventType _tipo = EventType.visitaTecnica;

  double? _latitude;
  double? _longitude;

  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedClienteId;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _capturarLocalizacao();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _capturarLocalizacao() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (_) {
      // Falha silenciosa: coordenadas permanecem null.
    }
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

    if (_selectedClienteId == null) {
      setState(() {
        _errorMessage = 'Selecione um cliente para continuar';
      });
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
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
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
            clienteId: _selectedClienteId!,
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
        final warning = ref
            .read(agendaProvider.notifier)
            .checkDistanceWarning(
              dataInicioPlanejada: dataInicio,
              latitude: _latitude,
              longitude: _longitude,
              startTime: _startTime,
            );

        if (warning != null) {
          await DistanceWarningDialog.show(context, warning);
        }

        navigator.pop(true);
        messenger.showSnackBar(
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
              // Cliente
              ClientSelectorDropdown(
                selectedClientId: _selectedClienteId,
                onChanged: (id) => setState(() => _selectedClienteId = id),
              ),
              OportunidadesClienteSection(
                clienteId: _selectedClienteId,
                onTituloSelecionado: (titulo) {
                  setState(() {
                    _tituloController.text = titulo;
                  });
                },
              ),
              const SizedBox(height: 16),

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

              // Horários
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      label: 'Início',
                      value: _startTime?.format(context) ?? 'Não definido',
                      icon: Icons.schedule_outlined,
                      onTap: _selectStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeField(
                      label: 'Término',
                      value: _endTime?.format(context) ?? 'Não definido',
                      icon: Icons.schedule_outlined,
                      onTap: _selectEndTime,
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Prioridade
              const SizedBox(height: 8),
              const Text(
                'Prioridade',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PriorityChip(
                    label: 'Baixa',
                    icon: Icons.low_priority_outlined,
                    isSelected: _priority == VisitPriority.baixa,
                    selectedColor: Colors.grey.shade600,
                    onTap: () {
                      setState(() {
                        _priority = VisitPriority.baixa;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _PriorityChip(
                    label: 'Normal',
                    icon: Icons.check_circle_outline,
                    isSelected: _priority == VisitPriority.normal,
                    selectedColor: const Color(0xFF4ADE80),
                    onTap: () {
                      setState(() {
                        _priority = VisitPriority.normal;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _PriorityChip(
                    label: 'Alta',
                    icon: Icons.priority_high_outlined,
                    isSelected: _priority == VisitPriority.alta,
                    selectedColor: Colors.red.shade400,
                    onTap: () {
                      setState(() {
                        _priority = VisitPriority.alta;
                      });
                    },
                  ),
                ],
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

  Widget _buildTimeField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

class _PriorityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? selectedColor : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? selectedColor : Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? selectedColor : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
