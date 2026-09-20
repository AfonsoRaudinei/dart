import 'package:flutter/material.dart';

import '../../../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/occurrence.dart';
import '../../domain/occurrence_photo_paths.dart';
import 'occurrence_photo_gallery.dart';

class OccurrenceDetailPhotoSection extends StatelessWidget {
  final Occurrence occurrence;
  final Color cardBg;
  final double cardRadius;
  final bool isIos;
  final bool isDark;

  const OccurrenceDetailPhotoSection({
    super.key,
    required this.occurrence,
    required this.cardBg,
    required this.cardRadius,
    required this.isIos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final photoPaths = allPhotoPaths(occurrence);
    if (photoPaths.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(cardRadius),
          border: isIos
              ? Border.all(color: SoloForteSheetSkinIos.cardBorder)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fotos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: isIos
                    ? SoloForteSheetSkinIos.subtitleColor
                    : (isDark
                        ? PremiumTokens.textSecondaryDark
                        : context.premiumTextSecondary),
              ),
            ),
            const SizedBox(height: 10),
            OccurrencePhotoGallery(
              paths: photoPaths,
              thumbnailSize: 72,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}
