// ADR-012 — planos/presentation/screens/meu_plano_screen.dart
//
// Rota: /planos/meu-plano — exibe info do plano ativo com dias restantes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/plano_providers.dart';
import '../../domain/entities/user_plan.dart';
import '../../domain/enums/plano_tipo.dart';

class MeuPlanoScreen extends ConsumerWidget {
  const MeuPlanoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planoAsync = ref.watch(planoAtivoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: planoAsync.when(
                data: (plano) => plano != null
                    ? _PlanoAtivoContent(plano: plano)
                    : _SemPlanoContent(),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF32D74B)),
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
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/map');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF32D74B),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Meu Plano',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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

class _PlanoAtivoContent extends StatelessWidget {
  final UserPlan plano;

  const _PlanoAtivoContent({required this.plano});

  Color get _accentColor {
    switch (plano.plano) {
      case PlanoTipo.bronze:
        return const Color(0xFFCD7F32);
      case PlanoTipo.prata:
        return const Color(0xFFC0C0C0);
      case PlanoTipo.ouro:
        return const Color(0xFFFFD700);
    }
  }

  String get _emoji {
    switch (plano.plano) {
      case PlanoTipo.bronze:
        return '🥉';
      case PlanoTipo.prata:
        return '🥈';
      case PlanoTipo.ouro:
        return '🥇';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dias = plano.diasRestantes;
    final expiraEmBreve = plano.expiraEmBreve;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 16),
        // Badge principal
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _accentColor.withAlpha(80)),
          ),
          child: Column(
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Plano ${plano.plano.label}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'via ${plano.origem.label}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
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
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: expiraEmBreve
                ? Border.all(color: Colors.red.withAlpha(120))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                expiraEmBreve
                    ? Icons.warning_amber_rounded
                    : Icons.calendar_today_rounded,
                color: expiraEmBreve ? Colors.red : const Color(0xFF32D74B),
                size: 24,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expiraEmBreve
                        ? '⚠️ Expira em $dias dias'
                        : '$dias dias restantes',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: expiraEmBreve ? Colors.red : Colors.white,
                    ),
                  ),
                  Text(
                    'Expira em ${_formatDate(plano.expiraEm)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
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
        const SizedBox(height: 32),
        if (plano.plano != PlanoTipo.ouro)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/planos');
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF32D74B),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Text(
                    'Ver planos superiores',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────
// CONTEÚDO: SEM PLANO
// ─────────────────────────────────────────────────────────────

class _SemPlanoContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          const Text(
            'Você não possui um plano ativo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Assine um plano para publicar seus cases agronômicos no mapa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/planos');
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF32D74B),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Text(
                    'Ver planos',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF32D74B), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFFE5E5EA),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
