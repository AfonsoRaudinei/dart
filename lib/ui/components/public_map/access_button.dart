import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';

/// CTA de acesso ao SoloForte na tela de mapa público.
///
/// Wordmark compacto (máx. 220×56) com tap navegando para `/login`.
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220, maxHeight: 56),
            child: SizedBox(
              width: 220,
              height: 56,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go(AppRoutes.login),
                  borderRadius: BorderRadius.circular(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      _bannerAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      excludeFromSemantics: true,
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
