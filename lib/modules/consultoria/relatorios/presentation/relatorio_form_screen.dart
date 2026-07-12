import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/relatorio_providers.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

class RelatorioFormScreen extends ConsumerStatefulWidget {
  final String relatorioId;
  const RelatorioFormScreen({required this.relatorioId, super.key});

  @override
  ConsumerState<RelatorioFormScreen> createState() =>
      _RelatorioFormScreenState();
}

class _RelatorioFormScreenState extends ConsumerState<RelatorioFormScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save(dynamic relatorioAtual) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = relatorioAtual.copyWith(
        title: _titleController.text.trim(),
        customNotes: _notesController.text.trim(),
      );

      await ref.read(relatorioNotifierProvider.notifier).updateRelatorio(updated);

      if (mounted) {
        context.go('/consultoria/relatorios/${widget.relatorioId}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final relatorioAsync =
        ref.watch(relatorioDetailProvider(id: widget.relatorioId));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: relatorioAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
          ),
          error: (error, _) => Center(
            child: Text(userFacingError(error, action: 'Erro'),
                style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          data: (relatorio) {
            if (relatorio == null) {
              return const Center(
                child: Text('Relatório não encontrado',
                    style: TextStyle(color: Color(0xFF6B7280))),
              );
            }

            // Populate on first build only if controllers are empty
            if (_titleController.text.isEmpty &&
                relatorio.title != null &&
                relatorio.title!.isNotEmpty) {
              _titleController.text = relatorio.title!;
            } else if (_titleController.text.isEmpty) {
              _titleController.text = relatorio.farmName; // fallback do detalhe
            }
            if (_notesController.text.isEmpty && relatorio.customNotes != null) {
              _notesController.text = relatorio.customNotes!;
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go(
                            '/consultoria/relatorios/${widget.relatorioId}'),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Editar Relatório',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    maxLength: 120,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Título',
                      labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'O título é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 6,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Observações (Notas customizadas)',
                      labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _isSaving ? null : () => _save(relatorio),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56DB),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Salvar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
