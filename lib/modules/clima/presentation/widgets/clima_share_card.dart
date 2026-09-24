import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/clima_fonte.dart';
import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';

/// Card visual para captura PNG e compartilhamento como imagem.
class ClimaShareCard extends StatelessWidget {
  const ClimaShareCard({super.key, required this.payload});

  final ClimaSharePayload payload;

  static const double cardWidth = 360;

  @override
  Widget build(BuildContext context) {
    final atribuicao = climaFonteAttribution(payload.fonte);
    final campo = payload.previewCampoLinha;

    return SizedBox(
      width: cardWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1428A0), Color(0xFF2C5564)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SoloForte',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payload.cidade,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payload.previewEmoji,
                    style: const TextStyle(fontSize: 44),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payload.previewTitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          payload.previewSubtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            height: 1.35,
                            color: Color(0xE6FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: payload.previewChips
                    .map(
                      (label) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x4DFFFFFF)),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (campo != null) ...[
                const SizedBox(height: 14),
                Text(
                  campo,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Color(0xF2FFFFFF),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (atribuicao.isNotEmpty)
                Text(
                  atribuicao,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xB3FFFFFF),
                  ),
                ),
              const Text(
                'Inteligência Agronômica',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xB3FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
