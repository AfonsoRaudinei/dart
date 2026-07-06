import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/share_position.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/services/geojson_exporter_service.dart';

// =============================================================================
// STATE
// =============================================================================

sealed class ExportState {
  const ExportState();
}

class ExportIdle extends ExportState {
  const ExportIdle();
}

class ExportLoading extends ExportState {
  const ExportLoading();
}

class ExportSuccess extends ExportState {
  final String fileName;
  const ExportSuccess(this.fileName);
}

class ExportError extends ExportState {
  final String message;
  const ExportError(this.message);
}

enum DrawingExportFormat { geojson, gpx, dxf, csv, txt, pdf }

class _ExportPayload {
  final String fileName;
  final String mimeType;
  final String? content;
  final List<int>? bytes;

  const _ExportPayload({
    required this.fileName,
    required this.mimeType,
    this.content,
    this.bytes,
  });
}

// =============================================================================
// NOTIFIER
// =============================================================================

/// Gerencia as operações de exportação GeoJSON.
///
/// Responsabilidades:
/// - Serializar features usando [GeoJsonExporterService] (puro)
/// - Gravar arquivo temporário com [path_provider]
/// - Compartilhar via [Share.shareXFiles] (share_plus)
///
/// Não persiste estado entre sessões — reset automático via [ExportIdle].
class DrawingExportNotifier extends Notifier<ExportState> {
  static const _service = GeoJsonExporterService();

  @override
  ExportState build() => const ExportIdle();

  // ---------------------------------------------------------------------------
  // EXPORT — Feature única
  // ---------------------------------------------------------------------------

