import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

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
        return PlanoTipo.bronze.limiteCases;
      case 'Prata':
        return PlanoTipo.prata.limiteCases;
      case 'Ouro':
        return PlanoTipo.ouro.limiteCases;
      default:
        return PlanoTipo.bronze.limiteCases;
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
                  ? 'Seu plano atual não permite publicar novos cases no mapa.'
                  : 'Seu plano ${planoLabel ?? 'atual'} permite apenas ${limite ?? _limiteDoPlano(planoLabel)} case(s) ativo(s). Exclua um case publicado ou mantenha como Não gerado.',
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
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Ok, entendi',
                  style: TextStyle(
                    fontFamily: 'Inter',
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
