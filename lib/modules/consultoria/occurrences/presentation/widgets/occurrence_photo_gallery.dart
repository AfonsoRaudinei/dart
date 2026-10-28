import 'dart:io';

import 'package:flutter/foundation.dart';
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
  final Map<String, String> captions;
  final double thumbnailSize;
  final bool readOnly;
  final void Function(int index)? onRemove;
  final void Function(int index, String caption)? onCaptionChanged;

  const OccurrencePhotoGallery({
    super.key,
    required this.paths,
    this.captions = const {},
    this.thumbnailSize = 56,
    this.readOnly = true,
    this.onRemove,
    this.onCaptionChanged,
  });

  @override
  State<OccurrencePhotoGallery> createState() => _OccurrencePhotoGalleryState();
}

class _OccurrencePhotoGalleryState extends State<OccurrencePhotoGallery> {
  late List<String?> _resolvedPaths;
  int _resolveGeneration = 0;

  @override
  void initState() {
    super.initState();
    _resolvedPaths = List<String?>.filled(widget.paths.length, null);
    _resolvePaths();
  }

  @override
  void didUpdateWidget(covariant OccurrencePhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.paths, widget.paths)) {
      if (_resolvedPaths.length != widget.paths.length) {
        _resolvedPaths = List<String?>.filled(widget.paths.length, null);
      }
      _resolvePaths();
    }
  }

  Future<void> _resolvePaths() async {
    final generation = ++_resolveGeneration;
    final storage = ImageStorageService();
    final resolved = List<String?>.filled(widget.paths.length, null);
    for (var i = 0; i < widget.paths.length; i++) {
      if (generation != _resolveGeneration) return;
      resolved[i] = await storage.resolveLocalPath(widget.paths[i]);
    }
    if (!mounted || generation != _resolveGeneration) return;
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
          final caption = widget.captions[storedPath] ?? '';
          return _PhotoThumbnail(
            storedPath: storedPath,
            resolvedPath: resolved,
            size: widget.thumbnailSize,
            readOnly: widget.readOnly,
            hasCaption: caption.trim().isNotEmpty,
            onRemove: widget.onRemove == null
                ? null
                : () => widget.onRemove!(index),
            onTap: resolved == null
                ? null
                : () => _openPreview(
                      context,
                      index: index,
                      resolvedPath: resolved,
                      caption: caption,
                    ),
          );
        },
      ),
    );
  }

  Future<void> _openPreview(
    BuildContext context, {
    required int index,
    required String resolvedPath,
    required String caption,
  }) async {
    final updated = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => _PhotoPreviewScreen(
          path: resolvedPath,
          caption: caption,
          readOnly: widget.readOnly || widget.onCaptionChanged == null,
        ),
      ),
    );
    if (!context.mounted || updated == null) return;
    widget.onCaptionChanged?.call(index, updated);
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
  bool _counting = false;
  int _countGeneration = 0;

  @override
  void initState() {
    super.initState();
    _countResolved();
  }

  @override
  void didUpdateWidget(covariant OccurrencePhotoStatusText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.paths, widget.paths)) _countResolved();
  }

  Future<void> _countResolved() async {
    final generation = ++_countGeneration;
    if (widget.paths.isEmpty) {
      if (!mounted) return;
      setState(() {
        _resolvedCount = 0;
        _counting = false;
      });
      return;
    }
    if (mounted) setState(() => _counting = true);
    final storage = ImageStorageService();
    var count = 0;
    for (final path in widget.paths) {
      if (generation != _countGeneration) return;
      if (await storage.resolveLocalPath(path) != null) count++;
    }
    if (!mounted || generation != _countGeneration) return;
    setState(() {
      _resolvedCount = count;
      _counting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paths.isEmpty) {
      return Text(
        widget.emptyHint,
        style: TextStyle(color: widget.hintColor, fontSize: 12),
      );
    }
    if (_counting || _resolvedCount == widget.paths.length) {
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
  final bool hasCaption;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const _PhotoThumbnail({
    required this.storedPath,
    required this.resolvedPath,
    required this.size,
    required this.readOnly,
    this.hasCaption = false,
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
          if (hasCaption)
            Positioned(
              left: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.short_text_rounded,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
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

class _PhotoPreviewScreen extends StatefulWidget {
  final String path;
  final String caption;
  final bool readOnly;

  const _PhotoPreviewScreen({
    required this.path,
    required this.caption,
    required this.readOnly,
  });

  @override
  State<_PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<_PhotoPreviewScreen> {
  late final TextEditingController _captionCtrl;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.caption);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop(widget.readOnly ? null : _captionCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: widget.readOnly ? 72 : 128),
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.file(
                        File(widget.path),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Fechar',
                  onPressed: _close,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: _close,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16 + keyboard,
                child: widget.readOnly
                    ? (_captionCtrl.text.trim().isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            _captionCtrl.text.trim(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ))
                    : TextField(
                        key: const Key('occurrence_photo_caption_field'),
                        controller: _captionCtrl,
                        maxLines: 2,
                        maxLength: kOccurrencePhotoCaptionMaxLength,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          labelText: 'Legenda (opcional)',
                          hintText: 'Ex.: Folha com mancha na nervura',
                          counterStyle: const TextStyle(color: Colors.white54),
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white12,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white70),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
