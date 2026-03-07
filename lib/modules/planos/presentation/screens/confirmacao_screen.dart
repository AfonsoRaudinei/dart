// ADR-012 — planos/presentation/screens/confirmacao_screen.dart
//
// Rota: /planos/confirmacao
// Exibida após o pagamento ser iniciado. Aguarda Supabase Realtime confirmar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';

import '../providers/plano_providers.dart';

class ConfirmacaoScreen extends ConsumerStatefulWidget {
  final String plano;
  final String? checkoutUrl;

  const ConfirmacaoScreen({super.key, required this.plano, this.checkoutUrl});

  @override
  ConsumerState<ConfirmacaoScreen> createState() => _ConfirmacaoScreenState();
}

class _ConfirmacaoScreenState extends ConsumerState<ConfirmacaoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  bool _confirmado = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    // Observa Realtime para detectar plano ativado
    _observarPlano();

    // Se possui URL do checkout, lança automaticamente no browser externo
    if (widget.checkoutUrl != null && widget.checkoutUrl!.isNotEmpty) {
      _abrirCheckout(widget.checkoutUrl!);
    }
  }

  Future<void> _abrirCheckout(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Falha silenciosa ou logging
    }
  }

  void _observarPlano() {
    // Força re-fetch após 3s (tempo médio de processamento do webhook)
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      ref.invalidate(planoAtivoProvider);
      ref.read(planoAtivoProvider.future).then((plano) {
        // 🛡 LIFECYCLE GUARD: callback .then() executa de forma assíncrona
        // e pode chegar após o widget ter sido descartado.
        if (!mounted) return;
        if (plano != null) {
          setState(() => _confirmado = true);
          _controller.forward();
          HapticFeedback.heavyImpact();
          // Redireciona para meu-plano após 2s
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/planos/meu-plano');
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _confirmado ? _buildConfirmado() : _buildAguardando(),
          ),
        ),
      ),
    );
  }

  Widget _buildAguardando() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Color(0xFF32D74B)),
        const SizedBox(height: 32),
        const Text(
          'Aguardando confirmação do pagamento...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.checkoutUrl != null
              ? 'Complete o pagamento no browser e retorne aqui.'
              : 'O pagamento será processado em instantes.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go('/map');
          },
          child: const Text(
            'Verificar depois',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFF32D74B),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: kFabSafeArea),
      ],
    );
  }

  Widget _buildConfirmado() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF32D74B).withAlpha(30),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF32D74B),
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Plano ativado! 🎉',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seus cases já podem aparecer no mapa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.go('/planos/meu-plano');
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF32D74B),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Text(
                    'Ir para Meu Plano',
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
          const SizedBox(height: kFabSafeArea),
        ],
      ),
    );
  }
}
