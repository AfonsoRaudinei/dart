import 'package:flutter/material.dart';

import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_share_card.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_share_png.dart';

/// Prévia em tamanho real do [ClimaShareCard] antes de compartilhar.
Future<void> showClimaCardPreviewDialog(
  BuildContext context,
  ClimaSharePayload payload,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _ClimaCardPreviewDialog(payload: payload),
  );
}

class _ClimaCardPreviewDialog extends StatefulWidget {
  const _ClimaCardPreviewDialog({required this.payload});

  final ClimaSharePayload payload;

  @override
  State<_ClimaCardPreviewDialog> createState() => _ClimaCardPreviewDialogState();
}

class _ClimaCardPreviewDialogState extends State<_ClimaCardPreviewDialog> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final ok = await shareClimaCardAsPng(context, widget.payload);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível gerar o card para compartilhar'),
          ),
        );
      } else if (ok && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final bg = isIos
        ? SoloForteSheetSkinIos.background
        : SoloForteSheetTokens.sheetBackground;
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.titleColor;
    final accent = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : Theme.of(context).colorScheme.primary;
    final radius = isIos ? SoloForteSheetSkinIos.sheetRadius : 20.0;

    final width = MediaQuery.sizeOf(context).width;
    final cardMaxWidth = (width - 48).clamp(280.0, ClimaShareCard.cardWidth);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Card da previsão',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: cardMaxWidth,
                child: ClimaShareCard(payload: widget.payload),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sharing ? null : _share,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isIos ? SoloForteSheetSkinIos.ctaRadius : 12,
                    ),
                  ),
                ),
                child: _sharing
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isIos
                              ? SoloForteSheetSkinIos.ctaText
                              : Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        'Compartilhar card',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fechar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
