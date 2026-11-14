import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:flutter/services.dart';
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

  String _limiteTextoDoPlano(String? label) {
    switch (label) {
      case 'Bronze':
        return '5 cases Bronze';
      case 'Prata':
        return '5 Bronze · 5 Prata';
      case 'Ouro':
        return '5 Bronze · 5 Prata · 10 Ouro';
      default:
        return 'cota por metal do plano';
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final titleColor = v.onSheetPrimary;
    final bodyColor = isIos
        ? v.subtitleColor
        : const Color(0xFF8E8E93);
    final handleColor = isIos
        ? v.handleColor
        : const Color(0xFF3A3A3C);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: v.handleSize.width,
              height: v.handleSize.height,
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
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              motivo == 'sem_plano'
                  ? 'Seu plano atual não permite publicar novos cases no mapa.'
                  : 'Seu plano ${planoLabel ?? 'atual'} permite ${limite != null ? 'até $limite case(s) ativo(s)' : _limiteTextoDoPlano(planoLabel)} por metal. Exclua um case publicado ou mantenha como Não gerado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Ok, entendi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: bodyColor,
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
