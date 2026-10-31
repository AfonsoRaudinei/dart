// ADR-012 — planos/presentation/screens/meu_plano_screen.dart
//
// Rota: /planos/meu-plano — exibe info do plano ativo com dias restantes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../providers/plano_providers.dart';
import '../../domain/entities/user_plan.dart';
import '../../domain/enums/plano_tipo.dart';

class MeuPlanoScreen extends ConsumerWidget {
  const MeuPlanoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planoAsync = ref.watch(planoAtivoProvider);

    return Scaffold(
      backgroundColor: context.premiumBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: planoAsync.when(
                data: (plano) => _PlanoAtivoContent(plano: plano),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                error: (e, _) => _ErrorContent(error: e.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Text(
            'Meu Plano',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.premiumTextPrimary,
              letterSpacing: 0.37,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTEÚDO: PLANO ATIVO
// ─────────────────────────────────────────────────────────────

class _PlanoAtivoContent extends ConsumerWidget {
  final UserPlan plano;

  const _PlanoAtivoContent({required this.plano});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dias = plano.diasRestantes;
    final expiraEmBreve = plano.expiraEmBreve;
    final codigoAsync = ref.watch(meuCodigoIndicacaoProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 16),
        // Badge principal
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.premiumSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.premiumHairline),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Plano ${plano.plano.label}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.premiumTextPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'via ${plano.origem.label}',
                style: TextStyle(
                  fontSize: 14,
                  color: context.premiumTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Dias restantes
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.premiumSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: expiraEmBreve
                  ? Colors.red.withAlpha(120)
                  : context.premiumHairline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                expiraEmBreve
                    ? Icons.warning_amber_rounded
                    : Icons.calendar_today_rounded,
                color: expiraEmBreve ? Colors.red : primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plano.isIndefinite
                        ? 'Sem expiração'
                        : expiraEmBreve
                        ? '⚠️ Expira em $dias dias'
                        : plano.diasRestantesLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: expiraEmBreve
                          ? Colors.red
                          : context.premiumTextPrimary,
                    ),
                  ),
                  if (!plano.isIndefinite)
                    Text(
                      'Expira em ${_formatDate(plano.expiraEm)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.premiumTextSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Info de limite
        _InfoRow(
          icon: Icons.location_on_rounded,
          label: 'Cases ativos no mapa',
          value: '${plano.limiteCases} case${plano.limiteCases > 1 ? 's' : ''}',
        ),
        if (plano.plano != PlanoTipo.ouro) ...[
          const SizedBox(height: 16),
          _NavigationRow(
            icon: Icons.group_add_outlined,
            label: 'Indicações',
            value: _buildIndicacaoSubtitle(
              plano,
              codigoAsync.asData?.value?.indicacoesValidadas ?? 0,
            ),
            route: AppRoutes.planosIndicacoes,
          ),
        ],
        const SizedBox(height: 32),
        const SizedBox(height: kFabSafeArea),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _buildIndicacaoSubtitle(UserPlan plano, int indicacoesValidadas) {
    switch (plano.plano) {
      case PlanoTipo.bronze:
        return '$indicacoesValidadas/5 para Prata';
      case PlanoTipo.prata:
        return '$indicacoesValidadas/10 para Ouro';
      case PlanoTipo.ouro:
        return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// CONTEÚDO: SEM PLANO
// ─────────────────────────────────────────────────────────────
// CONTEÚDO: ERRO
// ─────────────────────────────────────────────────────────────

class _ErrorContent extends StatelessWidget {
  final String error;

  const _ErrorContent({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Erro ao carregar plano: $error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontFamily: 'Inter'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET auxiliar: Info Row
// ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.premiumHairline),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: context.premiumTextPrimary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.premiumTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String route;

  const _NavigationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: context.premiumSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.premiumHairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          context.go(route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.premiumTextPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.premiumTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: context.premiumTextSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
