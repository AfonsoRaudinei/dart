import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../data/quick_photo_repository.dart';
import '../../data/vegetal_filter.dart';
import '../widgets/annotation_canvas.dart';
import '../widgets/annotation_toolbar.dart';

class PhotoEditorScreen extends StatefulWidget {
  final String imagePath;
  final double? lat;
  final double? lng;
  final String? visitSessionId;
  final bool initialFilterActive;

  const PhotoEditorScreen({
    super.key,
    required this.imagePath,
    this.lat,
    this.lng,
    this.visitSessionId,
    this.initialFilterActive = false,
  });

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  final _repository = QuickPhotoRepository();
  final List<AnnotationStroke> _strokes = [];

  Uint8List? _baseBytes;
  Uint8List? _previewBytes;
  ui.Image? _baseImage;
  Size? _lastCanvasSize;
  Color _selectedColor = Colors.red;
  bool _isCircleMode = false;
  bool _filterActive = false;
  bool _isFilteringPreview = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final image = await _decodeUiImage(bytes);
    if (!mounted) return;
    setState(() {
      _baseBytes = bytes;
      _baseImage = image;
      _filterActive = widget.initialFilterActive;
    });
    if (widget.initialFilterActive) {
      await _buildFilterPreview();
    }
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _addStroke(AnnotationStroke stroke) {
    setState(() => _strokes.add(stroke));
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  Future<void> _toggleFilter() async {
    final nextValue = !_filterActive;
    setState(() {
      _filterActive = nextValue;
      if (!nextValue) _previewBytes = null;
    });
    if (nextValue) {
      await _buildFilterPreview();
    }
  }

  Future<void> _buildFilterPreview() async {
    final bytes = _baseBytes;
    if (bytes == null) return;

    setState(() => _isFilteringPreview = true);
    try {
      final source = img.decodeImage(bytes);
      if (source == null) return;
      final previewSource = source.width > 800
          ? img.copyResize(source, width: 800)
          : source;
      final filtered = await compute(applyVegetalFilter, previewSource);
      final previewBytes = Uint8List.fromList(
        img.encodeJpg(filtered, quality: 85),
      );
      if (!mounted || !_filterActive) return;
      setState(() => _previewBytes = previewBytes);
    } finally {
      if (mounted) setState(() => _isFilteringPreview = false);
    }
  }

  Future<void> _save() async {
    final baseBytes = _baseBytes;
    final baseImage = _baseImage;
    final canvasSize = _lastCanvasSize;
    if (baseBytes == null ||
        baseImage == null ||
        canvasSize == null ||
        _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final finalBytes = await _composeFinalBytes(
        baseBytes,
        baseImage,
        canvasSize,
      );
      await File(widget.imagePath).writeAsBytes(finalBytes, flush: true);
      await _repository.uploadAndInsert(
        bytes: finalBytes,
        localPath: widget.imagePath,
        lat: widget.lat,
        lng: widget.lng,
        visitSessionId: widget.visitSessionId,
        type: _filterActive
            ? QuickPhotoType.vegetalFilter
            : QuickPhotoType.normal,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foto salva localmente, será enviada quando houver conexão',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<Uint8List> _composeFinalBytes(
    Uint8List baseBytes,
    ui.Image baseImage,
    Size canvasSize,
  ) async {
    final outputBaseImage = await _buildOutputBaseImage(baseBytes, baseImage);
    final outputSize = Size(
      baseImage.width.toDouble(),
      baseImage.height.toDouble(),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(outputBaseImage, Offset.zero, Paint());
    canvas.save();
    canvas.scale(
      outputSize.width / canvasSize.width,
      outputSize.height / canvasSize.height,
    );
    AnnotationPainter(strokes: _strokes).paint(canvas, canvasSize);
    canvas.restore();

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(baseImage.width, baseImage.height);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) return pngBytes;

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
  }

  Future<ui.Image> _buildOutputBaseImage(
    Uint8List baseBytes,
    ui.Image baseImage,
  ) async {
    if (!_filterActive) return baseImage;

    final source = img.decodeImage(baseBytes);
    if (source == null) return baseImage;

    final filtered = await compute(applyVegetalFilter, source);
    return _decodeUiImage(Uint8List.fromList(img.encodePng(filtered)));
  }

  Rect _containedRect(Size imageSize, Size bounds) {
    final scale = math.min(
      bounds.width / imageSize.width,
      bounds.height / imageSize.height,
    );
    final fittedSize = Size(imageSize.width * scale, imageSize.height * scale);
    final offset = Offset(
      (bounds.width - fittedSize.width) / 2,
      (bounds.height - fittedSize.height) / 2,
    );
    return offset & fittedSize;
  }

  @override
  Widget build(BuildContext context) {
    final baseImage = _baseImage;
    final imageBytes = _previewBytes;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (baseImage == null)
              const Center(child: CircularProgressIndicator())
            else
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 88),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bounds = constraints.biggest;
                      final imageRect = _containedRect(
                        Size(
                          baseImage.width.toDouble(),
                          baseImage.height.toDouble(),
                        ),
                        bounds,
                      );
                      _lastCanvasSize = imageRect.size;

                      return Stack(
                        children: [
                          Positioned.fromRect(
                            rect: imageRect,
                            child: imageBytes != null
                                ? Image.memory(imageBytes, fit: BoxFit.fill)
                                : Image.file(
                                    File(widget.imagePath),
                                    fit: BoxFit.fill,
                                  ),
                          ),
                          Positioned.fromRect(
                            rect: imageRect,
                            child: AnnotationCanvas(
                              strokes: List.unmodifiable(_strokes),
                              selectedColor: _selectedColor,
                              isCircleMode: _isCircleMode,
                              onStrokeAdded: _addStroke,
                            ),
                          ),
                          if (_isFilteringPreview)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      );
                    },
                  ),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton.filled(
                tooltip: 'Fechar',
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Salvar'),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnnotationToolbar(
                selectedColor: _selectedColor,
                isCircleMode: _isCircleMode,
                filterActive: _filterActive,
                canUndo: _strokes.isNotEmpty,
                isFiltering: _isFilteringPreview,
                onColorChanged: (color) => setState(() {
                  _selectedColor = color;
                }),
                onCircleModeChanged: (value) => setState(() {
                  _isCircleMode = value;
                }),
                onUndo: _undo,
                onToggleFilter: _toggleFilter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
