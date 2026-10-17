import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/presentation/relatorios_occurrence_location_resolver.dart';

/// Quadrado lon -48.3..-48.1 / lat -10.3..-10.1 (GeoJSON = [lon, lat]).
final _squareRing = [
  [-48.3, -10.3],
  [-48.1, -10.3],
  [-48.1, -10.1],
  [-48.3, -10.1],
  [-48.3, -10.3],
];

final _holeRing = [
  [-48.22, -10.22],
  [-48.18, -10.22],
  [-48.18, -10.18],
  [-48.22, -10.18],
  [-48.22, -10.22],
];

String _polygon(List<List<List<double>>> rings) =>
    jsonEncode({'type': 'Polygon', 'coordinates': rings});

void main() {
  group('geoJsonContainsPoint', () {
    test('Polygon: dentro e fora', () {
      final geo = _polygon([_squareRing]);
      expect(geoJsonContainsPoint(geo, -10.25, -48.25), isTrue);
      expect(geoJsonContainsPoint(geo, -10.05, -48.25), isFalse);
      expect(geoJsonContainsPoint(geo, -10.25, -48.05), isFalse);
    });

    test('coordenadas são [lon, lat] (não inverte eixos)', () {
      final geo = _polygon([
        [
          [10.0, 50.0],
          [11.0, 50.0],
          [11.0, 51.0],
          [10.0, 51.0],
          [10.0, 50.0],
        ],
      ]);
      expect(geoJsonContainsPoint(geo, 50.5, 10.5), isTrue);
      expect(geoJsonContainsPoint(geo, 10.5, 50.5), isFalse);
    });

    test('Polygon com furo exclui ponto no furo', () {
      final geo = _polygon([_squareRing, _holeRing]);
      expect(geoJsonContainsPoint(geo, -10.20, -48.20), isFalse);
      expect(geoJsonContainsPoint(geo, -10.28, -48.28), isTrue);
    });

    test('MultiPolygon: qualquer polígono contém', () {
      final geo = jsonEncode({
        'type': 'MultiPolygon',
        'coordinates': [
          [
            [
              [0.0, 0.5],
              [1.0, 0.5],
              [1.0, 1.0],
              [0.0, 1.0],
              [0.0, 0.5],
            ],
          ],
          [_squareRing],
        ],
      });
      expect(geoJsonContainsPoint(geo, -10.2, -48.2), isTrue);
      expect(geoJsonContainsPoint(geo, 0.7, 0.5), isTrue);
      expect(geoJsonContainsPoint(geo, 5, 5), isFalse);
    });

    test('Feature envolvendo geometry', () {
      final geo = jsonEncode({
        'type': 'Feature',
        'properties': {'nome': 'T1'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [_squareRing],
        },
      });
      expect(geoJsonContainsPoint(geo, -10.2, -48.2), isTrue);
    });

    test('ponto inválido ou geometria inválida retornam false', () {
      final geo = _polygon([_squareRing]);
      expect(geoJsonContainsPoint(geo, 0, 0), isFalse);
      expect(geoJsonContainsPoint(geo, double.nan, -48.2), isFalse);
      expect(geoJsonContainsPoint(null, -10.2, -48.2), isFalse);
      expect(geoJsonContainsPoint('não é json', -10.2, -48.2), isFalse);
      expect(
        geoJsonContainsPoint(
          jsonEncode({
            'type': 'Point',
            'coordinates': [-48.2, -10.2],
          }),
          -10.2,
          -48.2,
        ),
        isFalse,
      );
    });
  });

  test('fieldContainsPoint respeita pré-filtro bbox', () {
    final field = FieldSummary(
      id: 'f1',
      name: 'T1',
      farmId: 'farm-1',
      bbox: const [0, 0, 1, 1],
      geometry: _polygon([_squareRing]),
    );
    expect(fieldContainsPoint(field, -10.2, -48.2), isFalse);
  });

  group('resolveOccurrenceLocationNames', () {
    final farms = _FakeFarmLookup([
      const FarmSummary(id: 'farm-1', clientId: 'cli-1', name: 'Fazenda Sul'),
      const FarmSummary(id: 'farm-2', clientId: 'cli-1', name: 'Fazenda Norte'),
    ]);
    final fields = _FakeFieldLookup([
      FieldSummary(
        id: 'field-1',
        name: 'Talhão Sul',
        farmId: 'farm-1',
        geometry: _polygon([
          [
            [0.0, 0.5],
            [1.0, 0.5],
            [1.0, 1.0],
            [0.0, 1.0],
            [0.0, 0.5],
          ],
        ]),
      ),
      FieldSummary(
        id: 'field-2',
        name: 'Talhão 7',
        farmId: 'farm-2',
        geometry: _polygon([_squareRing]),
      ),
    ]);

    test('resolve fazenda e talhão pela posição', () async {
      final names = await resolveOccurrenceLocationNames(
        clientId: 'cli-1',
        lat: -10.2,
        lng: -48.2,
        visitSessionId: null,
        farmLookup: farms,
        fieldLookup: fields,
      );
      expect(names.fazenda, 'Fazenda Norte');
      expect(names.talhao, 'Talhão 7');
    });

    test('sem match por posição usa a sessão de visita', () async {
      final names = await resolveOccurrenceLocationNames(
        clientId: 'cli-1',
        lat: 5,
        lng: 5,
        visitSessionId: 'sess-1',
        farmLookup: farms,
        fieldLookup: fields,
        visitSessionLookup: _FakeVisitSessionLookup(
          VisitSessionSummary(
            id: 'sess-1',
            producerId: 'cli-1',
            status: 'finished',
            startTime: DateTime.utc(2026, 6, 1),
            areaId: 'field-1',
          ),
        ),
      );
      expect(names.talhao, 'Talhão Sul');
      expect(names.fazenda, 'Fazenda Sul');
    });

    test('lookups ausentes ou com erro retornam vazio', () async {
      final semLookups = await resolveOccurrenceLocationNames(
        clientId: 'cli-1',
        lat: -10.2,
        lng: -48.2,
        visitSessionId: 'sess-1',
      );
      expect(semLookups.fazenda, isEmpty);
      expect(semLookups.talhao, isEmpty);

      final comErro = await resolveOccurrenceLocationNames(
        clientId: 'cli-1',
        lat: -10.2,
        lng: -48.2,
        visitSessionId: 'sess-1',
        farmLookup: _ThrowingFarmLookup(),
        fieldLookup: fields,
        visitSessionLookup: _FakeVisitSessionLookup(null),
      );
      expect(comErro.fazenda, isEmpty);
      expect(comErro.talhao, isEmpty);
    });

    test('lat/long 0/0 não tenta resolver por posição', () async {
      final names = await resolveOccurrenceLocationNames(
        clientId: 'cli-1',
        lat: 0,
        lng: 0,
        visitSessionId: null,
        farmLookup: farms,
        fieldLookup: fields,
      );
      expect(names.fazenda, isEmpty);
      expect(names.talhao, isEmpty);
    });
  });
}

