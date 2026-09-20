import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/occurrence.dart';
import '../../domain/occurrence_photo_paths.dart';
import '../../../relatorio_visita/data/image_storage_service.dart';

/// Galeria horizontal de fotos de ocorrência com resolução de path e preview.
/// Miniatura de capa para cards de lista (Relatórios / mapa).
class OccurrenceCoverThumbnail extends StatefulWidget {
  final Occurrence occurrence;
  final double width;
  final double height;
  final Widget fallback;

  const OccurrenceCoverThumbnail({
    super.key,
    required this.occurrence,
    this.width = 60,
    this.height = 80,
    required this.fallback,
  });

  @override
  State<OccurrenceCoverThumbnail> createState() =>
      _OccurrenceCoverThumbnailState();
}

class _OccurrenceCoverThumbnailState extends State<OccurrenceCoverThumbnail> {
  String? _resolvedPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant OccurrenceCoverThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.occurrence.id != widget.occurrence.id ||
        oldWidget.occurrence.photoPath != widget.occurrence.photoPath ||
        oldWidget.occurrence.fotosCategoriasJson !=
            widget.occurrence.fotosCategoriasJson) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final cover = coverPhotoPath(widget.occurrence);
    if (cover == null) {
      if (!mounted) return;
      setState(() {
        _resolvedPath = null;
        _loading = false;
      });
      return;
    }
    final resolved = await ImageStorageService().resolveLocalPath(cover);
    if (!mounted) return;
    setState(() {
      _resolvedPath = resolved;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.fallback,
      );
    }
    if (_resolvedPath == null) return widget.fallback;
    return Image.file(
      File(_resolvedPath!),
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => widget.fallback,
    );
  }
}

class OccurrencePhotoGallery extends StatefulWidget {
  final List<String> paths;
  final double thumbnailSize;
  final bool readOnly;
  final void Function(int index)? onRemove;

  const OccurrencePhotoGallery({
    super.key,
    required this.paths,
    this.thumbnailSize = 56,
    this.readOnly = true,
    this.onRemove,
  });

  @override
  State<OccurrencePhotoGallery> createState() => _OccurrencePhotoGalleryState();
}

class _OccurrencePhotoGalleryState extends State<OccurrencePhotoGallery> {
  late List<String?> _resolvedPaths;

  @override
  void initState() {
    super.initState();
    _resolvedPaths = List<String?>.filled(widget.paths.length, null);
    _resolvePaths();
  }

  @override
  void didUpdateWidget(covariant OccurrencePhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paths != widget.paths) {
      _resolvedPaths = List<String?>.filled(widget.paths.length, null);
      _resolvePaths();
    }
  }

  Future<void> _resolvePaths() async {
    final storage = ImageStorageService();
    final resolved = <String?>[];
    for (final path in widget.paths) {
      resolved.add(await storage.resolveLocalPath(path));
    }
    if (!mounted) return;
    setState(() {
      _resolvedPaths = resolved;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paths.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: widget.thumbnailSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final storedPath = widget.paths[index];
          final resolved =
              index < _resolvedPaths.length ? _resolvedPaths[index] : null;
          return _PhotoThumbnail(
            storedPath: storedPath,
            resolvedPath: resolved,
            size: widget.thumbnailSize,
            readOnly: widget.readOnly,
            onRemove: widget.onRemove == null
                ? null
                : () => widget.onRemove!(index),
            onTap: resolved == null
                ? null
                : () => _openPreview(context, resolved),
          );
        },
      ),
    );
  }

  void _openPreview(BuildContext context, String resolvedPath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PhotoPreviewScreen(path: resolvedPath),
      ),
    );
  }
}

/// Texto de status com contagem de arquivos resolvidos no dispositivo.
class OccurrencePhotoStatusText extends StatefulWidget {
  final List<String> paths;
  final String emptyHint;
  final Color hintColor;

  const OccurrencePhotoStatusText({
    super.key,
    required this.paths,
    required this.emptyHint,
    required this.hintColor,
  });

  @override
  State<OccurrencePhotoStatusText> createState() =>
      _OccurrencePhotoStatusTextState();
}

class _OccurrencePhotoStatusTextState extends State<OccurrencePhotoStatusText> {
  int _resolvedCount = 0;

  @override
  void initState() {
    super.initState();
    _countResolved();
  }

  @override
  void didUpdateWidget(covariant OccurrencePhotoStatusText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paths != widget.paths) _countResolved();
  }

  Future<void> _countResolved() async {
    if (widget.paths.isEmpty) {
      if (!mounted) return;
      setState(() => _resolvedCount = 0);
      return;
    }
    final storage = ImageStorageService();
    var count = 0;
    for (final path in widget.paths) {
      if (await storage.resolveLocalPath(path) != null) count++;
    }
    if (!mounted) return;
    setState(() => _resolvedCount = count);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paths.isEmpty) {
      return Text(
        widget.emptyHint,
        style: TextStyle(color: widget.hintColor, fontSize: 12),
      );
    }
    if (_resolvedCount == widget.paths.length) {
      return Text(
        '${widget.paths.length} foto(s) pronta(s) para o relatório.',
        style: TextStyle(color: widget.hintColor, fontSize: 12),
      );
    }
    return Text(
      '${widget.paths.length} foto(s) no registro · $_resolvedCount arquivo(s) encontrado(s) no dispositivo.',
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 12,
      ),
    );
  }
}

class OccurrencePhotoGalleryStatus extends StatelessWidget {
  final int registeredCount;
  final int resolvedCount;

  const OccurrencePhotoGalleryStatus({
    super.key,
    required this.registeredCount,
    required this.resolvedCount,
  });

  @override
  Widget build(BuildContext context) {
    if (registeredCount == 0) {
      return Text(
        'Anexe foto para aparecer no relatório. Selecione a categoria e toque abaixo.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      );
    }

    if (resolvedCount == registeredCount) {
      return Text(
        '$registeredCount foto(s) pronta(s) para o relatório.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      );
    }

    return Text(
      '$registeredCount foto(s) no registro · $resolvedCount arquivo(s) encontrado(s) no dispositivo.',
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 12,
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String storedPath;
  final String? resolvedPath;
  final double size;
  final bool readOnly;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const _PhotoThumbnail({
    required this.storedPath,
    required this.resolvedPath,
    required this.size,
    required this.readOnly,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    Widget image;
    if (resolvedPath != null) {
      image = ClipRRect(
        borderRadius: borderRadius,
        child: Image.file(
          File(resolvedPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _missingPlaceholder(size),
        ),
      );
    } else {
      image = _missingPlaceholder(size);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          image,
          if (!readOnly && onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _missingPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC7C7CC)),
      ),
      child: const Icon(
        Icons.broken_image_outlined,
        color: Color(0xFF8E8E93),
        size: 22,
      ),
    );
  }
}

class _PhotoPreviewScreen extends StatelessWidget {
  final String path;

  const _PhotoPreviewScreen({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
