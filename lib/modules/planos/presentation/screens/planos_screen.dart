// ADR-012 — planos/presentation/screens/planos_screen.dart
//
// Rota: /planos — lista os 3 planos (Bronze, Prata, Ouro) com CTA de compra.
// Design: Premium iOS (design_soloforte.md) — Glassmorphism + Verde Esmeralda

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import '../../domain/enums/plano_tipo.dart';

class PlanosScreen extends StatelessWidget {
  const PlanosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),
                  const _PlanCard(plano: PlanoTipo.bronze),
                  const SizedBox(height: 12),
                  const _PlanCard(plano: PlanoTipo.prata),
                  const SizedBox(height: 12),
                  const _PlanCard(plano: PlanoTipo.ouro),
                  const SizedBox(height: 32),
                  _buildIndication(context),
                  const SizedBox(height: 32),
                  const SizedBox(height: kFabSafeArea),
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          SizedBox(width: 40),
          Expanded(
            child: Text(
              'Planos SoloForte',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.37,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndication(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/planos/indicacoes');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF32D74B).withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF32D74B).withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: Color(0xFF32D74B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Indique e Ganhe',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '5 indicações → Prata · 10 indicações → Ouro',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD DE PLANO
// ─────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PlanoTipo plano;

  const _PlanCard({required this.plano});

  @override
  Widget build(BuildContext context) {
    final config = _PlanConfig.from(plano);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go('/planos/pagamento', extra: {'plano': plano.name});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: config.accentColor.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: config.accentColor.withAlpha(20),
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(config.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plano.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: config.accentColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        config.preco,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFAEAEB2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...config.beneficios.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: config.accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        b,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFE5E5EA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: config.accentColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      'Assinar ${plano.label}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONFIGURAÇÃO DE EXIBIÇÃO POR PLANO
// ─────────────────────────────────────────────────────────────

class _PlanConfig {
  final Color accentColor;
  final String emoji;
  final String preco;
  final List<String> beneficios;

  const _PlanConfig({
    required this.accentColor,
    required this.emoji,
    required this.preco,
    required this.beneficios,
  });

  factory _PlanConfig.from(PlanoTipo plano) {
    switch (plano) {
      case PlanoTipo.bronze:
        return const _PlanConfig(
          accentColor: Color(0xFFCD7F32),
          emoji: '🥉',
          preco: 'Ponto de entrada obrigatório',
          beneficios: [
            '1 case ativo no mapa',
            'Acesso ao sistema de indicações',
            'Suporte via chat',
          ],
        );
      case PlanoTipo.prata:
        return const _PlanConfig(
          accentColor: Color(0xFFC0C0C0),
          emoji: '🥈',
          preco: '5 indicações validadas',
          beneficios: [
            '2 cases ativos no mapa',
            'Tudo do Bronze',
            'Acesso prioritário a novas funcionalidades',
          ],
        );
      case PlanoTipo.ouro:
        return const _PlanConfig(
          accentColor: Color(0xFFFFD700),
          emoji: '🥇',
          preco: '10 indicações validadas',
          beneficios: [
            '3 cases ativos no mapa',
            'Cases visíveis sem login',
            'Tudo do Prata',
            'Badge Ouro no perfil',
          ],
        );
    }
  }
}
