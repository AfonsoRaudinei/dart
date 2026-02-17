import 'package:flutter/material.dart';
import '../../../../../../ui/theme/soloforte_theme.dart';
import 'photo_tile.dart';
import 'camera_button.dart';

class PhotoGrid extends StatelessWidget {
  final String categoryId;
  final List<String> photos;
  final VoidCallback onAdd;
  final Function(String path) onRemove;

  const PhotoGrid({
    super.key,
    required this.categoryId,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Evidências Fotográficas',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SoloForteColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return CameraActionButton(onTap: onAdd);
              }

              final path = photos[index - 1];
              return PhotoTile(path: path, onRemove: () => onRemove(path));
            },
          ),
        ),
      ],
    );
  }
}
