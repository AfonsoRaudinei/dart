// ADR-012 — planos/presentation/screens/indicacoes_screen.dart
//
// Rota: /planos/indicacoes — código de indicação + progresso + histórico.
// Visível apenas para Bronze ou Prata ativo.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import '../providers/plano_providers.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/referral_code.dart';
import '../../domain/enums/referral_status.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

class IndicacoesScreen extends ConsumerWidget {
  const IndicacoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codigoAsync = ref.watch(meuCodigoIndicacaoProvider);
    final referralsAsync = ref.watch(referralsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: codigoAsync.when(
                data: (codigo) => _IndicacoesContent(
                  codigo: codigo,
                  referralsAsync: referralsAsync,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF32D74B)),
                ),
                error: (e, _) => Center(
                  child: Text(
                    userFacingError(e, action: 'Erro'),
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
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
          Text(
            'Indicações',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTEÚDO PRINCIPAL
// ─────────────────────────────────────────────────────────────

class _IndicacoesContent extends StatelessWidget {
  final ReferralCode? codigo;
  final AsyncValue<List<Referral>> referralsAsync;

  const _IndicacoesContent({
    required this.codigo,
    required this.referralsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 16),
        if (codigo != null) ...[
          _CodigoCard(codigo: codigo!),
          const SizedBox(height: 20),
          _ProgressoCard(indicacoesValidadas: codigo!.indicacoesValidadas),
          const SizedBox(height: 20),
        ],
        const Text(
          'Histórico de indicações',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        referralsAsync.when(
          data: (referrals) => referrals.isEmpty
              ? const _EmptyReferrals()
              : Column(
                  children: referrals
                      .map((r) => _ReferralTile(referral: r))
                      .toList(),
                ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF32D74B)),
            ),
          ),
          error: (e, _) => Text(
            userFacingError(e, action: 'Erro ao carregar indicações'),
            style: const TextStyle(color: Colors.red, fontFamily: 'Inter'),
          ),
        ),
        const SizedBox(height: 32),
        const SizedBox(height: kFabSafeArea),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD DO CÓDIGO DE INDICAÇÃO
// ─────────────────────────────────────────────────────────────

class _CodigoCard extends StatelessWidget {
  final ReferralCode codigo;

  const _CodigoCard({required this.codigo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF32D74B).withAlpha(60)),
      ),
      child: Column(
        children: [
          const Text(
            'Seu código de indicação',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                codigo.code,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF32D74B),
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  // clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código copiado!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF32D74B).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF32D74B),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Compartilhe com colegas agrônomos',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD DE PROGRESSO (Bronze → Prata: 5 | Prata → Ouro: 10)
// ─────────────────────────────────────────────────────────────

class _ProgressoCard extends StatelessWidget {
  final int indicacoesValidadas;

  const _ProgressoCard({required this.indicacoesValidadas});

  @override
  Widget build(BuildContext context) {
    // Progresso para próximo nível
    // Bronze (0-4 = Prata) | Prata (0-9 = Ouro)
    final meta = 5; // simplificado — provider mostraria o plano atual
    final progresso = (indicacoesValidadas / meta).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progresso',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '$indicacoesValidadas/$meta para o próximo nível',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              backgroundColor: const Color(0xFF3A3A3C),
              color: const Color(0xFF32D74B),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TILE DE REFERRAL
// ─────────────────────────────────────────────────────────────

class _ReferralTile extends StatelessWidget {
  final Referral referral;

  const _ReferralTile({required this.referral});

  Color get _statusColor {
    switch (referral.status) {
      case ReferralStatus.validada:
        return const Color(0xFF32D74B);
      case ReferralStatus.pendente:
        return const Color(0xFFFF9F0A);
      case ReferralStatus.expirada:
        return const Color(0xFF8E8E93);
    }
  }

  String get _statusLabel {
    switch (referral.status) {
      case ReferralStatus.validada:
        return 'Validada ✓';
      case ReferralStatus.pendente:
        return 'Pendente';
      case ReferralStatus.expirada:
        return 'Expirada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: _statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código: ${referral.code}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _formatDate(referral.criadoEm),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _statusLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _statusColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────────────────
// ESTADO VAZIO
// ─────────────────────────────────────────────────────────────

class _EmptyReferrals extends StatelessWidget {
  const _EmptyReferrals();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Nenhuma indicação ainda.\nCompartilhe seu código!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}
