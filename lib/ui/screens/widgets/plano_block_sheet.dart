import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

class PlanoBlockSheet extends StatelessWidget {
  final String motivo;
  final String? planoLabel;
  final int? limite;

  const PlanoBlockSheet({
    super.key,
    required this.motivo,
    this.planoLabel,
    this.limite,
  });

  static void show(
    BuildContext context, {
    required String motivo,
    String? planoLabel,
    int? limite,
  }) {
    HapticFeedback.heavyImpact();
    showSoloForteSheet(
      context: context,
      showDragHandle: false,
      builder: (ctx) => PlanoBlockSheet(
        motivo: motivo,
        planoLabel: planoLabel,
        limite: limite,
      ),
    );
  }

  int _limiteDoPlano(String? label) {
    switch (label) {
      case 'Bronze':
        return 3;
      case 'Prata':
        return 5;
      case 'Ouro':
        return 999999; // ilimitado (admin bypass deve evitar chegar aqui)
      default:
        return 3; // free tier
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : Colors.white;
    final bodyColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : const Color(0xFF8E8E93);
    final handleColor = isIos
        ? SoloForteSheetSkinIos.handleColor
        : const Color(0xFF3A3A3C);
    final ctaBg = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : const Color(0xFF32D74B);
    final ctaFg = isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final ctaRadius = isIos ? SoloForteSheetSkinIos.ctaRadius : 50.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isIos
                  ? SoloForteSheetSkinIos.handleSize.width
                  : 36,
              height: isIos
                  ? SoloForteSheetSkinIos.handleSize.height
                  : 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFFF9F0A),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              motivo == 'sem_plano'
                  ? 'Plano necessário para publicar'
                  : 'Limite de cases atingido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              motivo == 'sem_plano'
                  ? 'Assine um plano para publicar seus cases agronômicos no mapa.'
                  : 'Seu plano ${planoLabel ?? 'atual'} permite apenas ${limite ?? _limiteDoPlano(planoLabel)} case(s) ativo(s). Faça upgrade para publicar mais.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (context.mounted) context.go('/planos');
                  });
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ctaBg,
                    borderRadius: BorderRadius.circular(ctaRadius),
                  ),
                  child: Center(
                    child: Text(
                      'Ver planos',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ctaFg,
                      ),
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
}
