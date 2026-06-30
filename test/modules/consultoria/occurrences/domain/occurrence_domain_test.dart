import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';

void main() {
  group('OccurrenceCategory.fromString', () {
    test('normaliza aliases legados', () {
      expect(
        OccurrenceCategory.fromString('pragas'),
        OccurrenceCategory.insetos,
      );
      expect(
        OccurrenceCategory.fromString('amostra de solo'),
        OccurrenceCategory.amostraSolo,
      );
      expect(
        OccurrenceCategory.fromString('desconhecido'),
        OccurrenceCategory.doenca,
      );
    });
  });

  group('Occurrence.fromMap / getCoordinates', () {
    final createdAt = DateTime.utc(2026, 3, 21);

    test('amostra_solo true quando category indica amostra sem flag DB', () {
      final occurrence = Occurrence.fromMap({
        'id': 'occ-1',
        'type': 'point',
        'description': 'Solo',
        'created_at': createdAt.toIso8601String(),
        'category': 'amostra_solo',
        'amostra_solo': 0,
      });

      expect(occurrence.amostraSolo, isTrue);
    });

    test('getCoordinates prioriza lat/long e rejeita (0,0)', () {
      final withLatLong = Occurrence(
        id: 'occ-2',
        type: 'point',
        description: 'Praga',
        lat: -15.0,
        long: -47.0,
        createdAt: createdAt,
      );
      final zeroCoords = Occurrence(
        id: 'occ-3',
        type: 'point',
        description: 'Invalido',
        lat: 0,
        long: 0,
        createdAt: createdAt,
      );

      expect(withLatLong.getCoordinates(), {'lat': -15.0, 'long': -47.0});
      expect(zeroCoords.getCoordinates(), isNull);
    });

    test('getCoordinates extrai GeoJSON Point quando lat/long ausentes', () {
      final geometry = jsonEncode({
        'type': 'Point',
        'coordinates': [-47.5, -15.5],
      });
      final occurrence = Occurrence(
        id: 'occ-4',
        type: 'point',
        description: 'Geo',
        geometry: geometry,
        createdAt: createdAt,
      );

      expect(
        occurrence.getCoordinates(),
        {'lat': -15.5, 'long': -47.5},
      );
    });

    test('toMap força amostra_solo=1 quando category indica amostra', () {
      final occurrence = Occurrence(
        id: 'occ-5',
        type: 'point',
        description: 'Solo',
        category: 'amostra de solo',
        amostraSolo: false,
        createdAt: createdAt,
      );

      expect(occurrence.toMap()['amostra_solo'], 1);
    });
  });
}
