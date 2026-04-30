import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../models/relatorio_status.dart';
import '../models/relatorio_tecnico.dart';
import '../providers/relatorio_providers.dart';
import '../use_cases/publish_relatorio_use_case.dart';
import '../../../../core/constants/layout_constants.dart';

/// Tela de Detalhe do Relatório Técnico — PASSO 3
///
/// Rota: [AppRoutes.relatorioDetail] (/consultoria/relatorios/:id) — L2+
///
/// Layout: CustomScrollView com slivers
///
/// Comportamento por status:
///   - [pendente_revisao]: campos editáveis + botão PUBLICAR
///   - [publicado] / [arquivado]: somente leitura
///
/// Navegação: sem AppBar. SmartButton global cuida do retorno.
class RelatorioDetailScreen extends ConsumerStatefulWidget {
  const RelatorioDetailScreen({super.key, required this.relatorioId});

  final String relatorioId;

  @override
  ConsumerState<RelatorioDetailScreen> createState() =>
      _RelatorioDetailScreenState();
}

class _RelatorioDetailScreenState extends ConsumerState<RelatorioDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  bool _isDirty = false;
  bool _isPublishing = false;
  bool _fieldsSynced = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();

    _titleController.addListener(_markDirty);
    _notesController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  void _syncFields(RelatorioTecnico relatorio) {
    if (_fieldsSynced) return;
    _titleController.text = relatorio.title ?? '';
    _notesController.text = relatorio.customNotes ?? '';
    _fieldsSynced = true;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(relatorioDetailProvider(id: widget.relatorioId));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar relatório:\n$error',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (relatorio) {
            if (relatorio == null) {
              return const Center(
                child: Text(
                  'Relatório não encontrado.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              );
            }

            _syncFields(relatorio);

            return CustomScrollView(
              slivers: [
                _buildHeader(relatorio),
                _buildInfoCard(relatorio),
                if (relatorio.status == RelatorioStatus.pendente_revisao)
                  _buildEditCard(relatorio),
                if (relatorio.ocorrencias.isNotEmpty)
                  _buildOcorrenciasCard(relatorio),
                if (relatorio.talhoes.isNotEmpty) _buildTalhoesCard(relatorio),
                if (relatorio.status == RelatorioStatus.pendente_revisao)
                  _buildPublishButton(relatorio),
                const SliverToBoxAdapter(child: SizedBox(height: kFabSafeArea)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SLIVERS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildHeader(RelatorioTecnico relatorio) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                relatorio.title ?? relatorio.farmName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _StatusChip(status: relatorio.status),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
              onSelected: (value) async {
                if (value == 'edit') {
                  context.go('/consultoria/relatorios/${widget.relatorioId}/edit');
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1C1C1E),
                      title: const Text('Excluir relatório?',
                          style: TextStyle(color: Colors.white)),
                      content: const Text('Esta ação não pode ser desfeita.',
                          style: TextStyle(color: Color(0xFF8E8E93))),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Excluir',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(relatorioNotifierProvider.notifier)
                        .softDelete(widget.relatorioId);
                    if (mounted) context.go('/consultoria/relatorios');
                  }
                }
              },
              itemBuilder: (_) => [
                if (relatorio.status == RelatorioStatus.pendente_revisao)
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Excluir', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(RelatorioTecnico relatorio) {
    final formatter = DateFormat('dd/MM/yyyy');

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _InfoRow(label: 'Fazenda', value: relatorio.farmName),
            const Divider(height: 24),
            _InfoRow(
              label: 'Período',
              value:
                  '${formatter.format(relatorio.periodStart)} → ${formatter.format(relatorio.periodEnd)}',
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Talhões',
              value: '${relatorio.talhoes.length} visitados',
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Ocorrências',
              value: '${relatorio.ocorrencias.length} registradas',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard(RelatorioTecnico relatorio) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Editar relatório',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A56DB),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notas adicionais',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A56DB),
                    width: 2,
                  ),
                ),
              ),
            ),
            if (_isDirty) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _saveChanges(relatorio),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1A56DB)),
                  foregroundColor: const Color(0xFF1A56DB),
                ),
                child: const Text('Salvar alterações'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOcorrenciasCard(RelatorioTecnico relatorio) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ocorrências',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            ...relatorio.ocorrencias.map(
              (ocorrencia) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• ${ocorrencia.tipo}: ${ocorrencia.descricao}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalhoesCard(RelatorioTecnico relatorio) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Talhões visitados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            ...relatorio.talhoes.map(
              (talhao) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• ${talhao.nomeTalhao}${talhao.areaHectares != null ? ' (${talhao.areaHectares} ha)' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishButton(RelatorioTecnico relatorio) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: FilledButton(
          onPressed: _isPublishing ? null : () => _publishRelatorio(relatorio),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isPublishing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'PUBLICAR RELATÓRIO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // AÇÕES
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _saveChanges(RelatorioTecnico relatorio) async {
    HapticFeedback.mediumImpact();
    try {
      final repository = ref.read(relatorioRepositoryProvider);
      final updated = relatorio.copyWith(
        title: _titleController.text.trim(),
        customNotes: _notesController.text.trim(),
        updatedAt: DateTime.now().toUtc(),
      );

      await repository.update(updated);
      if (!mounted) return; // ← Guard obrigatório antes de usar ref
      ref.invalidate(relatorioDetailProvider(id: widget.relatorioId));

      setState(() => _isDirty = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alterações salvas com sucesso!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _publishRelatorio(RelatorioTecnico relatorio) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publicar relatório'),
        content: const Text(
          'O relatório será enviado ao produtor e ao agrônomo. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    HapticFeedback.mediumImpact();

    setState(() => _isPublishing = true);

    try {
      await ref.read(publishRelatorioProvider(relatorio.id).future);
      if (!mounted) return; // ← Guard obrigatório antes de usar ref
      ref.invalidate(relatorioDetailProvider(id: widget.relatorioId));

      if (mounted) {
        context.go('/consultoria/relatorios');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatório publicado com sucesso!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// COMPONENTES PRIVADOS
// ════════════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RelatorioStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config['label'] as String,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: config['fg'] as Color,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(RelatorioStatus status) {
    switch (status) {
      case RelatorioStatus.pendente_revisao:
        return {
          'bg': const Color(0xFFFFF3CD),
          'fg': const Color(0xFF92400E),
          'label': 'Pendente',
        };
      case RelatorioStatus.publicado:
        return {
          'bg': const Color(0xFFD1FAE5),
          'fg': const Color(0xFF065F46),
          'label': 'Publicado',
        };
      case RelatorioStatus.arquivado:
        return {
          'bg': const Color(0xFFF3F4F6),
          'fg': const Color(0xFF6B7280),
          'label': 'Arquivado',
        };
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ),
      ],
    );
  }
}
