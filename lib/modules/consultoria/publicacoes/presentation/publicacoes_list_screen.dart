import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'dart:ui' as ui;
import '../models/publicacao_tecnica.dart';
import '../models/publicacao_tema.dart';
import '../providers/publicacao_providers.dart';
import '../../../../core/constants/layout_constants.dart';

/// Tela de Listagem de Publicações Públicas — PASSO 4
///
/// Rota: [AppRoutes.publicacoes] (/consultoria/publicacoes) — L1
///
/// Exibe publicações públicas com filtro por tema.
/// Navegação: sem AppBar. SmartButton global cuida do retorno ao mapa.
class PublicacoesListScreen extends ConsumerStatefulWidget {
  const PublicacoesListScreen({super.key});

  @override
  ConsumerState<PublicacoesListScreen> createState() =>
      _PublicacoesListScreenState();
}

class _PublicacoesListScreenState extends ConsumerState<PublicacoesListScreen> {
  PublicacaoTema? _selectedTema;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTokens.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: PremiumTokens.backgroundLight.withValues(alpha: 0.8),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                'Publicações',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: PremiumTokens.textPrimaryLight,
                    ),
              ),
              background: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(SFIcons.add, color: PremiumTokens.brandGreen, size: 28),
                onPressed: () => context.go('/consultoria/publicacoes/nova'),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Column(
                children: [
                   _buildFilterChips(),
                   const Divider(height: 1, color: PremiumTokens.hairlineLight),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: kFabSafeArea),
            sliver: _buildListSliver(),
          ),
        ],
      ),
    );
  }



  Widget _buildFilterChips() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          _FilterChip(
            label: 'Todos',
            selected: _selectedTema == null,
            onTap: () => setState(() => _selectedTema = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pragas',
            selected: _selectedTema == PublicacaoTema.praga,
            onTap: () => setState(() => _selectedTema = PublicacaoTema.praga),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Doenças',
            selected: _selectedTema == PublicacaoTema.doenca,
            onTap: () => setState(() => _selectedTema = PublicacaoTema.doenca),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Solo',
            selected: _selectedTema == PublicacaoTema.solo,
            onTap: () => setState(() => _selectedTema = PublicacaoTema.solo),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Fenologia',
            selected: _selectedTema == PublicacaoTema.fenologia,
            onTap: () =>
                setState(() => _selectedTema = PublicacaoTema.fenologia),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Recomendação',
            selected: _selectedTema == PublicacaoTema.recomendacao,
            onTap: () =>
                setState(() => _selectedTema = PublicacaoTema.recomendacao),
          ),
        ],
      ),
    );
  }

  Widget _buildListSliver() {
    final async = ref.watch(publicacoesListProvider(tema: _selectedTema));

    return async.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: PremiumTokens.brandGreen),
        ),
      ),
      error: (error, _) => SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erro ao carregar publicações:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: PremiumTokens.textSecondaryLight),
            ),
          ),
        ),
      ),
      data: (publicacoes) {
        if (publicacoes.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Nenhuma publicação encontrada.',
                style: TextStyle(color: PremiumTokens.textTertiaryLight),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _PublicacaoCard(publicacao: publicacoes[index]);
              },
              childCount: publicacoes.length,
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// COMPONENTES PRIVADOS
// ════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PremiumTokens.brandGreen : PremiumTokens.surfaceLight,
          border: Border.all(
            color: selected ? PremiumTokens.brandGreen : PremiumTokens.hairlineLight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : PremiumTokens.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}

class _PublicacaoCard extends StatelessWidget {
  const _PublicacaoCard({required this.publicacao});

  final PublicacaoTecnica publicacao;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/consultoria/publicacoes/${publicacao.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PremiumTokens.surfaceLight,
          borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
          boxShadow: PremiumTokens.tightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TemaBadge(tema: publicacao.tema),
                Text(
                  DateFormat('dd/MM/yyyy').format(publicacao.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              publicacao.titulo,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              publicacao.conteudo,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (publicacao.safra != null) ...[
              const SizedBox(height: 8),
              Text(
                'Safra ${publicacao.safra}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TemaBadge extends StatelessWidget {
  const _TemaBadge({required this.tema});

  final PublicacaoTema tema;

  @override
  Widget build(BuildContext context) {
    final color = _getTemaColor(tema);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _getTemaLabel(tema),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getTemaColor(PublicacaoTema tema) {
    switch (tema) {
      case PublicacaoTema.praga:
        return const Color(0xFFDC2626);
      case PublicacaoTema.doenca:
        return const Color(0xFF7C3AED);
      case PublicacaoTema.solo:
        return const Color(0xFF92400E);
      case PublicacaoTema.fenologia:
        return const Color(0xFF059669);
      case PublicacaoTema.recomendacao:
        return const Color(0xFF1A56DB);
      case PublicacaoTema.outro:
        return const Color(0xFF6B7280);
    }
  }

  String _getTemaLabel(PublicacaoTema tema) {
    switch (tema) {
      case PublicacaoTema.praga:
        return 'Praga';
      case PublicacaoTema.doenca:
        return 'Doença';
      case PublicacaoTema.solo:
        return 'Solo';
      case PublicacaoTema.fenologia:
        return 'Fenologia';
      case PublicacaoTema.recomendacao:
        return 'Recomendação';
      case PublicacaoTema.outro:
        return 'Outro';
    }
  }
}
