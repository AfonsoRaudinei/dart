import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../../../core/router/app_routes.dart';

/// CTA de acesso ao SoloForte na tela de mapa público.
///
/// Botão em pílula, largura total com margens: ação clara ("Entrar ou criar
/// conta") em vez de um banner de logo. Toque navega para `/login`.
class AccessSoloForteButton extends StatelessWidget {
  /// Versão enxuta para dividir a linha com o logo (economiza altura do mapa).
  final bool compact;

  const AccessSoloForteButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Acessar SoloForte - Fazer login ou criar conta',
      button: true,
      child: Padding(
        padding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 24 : 28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(compact ? 24 : 28),
            child: InkWell(
              onTap: () => context.go(AppRoutes.login),
              borderRadius: BorderRadius.circular(compact ? 24 : 28),
              child: SizedBox(
                height: compact ? 48 : 56,
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Entrar ou criar conta',
                            style: TextStyle(
                              fontSize: compact ? 14.5 : 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: PremiumTokens.brandGreenAccessible,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: compact ? 18 : 20,
                            color: PremiumTokens.brandGreenAccessible,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
