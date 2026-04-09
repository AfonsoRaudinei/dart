import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
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
Future<PlatformFile> _tempKml(
  String content, {
  String fileName = 'test.kml',
}) async {
  final dir = await Directory.systemTemp.createTemp('kml_test_');
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(content);
  return PlatformFile(name: fileName, size: content.length, path: file.path);
}

/// Cria um arquivo KMZ temporário com um KML interno.
Future<PlatformFile> _tempKmz(
  String kmlContent, {
  String kmzName = 'test.kmz',
  String kmlEntryName = 'doc.kml',
}) async {
  final dir = await Directory.systemTemp.createTemp('kmz_test_');
  final file = File('${dir.path}/$kmzName');

  final kmlBytes = utf8.encode(kmlContent);
  final archive = Archive()
    ..addFile(ArchiveFile(kmlEntryName, kmlBytes.length, kmlBytes));

  final zipped = ZipEncoder().encode(archive);

  await file.writeAsBytes(zipped, flush: true);
  return PlatformFile(name: kmzName, size: zipped.length, path: file.path);
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
            -47.123456,-15.456789,0
            -47.120000,-15.456789,0
            -47.120000,-15.453000,0
            -47.123456,-15.453000,0
            -47.123456,-15.456789,0
          </coordinates>
        </LinearRing>
      </outerBoundaryIs>
    </Polygon>
  </Placemark>
</kml>''';

const _kmlComBOM = '\uFEFF$_kmlComPoligono';

// =============================================================================
// Testes
// =============================================================================

void main() {
  group('DrawingImportService.pickAndParse', () {
    test('retorna cancelled=true quando picker retorna null', () async {
      final service = const DrawingImportService(_CancelledPicker());
      final result = await service.pickAndParse();

      expect(result.cancelled, isTrue);
      expect(result.geometry, isNull);
      expect(result.error, isNull);
    });

    test('retorna error quando arquivo nao contem geometria', () async {
      final file = await _tempKml(_kmlSemPoligono);
      final service = DrawingImportService(_FilePicker(file));
      final result = await service.pickAndParse();

      expect(result.cancelled, isFalse);
      expect(result.geometry, isNull);
      expect(result.error, isNotNull);
      expect(result.error, contains('Polygon'));
      expect(result.isSuccess, isFalse);
    });

    test('retorna geometria quando KML válido com ordem [lng,lat]', () async {
      final file = await _tempKml(_kmlComPoligono);
      final service = DrawingImportService(_FilePicker(file));
      final result = await service.pickAndParse();

      expect(result.cancelled, isFalse);
      expect(result.error, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.origin, equals(DrawingOrigin.importacao_kml));
      expect(result.geometry, isA<DrawingPolygon>());

      final polygon = result.geometry! as DrawingPolygon;
      final first = polygon.coordinates.first.first;
      expect(first[0], closeTo(-47.123456, 1e-9)); // lng
      expect(first[1], closeTo(-15.456789, 1e-9)); // lat
    });

    test('aceita KML com BOM UTF-8', () async {
      final file = await _tempKml(_kmlComBOM);
      final service = DrawingImportService(_FilePicker(file));
      final result = await service.pickAndParse();

      expect(result.error, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.geometry, isA<DrawingPolygon>());
    });

    test('retorna geometria quando KMZ válido', () async {
      final file = await _tempKmz(_kmlComPoligono);
      final service = DrawingImportService(_FilePicker(file));
      final result = await service.pickAndParse();

      expect(result.cancelled, isFalse);
      expect(result.error, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.origin, equals(DrawingOrigin.importacao_kmz));
      expect(result.geometry, isA<DrawingPolygon>());
    });

    test('retorna erro explícito quando KMZ não contém KML', () async {
      final dir = await Directory.systemTemp.createTemp('kmz_sem_kml_');
      final file = File('${dir.path}/invalid.kmz');
      final archive = Archive()
        ..addFile(ArchiveFile('readme.txt', 5, utf8.encode('texto')));
      final zipped = ZipEncoder().encode(archive);
      await file.writeAsBytes(zipped, flush: true);

      final picked = PlatformFile(
        name: 'invalid.kmz',
        size: zipped.length,
        path: file.path,
      );
      final service = DrawingImportService(_FilePicker(picked));
      final result = await service.pickAndParse();

      expect(result.geometry, isNull);
      expect(result.error, isNotNull);
      expect(result.error, contains('.kml'));
      expect(result.isSuccess, isFalse);
    });

    test('aceita extensão em maiúsculas (KML)', () async {
      final file = await _tempKml(_kmlComPoligono, fileName: 'TESTE.KML');
      final service = DrawingImportService(_FilePicker(file));
      final result = await service.pickAndParse();

      expect(result.error, isNull);
      expect(result.isSuccess, isTrue);
    });

    test('retorna error (nao lanca excecao) quando picker falha', () async {
      final service = const DrawingImportService(_ThrowingPicker());
      final result = await service.pickAndParse();

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