  Future<void> exportFeature(
    DrawingFeature feature, {
    DrawingExportFormat format = DrawingExportFormat.geojson,
    Rect? sharePositionOrigin,
  }) async {
    state = const ExportLoading();
    try {
      final exported = await _buildExportForSingle(feature, format);
      await _shareFile(
        bytes: exported.bytes,
        content: exported.content,
        fileName: exported.fileName,
        mimeType: exported.mimeType,
        sharePositionOrigin: sharePositionOrigin,
      );
      final fileName = exported.fileName;
      state = ExportSuccess(fileName);
    } catch (e) {
      state = ExportError('Erro ao exportar: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // EXPORT — Coleção completa
  // ---------------------------------------------------------------------------

  Future<void> exportAll(
    List<DrawingFeature> features, {
    DrawingExportFormat format = DrawingExportFormat.geojson,
    Rect? sharePositionOrigin,
  }) async {
    if (features.isEmpty) {
      state = const ExportError('Nenhum talhão disponível para exportar.');
      return;
    }
    state = const ExportLoading();
    try {
      final exported = await _buildExportForCollection(features, format);
      await _shareFile(
        bytes: exported.bytes,
        content: exported.content,
        fileName: exported.fileName,
        mimeType: exported.mimeType,
        sharePositionOrigin: sharePositionOrigin,
      );
      final fileName = exported.fileName;
      state = ExportSuccess(fileName);
    } catch (e) {
      state = ExportError('Erro ao exportar coleção: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // RESET
  // ---------------------------------------------------------------------------

  /// Retorna ao estado ocioso. Chamar após consumir [ExportSuccess]/[ExportError].
  void reset() => state = const ExportIdle();

  @visibleForTesting
  String buildGpxForTesting(List<DrawingFeature> features) =>
      _buildGpx(features);

  // ---------------------------------------------------------------------------
  // PRIVATE
  // ---------------------------------------------------------------------------

  Future<_ExportPayload> _buildExportForSingle(
    DrawingFeature feature,
    DrawingExportFormat format,
  ) async {
    switch (format) {
      case DrawingExportFormat.geojson:
        return _ExportPayload(
          content: _service.exportFeature(feature),
          fileName: _service.fileNameFor(feature),
          mimeType: 'application/geo+json',
        );
      case DrawingExportFormat.gpx:
        return _ExportPayload(
          content: _buildGpx([feature]),
          fileName: _replaceExtension(_service.fileNameFor(feature), 'gpx'),
          mimeType: 'application/gpx+xml',
        );
      case DrawingExportFormat.dxf:
        return _ExportPayload(
          content: _buildDxf([feature]),
          fileName: _replaceExtension(_service.fileNameFor(feature), 'dxf'),
          mimeType: 'application/dxf',
        );
      case DrawingExportFormat.csv:
        return _ExportPayload(
          content: _buildCsv([feature]),
          fileName: _replaceExtension(_service.fileNameFor(feature), 'csv'),
          mimeType: 'text/csv',
        );
      case DrawingExportFormat.txt:
        return _ExportPayload(
          content: _buildTxt([feature]),
          fileName: _replaceExtension(_service.fileNameFor(feature), 'txt'),
          mimeType: 'text/plain',
        );
      case DrawingExportFormat.pdf:
        return _ExportPayload(
          bytes: await _buildPdf([feature]),
          fileName: _replaceExtension(_service.fileNameFor(feature), 'pdf'),
          mimeType: 'application/pdf',
        );
    }
  }

  Future<_ExportPayload> _buildExportForCollection(
    List<DrawingFeature> features,
    DrawingExportFormat format,
  ) async {
    switch (format) {
      case DrawingExportFormat.geojson:
        return _ExportPayload(
          content: _service.exportFeatureCollection(features),
          fileName: _service.collectionFileName(),
          mimeType: 'application/geo+json',
        );
      case DrawingExportFormat.gpx:
        return _ExportPayload(
          content: _buildGpx(features),
          fileName: _replaceExtension(_service.collectionFileName(), 'gpx'),
          mimeType: 'application/gpx+xml',
        );
      case DrawingExportFormat.dxf:
        return _ExportPayload(
          content: _buildDxf(features),
          fileName: _replaceExtension(_service.collectionFileName(), 'dxf'),
          mimeType: 'application/dxf',
        );
      case DrawingExportFormat.csv:
        return _ExportPayload(
          content: _buildCsv(features),
          fileName: _replaceExtension(_service.collectionFileName(), 'csv'),
          mimeType: 'text/csv',
        );
      case DrawingExportFormat.txt:
        return _ExportPayload(
          content: _buildTxt(features),
          fileName: _replaceExtension(_service.collectionFileName(), 'txt'),
          mimeType: 'text/plain',
        );
      case DrawingExportFormat.pdf:
        return _ExportPayload(
          bytes: await _buildPdf(features),
          fileName: _replaceExtension(_service.collectionFileName(), 'pdf'),
          mimeType: 'application/pdf',
        );
    }
  }

  String _replaceExtension(String fileName, String extension) {
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    return '$base.$extension';
  }

  String _buildGpx(List<DrawingFeature> features) {
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<gpx version="1.1" creator="SoloForte" xmlns="http://www.topografix.com/GPX/1/1">',
      );

    for (final feature in features) {
      final rings = _extractRings(feature.geometry);
      int ringIndex = 0;
      for (final ring in rings) {
        if (ring.isEmpty) continue;
        b.writeln('  <trk>');
        b.writeln(
          '    <name>${_escapeXml(feature.properties.nome)} ${ringIndex + 1}</name>',
        );
        b.writeln('    <trkseg>');
        for (final p in ring) {
          b.writeln('      <trkpt lat="${p[1]}" lon="${p[0]}"></trkpt>');
        }
        b.writeln('    </trkseg>');
        b.writeln('  </trk>');
        ringIndex++;
      }
    }
    b.writeln('</gpx>');
    return b.toString();
  }

  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _buildDxf(List<DrawingFeature> features) {
    final b = StringBuffer()
      ..writeln('0')
      ..writeln('SECTION')
      ..writeln('2')
      ..writeln('ENTITIES');

    for (final feature in features) {
      final rings = _extractRings(feature.geometry);
      for (final ring in rings) {
        if (ring.length < 2) continue;
        b.writeln('0');
        b.writeln('LWPOLYLINE');
        b.writeln('8');
        b.writeln(feature.properties.nome);
        b.writeln('90');
        b.writeln(ring.length);
        b.writeln('70');
        b.writeln('1');
        for (final p in ring) {
          b.writeln('10');
          b.writeln(p[0]);
          b.writeln('20');
          b.writeln(p[1]);
        }
      }
    }

    b
      ..writeln('0')
      ..writeln('ENDSEC')
      ..writeln('0')
      ..writeln('EOF');
    return b.toString();
  }

  String _buildCsv(List<DrawingFeature> features) {
    final b = StringBuffer('feature_id,nome,ring,vertex,latitude,longitude\n');
    for (final feature in features) {
      final rings = _extractRings(feature.geometry);
      for (int r = 0; r < rings.length; r++) {
        final ring = rings[r];
        for (int i = 0; i < ring.length; i++) {
          final p = ring[i];
          b.writeln(
            '${feature.id},"${feature.properties.nome.replaceAll('"', '""')}",${r + 1},${i + 1},${p[1]},${p[0]}',
          );
        }
      }
    }
    return b.toString();
  }

  String _buildTxt(List<DrawingFeature> features) {
    final b = StringBuffer();
    for (final feature in features) {
      b.writeln('Talhão: ${feature.properties.nome}');
      b.writeln('ID: ${feature.id}');
      b.writeln('Área (ha): ${feature.properties.areaHa.toStringAsFixed(4)}');
      final rings = _extractRings(feature.geometry);
      for (int r = 0; r < rings.length; r++) {
        b.writeln('Anel ${r + 1}:');
        for (int i = 0; i < rings[r].length; i++) {
          final p = rings[r][i];
          b.writeln('  ${i + 1}. lat=${p[1]}, lon=${p[0]}');
        }
      }
      b.writeln('');
    }
    return b.toString();
  }

  Future<List<int>> _buildPdf(List<DrawingFeature> features) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Relatório de Coordenadas')),
          ...features.map((f) {
            final rings = _extractRings(f.geometry);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${f.properties.nome} (${f.properties.areaHa.toStringAsFixed(4)} ha)',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                for (int r = 0; r < rings.length; r++) ...[
                  pw.Text('Anel ${r + 1}'),
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headers: const ['#', 'Latitude', 'Longitude'],
                    data: [
                      for (int i = 0; i < rings[r].length; i++)
                        [
                          '${i + 1}',
                          rings[r][i][1].toStringAsFixed(7),
                          rings[r][i][0].toStringAsFixed(7),
                        ],
                    ],
                  ),
                  pw.SizedBox(height: 8),
                ],
                pw.Divider(),
              ],
            );
          }),
        ],
      ),
    );
    return doc.save();
  }

  List<List<List<double>>> _extractRings(DrawingGeometry geometry) {
    if (geometry is DrawingPolygon) {
      return geometry.coordinates;
    }
    if (geometry is DrawingMultiPolygon) {
      return geometry.coordinates.expand((poly) => poly).toList();
    }
    return const [];
  }

  Future<void> _shareFile({
    List<int>? bytes,
    String? content,
    required String fileName,
    required String mimeType,
    Rect? sharePositionOrigin,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    if (bytes != null) {
      await file.writeAsBytes(bytes, flush: true);
    } else if (content != null) {
      await file.writeAsString(content, flush: true);
    } else {
      throw Exception('Payload de exportação inválido');
    }
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: fileName,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

// =============================================================================
// PROVIDER
// =============================================================================

final drawingExportProvider =
    NotifierProvider<DrawingExportNotifier, ExportState>(
      DrawingExportNotifier.new,
    );
