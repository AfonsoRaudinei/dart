import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  /// Exporta e compartilha uma única [DrawingFeature] como .geojson.
  Future<void> exportFeature(DrawingFeature feature) async {
    state = const ExportLoading();
    try {
      final content = _service.exportFeature(feature);
      final fileName = _service.fileNameFor(feature);
      await _shareGeoJsonFile(content, fileName);
      state = ExportSuccess(fileName);
    } catch (e) {
      state = ExportError('Erro ao exportar: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // EXPORT — Coleção completa
  // ---------------------------------------------------------------------------

  /// Exporta e compartilha todos os talhões como GeoJSON FeatureCollection.
  Future<void> exportAll(List<DrawingFeature> features) async {
    if (features.isEmpty) {
      state = const ExportError('Nenhum talhão disponível para exportar.');
      return;
    }
    state = const ExportLoading();
    try {
      final content = _service.exportFeatureCollection(features);
      final fileName = _service.collectionFileName();
      await _shareGeoJsonFile(content, fileName);
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

  // ---------------------------------------------------------------------------
  // PRIVATE
  // ---------------------------------------------------------------------------

  Future<void> _shareGeoJsonFile(String content, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/geo+json')],
      subject: fileName,
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
