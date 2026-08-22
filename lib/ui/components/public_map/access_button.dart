import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';

/// CTA de acesso ao SoloForte na tela de mapa público.
///
/// Banner inferior: imagem com tap navegando para `/login`.
class AccessSoloForteButton extends StatelessWidget {
  const AccessSoloForteButton({super.key});

  static const _bannerAsset =
      'assets/E351DC81-7916-4231-A063-9359D2AA64F3.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Acessar SoloForte - Fazer login ou criar conta',
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(AppRoutes.login),
            borderRadius: BorderRadius.circular(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 3,
                child: Image.asset(
                  _bannerAsset,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
