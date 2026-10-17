import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../design/sf_icons.dart';
import 'report_photo_links.dart';

/// Visualizador nativo das fotos de um relatório HTML: swipe entre fotos,
/// pinça/duplo toque para zoom e botão de fechar que volta ao relatório.
class ReportPhotoViewer extends StatefulWidget {
  const ReportPhotoViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  final List<ReportPhoto> photos;
  final int initialIndex;

  /// Abre o visualizador em rota modal própria (fechar = voltar ao relatório).
  static Future<void> open(
    BuildContext context, {
    required List<ReportPhoto> photos,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            ReportPhotoViewer(photos: photos, initialIndex: initialIndex),
      ),
    );
  }

  @override
  State<ReportPhotoViewer> createState() => _ReportPhotoViewerState();
}

class _ReportPhotoViewerState extends State<ReportPhotoViewer> {
  late final PageController _pageController;
  late int _current;
  bool _zoomed = false;
  final Map<int, Uint8List?> _bytesCache = {};

  @override
  void initState() {
    super.initState();
    final last = widget.photos.isEmpty ? 0 : widget.photos.length - 1;
    _current = widget.initialIndex.clamp(0, last);
    _pageController = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Uint8List? _bytesFor(int position) {
    return _bytesCache.putIfAbsent(
      position,
      () => widget.photos[position].decodeBytes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;
    final caption = total == 0 ? null : widget.photos[_current].caption;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: total,
              onPageChanged: (position) => setState(() {
                _current = position;
                _zoomed = false;
              }),
              itemBuilder: (context, position) => _ZoomablePhoto(
                key: ValueKey('report-photo-$position'),
                photo: widget.photos[position],
                bytes: _bytesFor(position),
                onZoomChanged: (zoomed) {
                  if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                },
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('report-photo-viewer-close'),
                      tooltip: 'Fechar',
                      color: Colors.white,
                      icon: const Icon(SFIcons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    if (total > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          '${_current + 1} de $total',
                          key: const ValueKey('report-photo-viewer-counter'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (caption != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({
    super.key,
    required this.photo,
    required this.bytes,
    required this.onZoomChanged,
  });

  final ReportPhoto photo;
  final Uint8List? bytes;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  static const _minScale = 1.0;
  static const _maxScale = 5.0;
  static const _doubleTapScale = 2.5;

  final TransformationController _transform = TransformationController();
  Offset? _doubleTapPosition;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  bool get _isZoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  void _onInteractionEnd(ScaleEndDetails _) {
    widget.onZoomChanged(_isZoomed);
  }

  void _toggleZoom() {
    if (_isZoomed) {
      _transform.value = Matrix4.identity();
    } else {
      final focal = _doubleTapPosition ?? Offset.zero;
      _transform.value = Matrix4.identity()
        ..translateByDouble(
          -focal.dx * (_doubleTapScale - 1),
          -focal.dy * (_doubleTapScale - 1),
          0,
          1,
        )
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
    }
    widget.onZoomChanged(_isZoomed);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: _minScale,
        maxScale: _maxScale,
        onInteractionEnd: _onInteractionEnd,
        child: SizedBox.expand(child: Center(child: _buildImage())),
      ),
    );
  }

  Widget _buildImage() {
    final bytes = widget.bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _PhotoUnavailable(),
      );
    }
    if (widget.photo.isNetwork) {
      return Image.network(
        widget.photo.src,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _PhotoUnavailable(),
      );
    }
    return const _PhotoUnavailable();
  }
}

class _PhotoUnavailable extends StatelessWidget {
  const _PhotoUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Foto indisponível',
      style: TextStyle(color: Colors.white70, fontSize: 15),
    );
  }
}
