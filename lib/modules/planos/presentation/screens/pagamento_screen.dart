// ADR-012 — planos/presentation/screens/pagamento_screen.dart
//
// Rota: /planos/pagamento — seleção de método (PIX ou Cartão) e confirmação.
// Fluxo: chama MercadoPagoService → abre URL → aguarda webhook → Realtime atualiza.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import '../../data/services/mercadopago_service.dart';

class PagamentoScreen extends ConsumerStatefulWidget {
  final String plano; // 'bronze' | 'prata' | 'ouro'

  const PagamentoScreen({super.key, required this.plano});

  @override
  ConsumerState<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends ConsumerState<PagamentoScreen> {
  String _metodo = 'pix'; // 'pix' | 'cartao'
  bool _loading = false;
  String? _erro;

  String get _planoLabel {
    switch (widget.plano) {
      case 'bronze':
        return 'Bronze 🥉';
      case 'prata':
        return 'Prata 🥈';
      case 'ouro':
        return 'Ouro 🥇';
      default:
        return widget.plano;
    }
  }

  Future<void> _iniciarPagamento() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      HapticFeedback.mediumImpact();
      final service = MercadoPagoService(Supabase.instance.client);
      final checkoutUrl = await service.criarPreferenciaPagamento(
        plano: widget.plano,
        metodo: _metodo,
      );

      if (!mounted) return;
      // Navega para confirmação passando a URL de checkout
      context.go(
        AppRoutes.planosConfirmacao,
        extra: {'plano': widget.plano, 'checkoutUrl': checkoutUrl},
      );
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _loading = false;
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _buildIosUnavailable(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 16),
                  _PlanoBadge(label: _planoLabel),
                  const SizedBox(height: 24),
                  const Text(
                    'Escolha o método de pagamento',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MetodoTile(
                    titulo: 'PIX',
                    subtitulo: 'Aprovação instantânea',
                    icone: Icons.qr_code_rounded,
                    selecionado: _metodo == 'pix',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _metodo = 'pix');
                    },
                  ),
                  const SizedBox(height: 12),
                  _MetodoTile(
                    titulo: 'Cartão de Crédito/Débito',
                    subtitulo: 'Visa, Master, Elo e mais',
                    icone: Icons.credit_card_rounded,
                    selecionado: _metodo == 'cartao',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _metodo = 'cartao');
                    },
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _erro!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'Inter',
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF32D74B),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: GestureDetector(
                            onTap: _iniciarPagamento,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF32D74B),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Center(
                                child: Text(
                                  'Continuar para pagamento',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosUnavailable(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF32D74B),
                  size: 56,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pagamento indisponivel no iOS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Este app nao inicia compras externas no iOS. Se houver plano ativo na conta, ele sera aplicado automaticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.planos);
                  },
                  child: const Text(
                    'Voltar aos planos',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: Color(0xFF32D74B),
                    ),
                  ),
                ),
                const SizedBox(height: kFabSafeArea),
              ],
            ),
          ),
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
            'Pagamento',
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
// WIDGETS INTERNOS
// ─────────────────────────────────────────────────────────────

class _PlanoBadge extends StatelessWidget {
  final String label;
  const _PlanoBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF32D74B),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Plano $label',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetodoTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final bool selecionado;
  final VoidCallback onTap;

  const _MetodoTile({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0xFF32D74B).withAlpha(25)
              : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado
                ? const Color(0xFF32D74B)
                : const Color(0xFF3A3A3C),
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icone,
              color: selecionado
                  ? const Color(0xFF32D74B)
                  : const Color(0xFF8E8E93),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selecionado
                          ? Colors.white
                          : const Color(0xFFE5E5EA),
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            if (selecionado)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF32D74B),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
