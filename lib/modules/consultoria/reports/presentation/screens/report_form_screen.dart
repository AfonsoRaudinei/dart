import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../clients/presentation/providers/clients_providers.dart';
import '../../domain/report_model.dart';
import '../providers/reports_providers.dart';
import 'package:go_router/go_router.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key});

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  ReportType? _selectedType;
  String? _selectedClientId;
  DateTimeRange? _selectedPeriod;
  final List<String> _imagePaths = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedPeriod,
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione o tipo de relatório')),
        );
        return;
      }
      if (_selectedClientId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Selecione um cliente')));
        return;
      }
      if (_selectedPeriod == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Selecione o período')));
        return;
      }

      final newReport = Report(
        id: const Uuid().v4(),
        title: _titleController.text,
        type: _selectedType!,
        clientId: _selectedClientId!,
        startDate: _selectedPeriod!.start,
        endDate: _selectedPeriod!.end,
        content: _contentController.text,
        createdAt: DateTime.now(),
        author: 'Usuário Atual', // Placeholder
        images: _imagePaths,
      );

      await ref.read(reportControllerProvider).saveReport(newReport);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório salvo com sucesso!')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Novo Relatório',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Type Selection
                    DropdownButtonFormField<ReportType>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Relatório',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedType,
                      items: ReportType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.toString().split('.').last.toUpperCase(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Client Selection
                    clientsAsync.when(
                      data: (clients) {
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedClientId,
                          items: clients.map((client) {
                            return DropdownMenuItem(
                              value: client.id,
                              child: Text(client.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClientId = value;
                            });
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) =>
                          Text('Erro ao carregar clientes: $err'),
                    ),
                    const SizedBox(height: 16),

                    // Period Selection
                    InkWell(
                      onTap: _selectDateRange,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Período',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.date_range),
                        ),
                        child: Text(
                          _selectedPeriod == null
                              ? 'Selecione o período'
                              : '${DateFormat('dd/MM/yyyy').format(_selectedPeriod!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedPeriod!.end)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe um título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Conteúdo',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o conteúdo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Images
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Imagens',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_a_photo),
                        ),
                      ],
                    ),
                    if (_imagePaths.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imagePaths.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.file(
                                    File(_imagePaths[index]),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeImage(index),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('SALVAR RELATÓRIO'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
