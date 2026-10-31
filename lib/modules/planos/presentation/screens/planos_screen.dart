// ADR-012 — planos/presentation/screens/planos_screen.dart
//
// Rota: /planos — status do plano (sem checkout; decisão C).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../providers/plano_providers.dart';

class PlanosScreen extends StatelessWidget {
  const PlanosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.premiumBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Planos SoloForte',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.premiumTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Plano SoloForte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: context.premiumTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Status da assinatura',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Assinaturas pagas estão temporariamente indisponíveis neste app. '
                'Seu plano gratuito e indicações continuam valendo na conta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: context.premiumTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final planoAsync = ref.watch(planoAtivoProvider);
                  final plano = planoAsync.valueOrNull;
                  if (plano != null && plano.ativo) {
                    final planoNome =
                        plano.plano.name[0].toUpperCase() +
                        plano.plano.name.substring(1);
                    return Text(
                      'Plano atual: $planoNome · ${plano.diasRestantesLabel} · '
                      'até ${plano.limiteCases} cases no mapa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.premiumTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go(AppRoutes.map);
                },
                child: Text(
                  'Voltar ao mapa',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: kFabSafeArea),
            ],
          ),
        ),
      ),
    );
  }
}
