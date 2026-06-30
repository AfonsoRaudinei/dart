import '../models/drawing_models.dart';
import '../drawing_utils.dart';
import '../../infra/file_picker/i_file_picker.dart';

/// Resultado de uma operação de importação de arquivo.
class ImportResult {
  final DrawingGeometry? geometry;
  final DrawingOrigin? origin;
  final String? error;
  final bool cancelled;

  const ImportResult({
    this.geometry,
    this.origin,
    this.error,
    this.cancelled = false,
  });

  bool get isSuccess => geometry != null && error == null && !cancelled;
}

/// Serviço de importação de arquivos KML/KMZ.
///
/// Depende de [IFilePicker] (injetável), permitindo testes com [FakeFilePicker].
class DrawingImportService {
  final IFilePicker _filePicker;

  const DrawingImportService(this._filePicker);

  /// Abre o seletor de arquivo (KML ou KMZ), parseia e retorna a geometria processada.
  ///
  /// O tipo é inferido automaticamente pela extensão do arquivo selecionado.
  ///
  /// Casos de retorno:
  /// - `cancelled = true` → usuário cancelou, sem ação necessária
  /// - `error != null` → arquivo inválido ou erro de leitura
  /// - `isSuccess == true` → geometria pronta para preview
  Future<ImportResult> pickAndParse() async {
    try {
      final file = await _filePicker.pickSingleFile(
        allowedExtensions: ['kml', 'kmz'],
      );

      if (file == null) {
        return const ImportResult(cancelled: true);
      }

      final ext = file.name.split('.').last.toLowerCase();
      final geometry = await DrawingUtils.parseFileOrThrow(file);

      var processed = DrawingUtils.simplifyGeometry(geometry);
      processed = DrawingUtils.normalizeGeometry(processed);

      final origin = ext == 'kmz'
          ? DrawingOrigin.importacao_kmz
          : DrawingOrigin.importacao_kml;

      return ImportResult(geometry: processed, origin: origin);
    } on DrawingImportException catch (e) {
      return ImportResult(error: e.message);
    } catch (e) {
      return ImportResult(error: 'Erro ao ler arquivo: $e');
    }
  }
}
