import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

/// Cenas colormap guardadas no aparelho. A mais nova permanece mesmo fora da janela.
const int kNdviHistoryMaxScenes = 12;
const Duration kNdviHistoryMaxAge = Duration(days: 90);

List<NdviImage> ndviHistoryKept(List<NdviImage> images, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final sorted = [...images]
    ..sort((a, b) => b.imageDate.compareTo(a.imageDate));
  final kept = <NdviImage>[];
  for (final image in sorted) {
    if (kept.length >= kNdviHistoryMaxScenes) break;
    final olderThanWindow =
        kept.isNotEmpty &&
        clock.difference(image.imageDate) > kNdviHistoryMaxAge;
    if (olderThanWindow) continue;
    kept.add(image);
  }
  return kept;
}
