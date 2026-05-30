import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../application/report_providers.dart';
import '../domain/entities/relatorio.dart';

// Ocorrências — mesmo bounded context (consultoria/)
import '../../occurrences/presentation/controllers/occurrence_controller.dart';
import '../../occurrences/presentation/widgets/occurrence_detail_sheet.dart';
// hide SyncStatus para evitar conflito com o enum de relatorio.dart
import '../../occurrences/domain/occurrence.dart' hide SyncStatus;

// Marketing Cases — cross-module (ADR-008)
// Entidade importada para tipagem segura — Fix B (elimina casts dynamic inseguros)
// Arch: consultoria→marketing permitido; bloqueio é consultoria→operacao
import '../../marketing/presentation/widgets/marketing_case_sheet.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';

/// Tela de Relatórios com três seções de dados reais do SQLite local:
///
/// 1. Relatórios de Visita  → [relatoriosListProvider]
/// 2. Ocorrências Registradas → [occurrencesListProvider]
/// 3. Marketing Cases         → [marketingCasesProvider]
///
/// Apenas leitura — nenhum dado é gravado aqui.
/// Fronteira respeitada: importa apenas providers de módulos externos.
class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // ── Seção 1: Relatórios de Visita ──────────────────────────
                  _RelatoriosSection(dateFormat: _dateFormat),
                  const SizedBox(height: 20),

                  // ── Seção 2: Ocorrências Registradas ───────────────────────
                  _OccurrenciasSection(dateFormat: _dateFormat),
                  const SizedBox(height: 20),

                  // ── Seção 3: Marketing Cases ───────────────────────────────
                  _MarketingCasesSection(dateFormat: _dateFormat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Relatórios',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEÇÃO 1 — Relatórios de Visita
// ══════════════════════════════════════════════════════════════════════════════

class _RelatoriosSection extends ConsumerWidget {
  final DateFormat dateFormat;
  const _RelatoriosSection({required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatoriosAsync = ref.watch(relatoriosListProvider);

    return relatoriosAsync.when(
      data: (list) => _SectionContainer(
        title: 'Relatórios de Visita',
        count: list.length,
        emptyMessage: 'Nenhum relatório gerado ainda.',
        isEmpty: list.isEmpty,
        child: Column(
          children: list
              .map((r) => _RelatorioCard(relatorio: r, dateFormat: dateFormat))
              .toList(),
        ),
      ),
      loading: () => const _SectionLoading(title: 'Relatórios de Visita'),
      error: (e, stack) {
        debugPrint('[RelatoriosScreen] relatoriosListProvider ERROR: $e\n$stack');
        return _SectionError(
          title: 'Relatórios de Visita',
          onRetry: () => ref.refresh(relatoriosListProvider),
        );
      },
    );
  }
}

class _RelatorioCard extends StatelessWidget {
  final Relatorio relatorio;
  final DateFormat dateFormat;

  const _RelatorioCard({required this.relatorio, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _syncStatusLabel(relatorio.syncStatus);
    final statusColor = _syncStatusColor(relatorio.syncStatus);

    return InkWell(
      onTap: () => context.go('/consultoria/relatorios/${relatorio.id}'),
      borderRadius: BorderRadius.circular(12),
      child: _DataCard(
        leading: const Icon(Icons.description_outlined, size: 20),
        title: relatorio.titulo,
        subtitle: relatorio.descricao.isNotEmpty ? relatorio.descricao : null,
        date: dateFormat.format(relatorio.createdAt.toLocal()),
        statusLabel: statusLabel,
        statusColor: statusColor,
      ),
    );
  }

  String _syncStatusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.local_only:
        return 'Local';
      case SyncStatus.pending_sync:
        return 'Pendente';
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.sync_error:
        return 'Erro sync';
      case SyncStatus.deleted_local:
        return 'Removido';
    }
  }

  Color _syncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return const Color(0xFF34C759);
      case SyncStatus.pending_sync:
        return const Color(0xFFFF9500);
      case SyncStatus.sync_error:
        return const Color(0xFFFF3B30);
      default:
        return Colors.grey;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEÇÃO 2 — Ocorrências Registradas
// ══════════════════════════════════════════════════════════════════════════════

class _OccurrenciasSection extends ConsumerWidget {
  final DateFormat dateFormat;
  const _OccurrenciasSection({required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occAsync = ref.watch(occurrencesListProvider);

    return occAsync.when(
      data: (list) => _SectionContainer(
        title: 'Ocorrências Registradas',
        count: list.length,
        emptyMessage: 'Nenhuma ocorrência registrada.',
        isEmpty: list.isEmpty,
        child: Column(
          children: list
              .map((o) => _OccurrenciaCard(occurrence: o, dateFormat: dateFormat))
              .toList(),
        ),
      ),
      loading: () => const _SectionLoading(title: 'Ocorrências Registradas'),
      error: (e, stack) {
        debugPrint('[RelatoriosScreen] occurrencesListProvider ERROR: $e\n$stack');
        return _SectionError(
          title: 'Ocorrências Registradas',
          onRetry: () => ref.refresh(occurrencesListProvider),
        );
      },
    );
  }
}

class _OccurrenciaCard extends StatelessWidget {
  final Occurrence occurrence;
  final DateFormat dateFormat;

  const _OccurrenciaCard({required this.occurrence, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _occStatusLabel(occurrence.status);
    final statusColor = _occStatusColor(occurrence.status);
    final categoryLabel = occurrence.category ?? occurrence.type;

    return InkWell(
      onTap: () => OccurrenceDetailSheet.show(context, occurrence),
      borderRadius: BorderRadius.circular(12),
      child: _DataCard(
        leading: const Icon(Icons.warning_amber_rounded, size: 20),
        title: occurrence.type,
        subtitle: categoryLabel != occurrence.type ? categoryLabel : null,
        date: dateFormat.format(occurrence.createdAt.toLocal()),
        statusLabel: statusLabel,
        statusColor: statusColor,
      ),
    );
  }

  String _occStatusLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'draft':
      default:
        return 'Rascunho';
    }
  }

  Color _occStatusColor(String? status) {
    return status == 'confirmed'
        ? const Color(0xFF34C759)
        : const Color(0xFFFF9500);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEÇÃO 3 — Marketing Cases
// ══════════════════════════════════════════════════════════════════════════════

class _MarketingCasesSection extends ConsumerWidget {
  final DateFormat dateFormat;
  const _MarketingCasesSection({required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fix F — Protege contra StateError síncrono do Supabase.instance.client
    // durante a criação do StateNotifierProvider (race condition no cold start).
    // Sem este try-catch, a exception escapa do build() e quebra a árvore de
    // widgets inteira → tela cinza. O when(error:) NÃO captura erros de
    // criação do provider — apenas erros dentro do notifier.
    late final AsyncValue<List<MarketingCase>> casesAsync;
    try {
      casesAsync = ref.watch(marketingCasesProvider);
    } catch (e, st) {
      debugPrint('[RelatoriosScreen] marketingCasesProvider falhou na criação: $e\n$st');
      return _SectionError(
        title: 'Marketing Cases',
        onRetry: () => ref.invalidate(marketingCasesProvider),
      );
    }

    return casesAsync.when(
      data: (list) {
        // Exclui deletados logicamente
        final visible = list.where((c) => c.deletadoEm == null).toList();
        return _SectionContainer(
          title: 'Marketing Cases',
          count: visible.length,
          emptyMessage: 'Nenhum case publicado.',
          isEmpty: visible.isEmpty,
          child: Column(
            children: visible
                .map((c) => _MarketingCaseCard(marketingCase: c, dateFormat: dateFormat))
                .toList(),
          ),
        );
      },
      loading: () => const _SectionLoading(title: 'Marketing Cases'),
      error: (e, _) => _SectionError(
        title: 'Marketing Cases',
        onRetry: () => ref.refresh(marketingCasesProvider),
      ),
    );
  }
}

class _MarketingCaseCard extends StatelessWidget {
  // Fix B — Tipagem forte substitui dynamic.
  // Elimina casts inseguros (as String / as DateTime) que escapavam
  // do when(error:) quando lançavam TypeError dentro do data() callback.
  final MarketingCase marketingCase;
  final DateFormat dateFormat;

  const _MarketingCaseCard({required this.marketingCase, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _caseStatusLabel(marketingCase.status.toValue());
    final statusColor = _caseStatusColor(marketingCase.status.toValue());

    return InkWell(
      onTap: () => MarketingCaseSheet.show(context, marketingCase),
      borderRadius: BorderRadius.circular(12),
      child: _DataCard(
        leading: const Icon(Icons.star_outline_rounded, size: 20),
        title: marketingCase.produtorFazenda,
        subtitle: marketingCase.tipo.toValue(),
        date: dateFormat.format(marketingCase.criadoEm.toLocal()),
        statusLabel: statusLabel,
        statusColor: statusColor,
      ),
    );
  }

  String _caseStatusLabel(String status) {
    switch (status) {
      case 'published':
        return 'Publicado';
      case 'draft':
        return 'Rascunho';
      case 'pending_sync':
        return 'Pendente';
      case 'archived':
        return 'Arquivado';
      default:
        return status;
    }
  }

  Color _caseStatusColor(String status) {
    switch (status) {
      case 'published':
        return const Color(0xFF34C759);
      case 'draft':
      case 'pending_sync':
        return const Color(0xFFFF9500);
      default:
        return Colors.grey;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES COMPARTILHADOS
// ══════════════════════════════════════════════════════════════════════════════

/// Container de seção com cabeçalho (título + contador) e corpo.
class _SectionContainer extends StatelessWidget {
  final String title;
  final int count;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;

  const _SectionContainer({
    required this.title,
    required this.count,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da seção
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        // Conteúdo ou estado vazio
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                emptyMessage,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          child,
      ],
    );
  }
}

/// Card genérico de item de dados.
class _DataCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final String date;
  final String statusLabel;
  final Color statusColor;

  const _DataCard({
    required this.leading,
    required this.title,
    this.subtitle,
    required this.date,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 10),
            child: IconTheme(
              data: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
              child: leading,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de loading de seção.
class _SectionLoading extends StatelessWidget {
  final String title;
  const _SectionLoading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ],
    );
  }
}

/// Estado de erro de seção com botão de retry.
class _SectionError extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;
  const _SectionError({required this.title, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Color(0xFFFF3B30)),
              const SizedBox(width: 6),
              Text(
                'Erro ao carregar dados',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: const Color(0xFFFF3B30),
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      ],
    );
  }
}
