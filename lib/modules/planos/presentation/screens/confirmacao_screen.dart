// ADR-012 — planos/presentation/screens/confirmacao_screen.dart
//
// Rota: /planos/confirmacao — checkout oculto (decisão C).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

class ConfirmacaoScreen extends ConsumerWidget {
  final String plano;
  final String? checkoutUrl;

  const ConfirmacaoScreen({super.key, required this.plano, this.checkoutUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: context.premiumBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, color: primary, size: 56),
                const SizedBox(height: 24),
                Text(
                  'Confirmação indisponível',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.premiumTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'O fluxo de pagamento externo está desativado neste app. '
                  'Quando houver plano ativo na conta, ele será sincronizado automaticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: context.premiumTextSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.planos);
                  },
                  child: Text(
                    'Voltar aos planos',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: primary,
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
}
