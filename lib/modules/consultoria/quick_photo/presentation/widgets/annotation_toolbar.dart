import 'package:flutter/material.dart';

class AnnotationToolbar extends StatelessWidget {
  final Color selectedColor;
  final bool isCircleMode;
  final bool filterActive;
  final bool canUndo;
  final bool isFiltering;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<bool> onCircleModeChanged;
  final VoidCallback onUndo;
  final VoidCallback onToggleFilter;

  const AnnotationToolbar({
    super.key,
    required this.selectedColor,
    required this.isCircleMode,
    required this.filterActive,
    required this.canUndo,
    required this.isFiltering,
    required this.onColorChanged,
    required this.onCircleModeChanged,
    required this.onUndo,
    required this.onToggleFilter,
  });

  static const _colors = [
    Colors.red,
    Colors.yellow,
    Colors.blue,
    Colors.white,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Lápis',
              icon: const Icon(Icons.edit_rounded),
              color: isCircleMode ? Colors.white54 : Colors.white,
              onPressed: () => onCircleModeChanged(false),
            ),
            IconButton(
              tooltip: 'Círculo',
              icon: const Icon(Icons.circle_outlined),
              color: isCircleMode ? Colors.white : Colors.white54,
              onPressed: () => onCircleModeChanged(true),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _colors.map((color) {
                    final selected = selectedColor == color;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => onColorChanged(color),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? Colors.white : Colors.white24,
                              width: selected ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Desfazer',
              icon: const Icon(Icons.undo_rounded),
              color: canUndo ? Colors.white : Colors.white30,
              onPressed: canUndo ? onUndo : null,
            ),
            IconButton(
              tooltip: 'Filtro vegetal',
              icon: isFiltering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.eco_rounded),
              color: filterActive ? Colors.lightGreenAccent : Colors.white,
              onPressed: isFiltering ? null : onToggleFilter,
            ),
          ],
        ),
      ),
    );
  }
}
