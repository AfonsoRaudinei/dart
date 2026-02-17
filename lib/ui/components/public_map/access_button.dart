import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../theme/soloforte_theme.dart';

/// Botão de acesso ao SoloForte exibido na tela de mapa público.
///
/// Localizado na parte inferior central da tela, permite que usuários
/// não autenticados acessem a tela de login.
///
/// **Design:**
/// - Ícone do app à esquerda
/// - Texto "Acessar SoloForte" centralizado
/// - Fundo branco com sombra suave
/// - Ação: Navega para `/login`
class AccessSoloForteButton extends StatelessWidget {
  const AccessSoloForteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Acessar SoloForte - Fazer login ou criar conta',
      button: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SoloSpacing.lg,
          vertical: SoloSpacing.md,
        ),
        decoration: BoxDecoration(
          color: SoloForteColors.white,
          borderRadius: SoloRadius.radiusLg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(AppRoutes.login),
            borderRadius: SoloRadius.radiusLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SoloSpacing.md,
                vertical: SoloSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone do App - Maior e mais clean
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: SoloForteColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback se a imagem não carregar
                        return Container(
                          decoration: BoxDecoration(
                            color: SoloForteColors.greenIOS,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.agriculture,
                            color: Colors.white,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: SoloSpacing.lg),
                  // Texto
                  Text(
                    'Acessar SoloForte',
                    style: SoloTextStyles.headingMedium.copyWith(
                      fontSize: 17,
                      fontWeight: SoloFontWeights.semibold,
                      color: SoloForteColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: SoloSpacing.xs),
                  // Ícone de seta
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: SoloForteColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
