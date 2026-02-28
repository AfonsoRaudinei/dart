import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/router/app_routes.dart';

import '../../models/relatorio_status.dart';
import '../../models/relatorio_tecnico.dart';
import '../providers/relatorio_query_providers.dart';

/// Tela de Listagem de Relatórios Técnicos — ADR-009
///
/// Rota: [AppRoutes.reports] (/consultoria/relatorios) — L1
///
/// Exibe os relatórios do agrônomo autenticado com filtros:
///   - "Meus" → [RelatorioStatus.pendente_revisao]
///   - "Compartilhados" → [RelatorioStatus.publicado]
///
/// Navegação: sem AppBar nativa. SmartButton global cuida do retorno ao mapa.
class RelatorioListPage extends ConsumerStatefulWidget {
  const RelatorioListPage({super.key});

  @override
  ConsumerState<RelatorioListPage> createState() => _RelatorioListPageState();
}

class _RelatorioListPageState extends ConsumerState<RelatorioListPage> {
  RelatorioStatus? _activeFilter = RelatorioStatus.pendente_revisao;

  static const _dateFormat = 'dd/MM/yyyy';

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final reportsAsync = ref.watch(
      relatoriosByAgronomistProvider(userId, status: _activeFilter),
    );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilterRow(),
          const SizedBox(height: 8.0),
          Expanded(child: _buildBody(reportsAsync)),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        8.0,
      ),
      child: Text('Relatórios', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  // ── Filtros ───────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        children: [
          _FilterChip(
            label: 'Meus',
            selected: _activeFilter == RelatorioStatus.pendente_revisao,
            onSelected: (_) => setState(
              () => _activeFilter = RelatorioStatus.pendente_revisao,
            ),
          ),
          _FilterChip(
            label: 'Compartilhados',
            selected: _activeFilter == RelatorioStatus.publicado,
            onSelected: (_) =>
                setState(() => _activeFilter = RelatorioStatus.publicado),
          ),
          _FilterChip(
            label: 'Todos',
            selected: _activeFilter == null,
            onSelected: (_) => setState(() => _activeFilter = null),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────

  Widget _buildBody(AsyncValue<List<RelatorioTecnico>> async) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: 'Erro ao carregar relatórios:\n$error',
        onRetry: () => ref.invalidate(relatoriosByAgronomistProvider),
      ),
      data: (relatorios) => relatorios.isEmpty
          ? _EmptyState(filter: _activeFilter)
          : ListView.builder(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 80, // espaço para SmartButton global
              ),
              itemCount: relatorios.length,
              itemBuilder: (_, i) => _RelatorioCard(
                relatorio: relatorios[i],
                dateFormat: _dateFormat,
              ),
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COMPONENTES PRIVADOS
// ════════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: PremiumTokens.brandGreen.withValues(alpha: 0.15),
      checkmarkColor: PremiumTokens.brandGreen,
      labelStyle: TextStyle(
        color: selected
            ? PremiumTokens.brandGreen
            : PremiumTokens.textSecondaryLight,
        fontWeight: selected
            ? FontWeight.w500
            : FontWeight.w400,
        fontSize: 10.0,
      ),
    );
  }
}

class _RelatorioCard extends StatelessWidget {
  const _RelatorioCard({required this.relatorio, required this.dateFormat});

  final RelatorioTecnico relatorio;
  final String dateFormat;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat(dateFormat);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () => context.go(AppRoutes.reportDetail(relatorio.id)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + badge sync
              Row(
                children: [
                  Expanded(
                    child: Text(
                      relatorio.title?.isNotEmpty == true
                          ? relatorio.title!
                          : relatorio.farmName,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (relatorio.syncStatus == RelatorioSyncStatus.local_only)
                    const _OfflineBadge(),
                ],
              ),
              const SizedBox(height: 4),

              // Fazenda (se título customizado)
              if (relatorio.title?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    relatorio.farmName,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Período
              Text(
                '${fmt.format(relatorio.periodStart)} → ${fmt.format(relatorio.periodEnd)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8.0),

              // Badge de status
              _StatusBadge(status: relatorio.status),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 10,
            color: const Color(0xFF92400E),
          ),
          const SizedBox(width: 3),
          Text(
            'Offline',
            style: const TextStyle(fontSize: 11, color: Colors.grey).copyWith(
              color: const Color(0xFF92400E),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final RelatorioStatus? filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      RelatorioStatus.pendente_revisao =>
        'Nenhum relatório pendente de revisão.\n'
            'Relatórios são gerados automaticamente ao finalizar uma visita.',
      RelatorioStatus.publicado => 'Nenhum relatório publicado ainda.',
      _ => 'Nenhum relatório encontrado.',
    };

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
              message,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: PremiumTokens.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: const Color(0xFFFF3B30)),
            const SizedBox(height: 16.0),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: PremiumTokens.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTokens.brandGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
