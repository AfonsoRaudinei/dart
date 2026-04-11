import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

class PlanoBlockSheet extends StatelessWidget {
  final String motivo;
  final String? planoLabel;

  const PlanoBlockSheet({super.key, required this.motivo, this.planoLabel});

  static void show(
    BuildContext context, {
    required String motivo,
    String? planoLabel,
  }) {
    HapticFeedback.heavyImpact();
    showSoloForteSheet(
      context: context,
      showDragHandle: false,
      builder: (ctx) => PlanoBlockSheet(motivo: motivo, planoLabel: planoLabel),
    );
  }

  int _limiteDoPlano(String? label) {
    switch (label) {
      case 'Bronze':
        return 1;
      case 'Prata':
        return 2;
      case 'Ouro':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3C),
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
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              motivo == 'sem_plano'
                  ? 'Assine um plano para publicar seus cases agronômicos no mapa.'
                  : 'Seu plano $planoLabel permite apenas ${_limiteDoPlano(planoLabel)} case(s) ativo(s). Faça upgrade para publicar mais.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF8E8E93),
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
                    color: const Color(0xFF32D74B),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Center(
                    child: Text(
                      'Ver planos',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
