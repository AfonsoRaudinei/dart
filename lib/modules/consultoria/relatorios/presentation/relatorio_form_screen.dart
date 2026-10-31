import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

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

      // Hub pós-edição: RelatorioDetailScreen (lista usa HtmlReportViewer no tap).
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
    final theme = Theme.of(context);
    final relatorioAsync =
        ref.watch(relatorioDetailProvider(id: widget.relatorioId));

    return Scaffold(
      backgroundColor: context.premiumBackground,
      body: SafeArea(
        child: relatorioAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          ),
          error: (error, _) => Center(
            child: Text(
              userFacingError(error, action: 'Erro'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.premiumTextSecondary,
              ),
            ),
          ),
          data: (relatorio) {
            if (relatorio == null) {
              return Center(
                child: Text(
                  'Relatório não encontrado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.premiumTextSecondary,
                  ),
                ),
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
                      Text(
                        'Editar Relatório',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    maxLength: 120,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Título',
                      filled: true,
                      fillColor: context.premiumSurface,
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
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Observações (Notas customizadas)',
                      filled: true,
                      fillColor: context.premiumSurface,
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
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
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
