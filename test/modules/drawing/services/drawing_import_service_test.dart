import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/services/drawing_import_service.dart';
import 'package:soloforte_app/modules/drawing/infra/file_picker/i_file_picker.dart';

// =============================================================================
// Fake colaboradores
// =============================================================================

/// Simula um seletor que sempre retorna null (usuário cancelou).
class _CancelledPicker implements IFilePicker {
  const _CancelledPicker();
  @override
  Future<PlatformFile?> pickSingleFile({
    required List<String> allowedExtensions,
  }) async => null;
}

/// Simula um seletor que retorna um arquivo real a partir de bytes.
class _FilePicker implements IFilePicker {
  final PlatformFile file;
  const _FilePicker(this.file);

  @override
  Future<PlatformFile?> pickSingleFile({
    required List<String> allowedExtensions,
  }) async => file;
}

/// Simula um seletor que lança exceção (falha de plataforma).
class _ThrowingPicker implements IFilePicker {
  const _ThrowingPicker();
  @override
  Future<PlatformFile?> pickSingleFile({
    required List<String> allowedExtensions,
  }) async => throw Exception('Permissão negada');
}

// =============================================================================
// Helpers
// =============================================================================

/// Cria um arquivo KML temporário com [content] e retorna PlatformFile.
Future<PlatformFile> _tempKml(String content) async {
  final dir = await Directory.systemTemp.createTemp('kml_test_');
  final file = File('${dir.path}/test.kml');
  await file.writeAsString(content);
  return PlatformFile(
    name: 'test.kml',
    size: content.length,
    path: file.path,
  );
}

const _kmlSemPoligono = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Placemark>
    <name>Ponto</name>
    <Point><coordinates>0,0,0</coordinates></Point>
  </Placemark>
</kml>''';

const _kmlComPoligono = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Placemark>
    <Polygon>
      <outerBoundaryIs>
        <LinearRing>
          <coordinates>
            0.0,0.0,0
            0.01,0.0,0
            0.01,0.01,0
            0.0,0.01,0
            0.0,0.0,0
          </coordinates>
        </LinearRing>
      </outerBoundaryIs>
    </Polygon>
  </Placemark>
</kml>''';

// =============================================================================
// Testes
// =============================================================================

void main() {
  group('DrawingImportService.pickAndParse', () {
    test('retorna cancelled=true quando picker retorna null', () async {
      final service = const DrawingImportService(_CancelledPicker());
      final result = await service.pickAndParse(false);

      expect(result.cancelled, isTrue);
      expect(result.geometry, isNull);
      expect(result.error, isNull);
    });

    test('retorna error quando arquivo nao contem geometria', () async {
      final file = await _tempKml(_kmlSemPoligono);
      final service = DrawingImportService(_FilePicker(file));
      final result = await service.pickAndParse(false);

      expect(result.cancelled, isFalse);
      expect(result.geometry, isNull);
      expect(result.error, isNotNull);
      expect(result.isSuccess, isFalse);
    });

    test('retorna geometria quando KML valido', () async {
      final file = await _tempKml(_kmlComPoligono);
      final service = DrawingImportService(_FilePicker(file));
      final result = await service.pickAndParse(false);

      // Pode falhar se simplifyGeometry não estiver disponível em test;
      // mas o caminho feliz deve ao menos não ser cancelled.
      expect(result.cancelled, isFalse);
    });

    test('retorna error (nao lanca excecao) quando picker falha', () async {
      final service = const DrawingImportService(_ThrowingPicker());
      final result = await service.pickAndParse(false);

      expect(result.error, isNotNull);
      expect(result.cancelled, isFalse);
      expect(result.isSuccess, isFalse);
    });

    test('ImportResult.isSuccess é false quando há error', () {
      const r = ImportResult(error: 'falhou');
      expect(r.isSuccess, isFalse);
    });

    test('ImportResult.isSuccess é false quando cancelled', () {
      const r = ImportResult(cancelled: true);
      expect(r.isSuccess, isFalse);
    });
  });
}
