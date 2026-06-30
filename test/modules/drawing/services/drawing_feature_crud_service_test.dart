import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/services/drawing_feature_crud_service.dart';

// Geometria mínima válida (quadrado ~1 km²)
DrawingPolygon _squarePoly() => DrawingPolygon(
      coordinates: [
        [
          [0.0, 0.0],
          [0.01, 0.0],
          [0.01, 0.01],
          [0.0, 0.01],
          [0.0, 0.0],
        ],
      ],
    );

DrawingFeature _baseFeature() {
  const service = DrawingFeatureCrudService();
  return service.buildFeature(
    geometry: _squarePoly(),
    nome: 'Talhão Alfa',
    tipo: DrawingType.talhao,
    origem: DrawingOrigin.desenho_manual,
    autorId: 'user-1',
    autorTipo: AuthorType.consultor,
  );
}

void main() {
  const service = DrawingFeatureCrudService();

  // =========================================================================
  group('buildFeature', () {
    test('cria feature com status rascunho e syncStatus local_only', () {
      final feature = service.buildFeature(
        geometry: _squarePoly(),
        nome: 'Talhão Beta',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        autorId: 'user-1',
        autorTipo: AuthorType.consultor,
      );

      expect(feature.properties.status, equals(DrawingStatus.rascunho));
      expect(feature.properties.syncStatus, equals(SyncStatus.local_only));
      expect(feature.properties.versao, equals(1));
      expect(feature.properties.ativo, isTrue);
    });

    test('gera id unico para cada chamada', () {
      final a = service.buildFeature(
        geometry: _squarePoly(),
        nome: 'A',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        autorId: 'u',
        autorTipo: AuthorType.consultor,
      );
      final b = service.buildFeature(
        geometry: _squarePoly(),
        nome: 'B',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        autorId: 'u',
        autorTipo: AuthorType.consultor,
      );

      expect(a.id, isNot(equals(b.id)));
    });

    test('calcula area maior que zero para geometria valida', () {
      final feature = _baseFeature();
      expect(feature.properties.areaHa, greaterThan(0));
    });

    test('propaga clienteId e fazendaId opcionais', () {
      final feature = service.buildFeature(
        geometry: _squarePoly(),
        nome: 'Safra Soja',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        autorId: 'u',
        autorTipo: AuthorType.consultor,
        clienteId: 'cli-42',
        fazendaId: 'faz-7',
        grupo: 'Soja 2025/26',
        cor: 0xFF00FF00,
      );

      expect(feature.properties.clienteId, equals('cli-42'));
      expect(feature.properties.fazendaId, equals('faz-7'));
      expect(feature.properties.grupo, equals('Soja 2025/26'));
      expect(feature.properties.cor, equals(0xFF00FF00));
    });
  });

  // =========================================================================
  group('buildUpdate — sem mudanca de geometria', () {
    test('atualiza nome e syncStatus para pending_sync', () {
      final old = _baseFeature();
      final (:updated, :deactivated) = service.buildUpdate(old, nome: 'Novo Nome');

      expect(updated.properties.nome, equals('Novo Nome'));
      expect(updated.properties.syncStatus, equals(SyncStatus.pending_sync));
      expect(deactivated, isNull);
    });

    test('preserva id original quando nao ha nova geometria', () {
      final old = _baseFeature();
      final (:updated, :deactivated) = service.buildUpdate(
        old,
        status: DrawingStatus.aprovado,
      );

      expect(updated.id, equals(old.id));
      expect(deactivated, isNull);
    });
  });

  group('buildUpdate — com nova geometria (versionamento)', () {
    test('gera novo id e incrementa versao', () {
      final old = _baseFeature();
      final novaGeo = DrawingPolygon(
        coordinates: [
          [
            [0.0, 0.0],
            [0.02, 0.0],
            [0.02, 0.02],
            [0.0, 0.02],
            [0.0, 0.0],
          ],
        ],
      );

      final (:updated, :deactivated) = service.buildUpdate(
        old,
        newGeometry: novaGeo,
        editorId: 'user-2',
        editorType: AuthorType.consultor,
      );

      expect(updated.id, isNot(equals(old.id)));
      expect(updated.properties.versao, equals(old.properties.versao + 1));
      expect(deactivated, isNotNull);
      expect(deactivated!.id, equals(old.id));
      expect(deactivated.properties.ativo, isFalse);
    });

    test('versaoAnteriorId aponta para id original', () {
      final old = _baseFeature();
      final (:updated, :deactivated) = service.buildUpdate(
        old,
        newGeometry: _squarePoly(),
        editorId: 'u',
        editorType: AuthorType.consultor,
      );

      expect(updated.properties.versaoAnteriorId, equals(old.id));
      expect(deactivated, isNotNull);
    });
  });

  // =========================================================================
  group('applyProperties', () {
    test('altera grupo sem criar nova versao', () {
      final old = _baseFeature();
      final updated = service.applyProperties(old, grupo: 'Milho 2024');

      expect(updated.id, equals(old.id));
      expect(updated.properties.grupo, equals('Milho 2024'));
      expect(updated.properties.versao, equals(old.properties.versao));
    });

    test('altera cor sem alterar geometria', () {
      final old = _baseFeature();
      final updated = service.applyProperties(old, cor: 0xFFFF0000);

      expect(updated.properties.cor, equals(0xFFFF0000));
      expect(updated.geometry, same(old.geometry));
    });
  });
}
