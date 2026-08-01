import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';

void main() {
  group('OccurrenceFormData.hasValidMapPin — blindagem anti-GPS', () {
    test('aceita ponto do mapa válido (tap)', () {
      const data = OccurrenceFormData(
        type: 'Média',
        description: 'teste',
        latitude: -15.7801,
        longitude: -47.9292,
      );
      expect(data.hasValidMapPin, isTrue);
    });

    test('rejeita (0,0) — fallback perigoso para GPS', () {
      const data = OccurrenceFormData(
        type: 'Média',
        description: 'teste',
        latitude: 0,
        longitude: 0,
      );
      expect(data.hasValidMapPin, isFalse);
    });

    test('rejeita NaN / infinito', () {
      expect(
        // ignore: prefer_const_constructors
        OccurrenceFormData(
          type: 'Média',
          description: 'teste',
          latitude: double.nan,
          longitude: -47.9,
        ).hasValidMapPin,
        isFalse,
      );
      expect(
        // ignore: prefer_const_constructors
        OccurrenceFormData(
          type: 'Média',
          description: 'teste',
          latitude: -15.7,
          longitude: double.infinity,
        ).hasValidMapPin,
        isFalse,
      );
    });

    test('rejeita fora do range geográfico', () {
      expect(
        const OccurrenceFormData(
          type: 'Média',
          description: 'teste',
          latitude: 91,
          longitude: 0.1,
        ).hasValidMapPin,
        isFalse,
      );
    });
  });

  group('modo=foco query parse', () {
    test('extrai lat/lng para focar pin no mapa', () {
      final uri = Uri.parse('/map?modo=foco&lat=-15.780100&lng=-47.929200');
      expect(uri.queryParameters['modo'], 'foco');
      final lat = double.parse(uri.queryParameters['lat']!);
      final lng = double.parse(uri.queryParameters['lng']!);
      expect(lat, closeTo(-15.7801, 0.00001));
      expect(lng, closeTo(-47.9292, 0.00001));
    });
  });

  group('pin imutável no State (contrato)', () {
    test('coords de abertura prevalecem sobre wipe hipotético 0,0', () {
      const pinned = OccurrenceFormData(
        type: 'Alta',
        description: 'capturado no initState',
        latitude: -15.7801,
        longitude: -47.9292,
      );
      const wipedByRebuild = OccurrenceFormData(
        type: 'Alta',
        description: 'provider null mid-form',
        latitude: 0,
        longitude: 0,
      );
      expect(pinned.hasValidMapPin, isTrue);
      expect(wipedByRebuild.hasValidMapPin, isFalse);
      // O State deve persistir `pinned` e ignorar o wipe do provider.
    });
  });
}
