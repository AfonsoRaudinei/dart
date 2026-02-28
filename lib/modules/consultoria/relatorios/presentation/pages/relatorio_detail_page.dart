import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/router/app_routes.dart';

import '../../models/relatorio_status.dart';
import '../../models/relatorio_tecnico.dart';
import '../../models/visit_session_snapshot.dart';
import '../../use_cases/publish_relatorio_use_case.dart';
import '../providers/relatorio_query_providers.dart';

/// Tela de Detalhe do Relatório Técnico — ADR-009
///
/// Rota: [AppRoutes.reportDetail(id)] (/consultoria/relatorios/:id) — L2+
///
/// Comportamento por status:
///   - [pendente_revisao]: campos editáveis de título/notas + botão PUBLICAR
///   - [publicado] / [arquivado]: somente leitura
///
/// Navegação: sem AppBar nativa. SmartButton global cuida do retorno ao mapa.
class RelatorioDetailPage extends ConsumerStatefulWidget {
  const RelatorioDetailPage({super.key, required this.relatorioId});

  final String relatorioId;

  @override
  ConsumerState<RelatorioDetailPage> createState() =>
      _RelatorioDetailPageState();
}

class _RelatorioDetailPageState extends ConsumerState<RelatorioDetailPage> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _fieldsSynced = false;
  bool _isPublishing = false;

  static const _dateFormat = 'dd/MM/yyyy';

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Sincroniza controladores de texto com os dados do relatório (apenas 1×).
  void _syncFields(RelatorioTecnico relatorio) {
    if (_fieldsSynced) return;
    _titleController.text = relatorio.title ?? '';
    _notesController.text = relatorio.customNotes ?? '';
    _fieldsSynced = true;
  }

  // ── Ação Publicar ─────────────────────────────────────────────────────

  Future<void> _publish(RelatorioTecnico relatorio) async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    try {
      await ref.read(publishRelatorioProvider(relatorio.id).future);
      // Invalida o cache para refletir o novo status
      ref.invalidate(relatorioByIdProvider(widget.relatorioId));
      ref.invalidate(relatoriosByAgronomistProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Relatório publicado com sucesso!'),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(relatorioByIdProvider(widget.relatorioId));

    return SafeArea(
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: const Color(0xFFFF3B30),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Erro ao carregar relatório:\n$err',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: PremiumTokens.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.reports),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar à lista'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTokens.brandGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (relatorio) {
          if (relatorio == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 56,
                      color: PremiumTokens.textTertiaryLight,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Relatório não encontrado.',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: PremiumTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          _syncFields(relatorio);
          return _buildContent(relatorio);
        },
      ),
    );
  }

  Widget _buildContent(RelatorioTecnico relatorio) {
    final fmt = DateFormat(_dateFormat);
    final isPendente = relatorio.status == RelatorioStatus.pendente_revisao;

    return CustomScrollView(
      slivers: [
        // ── Header ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16.0,
              16.0,
              16.0,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(relatorio.farmName, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${fmt.format(relatorio.periodStart)} → ${fmt.format(relatorio.periodEnd)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    _StatusBadge(status: relatorio.status),
                    if (relatorio.syncStatus ==
                        RelatorioSyncStatus.local_only) ...[
                      const SizedBox(width: 6),
                      const _OfflineBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Campos editáveis (somente se pendente) ───────────────────
        if (isPendente)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16.0,
                20.0,
                16.0,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revisão',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Título (opcional)',
                      hintText:
                          'Ex.: Relatório de Monitoramento — Fazenda Bela Vista',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notas adicionais (opcional)',
                      hintText: 'Observações do agrônomo...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),

        // ── Seção: Ocorrências ───────────────────────────────────────
        if (relatorio.ocorrencias.isNotEmpty)
          _SliverSection(
            title: 'Ocorrências (${relatorio.ocorrencias.length})',
            child: Column(
              children: relatorio.ocorrencias
                  .map((o) => _OcorrenciaRow(o))
                  .toList(),
            ),
          ),

        // ── Seção: Talhões ───────────────────────────────────────────
        if (relatorio.talhoes.isNotEmpty)
          _SliverSection(
            title: 'Talhões Visitados (${relatorio.talhoes.length})',
            child: Column(
              children: relatorio.talhoes.map((t) => _TalhaoRow(t)).toList(),
            ),
          ),

        // ── Seção: Fotos ─────────────────────────────────────────────
        if (relatorio.fotos.isNotEmpty)
          _SliverSection(
            title: 'Fotos (${relatorio.fotos.length})',
            child: _FotoGrid(fotos: relatorio.fotos),
          ),

        // ── Botão Publicar ───────────────────────────────────────────
        if (isPendente)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16.0,
                20.0,
                16.0,
                24.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPublishing ? null : () => _publish(relatorio),
                  icon: _isPublishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.publish_rounded),
                  label: Text(
                    _isPublishing ? 'Publicando...' : 'PUBLICAR RELATÓRIO',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTokens.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    disabledBackgroundColor: PremiumTokens.brandGreen.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Espaço para SmartButton global
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COMPONENTES PRIVADOS
// ════════════════════════════════════════════════════════════════════════════

/// Seção colapsável com título + conteúdo.
class _SliverSection extends StatelessWidget {
  const _SliverSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16.0,
          20.0,
          16.0,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                color: PremiumTokens.backgroundLight,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _OcorrenciaRow extends StatelessWidget {
  const _OcorrenciaRow(this.ocorrencia);
  final OcorrenciaSnapshot ocorrencia;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bug_report_outlined, size: 20),
      title: Text(ocorrencia.tipo, style: Theme.of(context).textTheme.bodyMedium!),
      subtitle: Text(ocorrencia.descricao, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      dense: true,
    );
  }
}

class _TalhaoRow extends StatelessWidget {
  const _TalhaoRow(this.talhao);
  final TalhaoVisitado talhao;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.crop_square_outlined, size: 20),
      title: Text(talhao.nomeTalhao, style: Theme.of(context).textTheme.bodyMedium!),
      dense: true,
    );
  }
}

class _FotoGrid extends StatelessWidget {
  const _FotoGrid({required this.fotos});
  final List<String> fotos;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: fotos.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(6.0),
        child: Image.asset(
          fotos[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: PremiumTokens.backgroundLight,
            child: Icon(
              Icons.broken_image_outlined,
              color: PremiumTokens.textTertiaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final RelatorioStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      RelatorioStatus.pendente_revisao => (
        'Pendente Revisão',
        const Color(0xFFFFF3CD),
        const Color(0xFF92400E),
      ),
      RelatorioStatus.publicado => (
        'Publicado',
        const Color(0xFFD1FAE5),
        const Color(0xFF065F46),
      ),
      RelatorioStatus.arquivado => (
        'Arquivado',
        PremiumTokens.backgroundLight,
        PremiumTokens.textSecondaryLight,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.grey).copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 11,
            color: const Color(0xFF92400E),
          ),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: const TextStyle(fontSize: 11, color: Colors.grey).copyWith(
              color: const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}
