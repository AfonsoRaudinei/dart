import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';

/// Botão de acesso ao SoloForte exibido na tela de mapa público.
///
/// Localizado na parte inferior central da tela, permite que usuários
/// não autenticados acessem a tela de login.
///
/// **Design:**
/// - Texto "Acessar SoloForte" com S e F destacados
/// - Chevron verde à direita
/// - Fundo branco com sombra dupla pronunciada
/// - Ação: Navega para `/login`
class AccessSoloForteButton extends StatelessWidget {
  const AccessSoloForteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Acessar SoloForte - Fazer login ou criar conta',
      button: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => context.go(AppRoutes.login),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Texto principal com S e F destacados
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        letterSpacing: 0.1,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Acessar ',
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: 'S',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).primaryColor,
                            fontSize: 19,
                          ),
                        ),
                        const TextSpan(text: 'olo'),
                        TextSpan(
                          text: 'F',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).primaryColor,
                            fontSize: 19,
                          ),
                        ),
                        const TextSpan(text: 'orte'),
                      ],
                    ),
                  ),
                  // Chevron com fundo verde
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
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