class _FakeFarmLookup implements IFarmLookup {
  _FakeFarmLookup(this.farms);

  final List<FarmSummary> farms;

  @override
  Future<List<FarmSummary>> getFarmsByClient(String clientId) async =>
      farms.where((farm) => farm.clientId == clientId).toList();

  @override
  Future<FarmSummary?> findById(String farmId) async {
    for (final farm in farms) {
      if (farm.id == farmId) return farm;
    }
    return null;
  }

  @override
  Future<void> saveFarm({
    required String clientId,
    required String farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) async {}
}

class _ThrowingFarmLookup extends _FakeFarmLookup {
  _ThrowingFarmLookup() : super(const []);

  @override
  Future<List<FarmSummary>> getFarmsByClient(String clientId) =>
      throw StateError('indisponível');
}

class _FakeFieldLookup implements IFieldLookup {
  _FakeFieldLookup(this.fields);

  final List<FieldSummary> fields;

  @override
  Future<FieldSummary?> findById(String fieldId) async {
    for (final field in fields) {
      if (field.id == fieldId) return field;
    }
    return null;
  }

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async =>
      fields.where((field) => field.farmId == farmId).toList();

  @override
  Future<List<FieldSummary>> listAll() async => fields;
}

class _FakeVisitSessionLookup implements IVisitSessionLookup {
  _FakeVisitSessionLookup(this.session);

  final VisitSessionSummary? session;

  @override
  Future<VisitSessionSummary?> getActiveSession() async => null;

  @override
  Future<VisitSessionSummary?> findById(String sessionId) async =>
      session?.id == sessionId ? session : null;
}
