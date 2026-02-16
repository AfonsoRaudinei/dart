import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/services/geometry_service.dart';

void main() {
  group('GeometryService - Cálculos', () {
    test('calculateArea de polígono simples deve retornar área correta', () {
      // Quadrado ~1km no equador
      final polygon = DrawingPolygon(coordinates: [
        [
          [-47.0, 0.0],
          [-47.0, 0.009],
          [-47.009, 0.009],
          [-47.009, 0.0],
          [-47.0, 0.0],
        ]
      ]);

      final area = GeometryService.calculateArea(polygon);

      // Esperado: ~100 hectares (±5%)
      expect(area, greaterThan(95.0));
      expect(area, lessThan(105.0));
    });

    test('calculateArea de geometria nula deve retornar 0', () {
      final area = GeometryService.calculateArea(null);
      expect(area, equals(0.0));
    });

    test('calculatePerimeter de polígono simples', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [-47.0, 0.0],
          [-47.0, 0.009],
          [-47.009, 0.009],
          [-47.009, 0.0],
          [-47.0, 0.0],
        ]
      ]);

      final perimeter = GeometryService.calculatePerimeter(polygon);

      // Perímetro de quadrado 1km: ~4km (±5%)
      expect(perimeter, greaterThan(3.8));
      expect(perimeter, lessThan(4.2));
    });

    test('calculateSegmentDistances deve retornar distâncias corretas', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [-47.0, 0.0],
          [-47.0, 0.009], // ~1km
          [-47.009, 0.009], // ~1km
          [-47.0, 0.0], // volta
        ]
      ]);

      final segments = GeometryService.calculateSegmentDistances(polygon);

      expect(segments.length, equals(3)); // 4 pontos = 3 segmentos (incluindo fechamento)
      // Cada segmento ~1km (diagonal pode ser ~1.4km)
      for (var segment in segments) {
        expect(segment, greaterThan(0.9));
        expect(segment, lessThan(1.5)); // Diagonal ~√2 km
      }
    });
  });

  group('GeometryService - Validação', () {
    test('validatePolygon deve aceitar triângulo válido', () {
      final triangle = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [0.5, 1.0],
          [0.0, 0.0],
        ]
      ]);

      final result = GeometryService.validatePolygon(triangle);
      expect(result.isValid, isTrue);
    });

    test('validatePolygon deve rejeitar polígono com <3 pontos', () {
      final invalid = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [0.0, 0.0],
        ]
      ]);

      final result = GeometryService.validatePolygon(invalid);
      expect(result.isValid, isFalse);
      expect(result.message, contains('Mínimo 3 pontos'));
    });

    test('validatePolygon deve rejeitar polígono vazio', () {
      final empty = DrawingPolygon(coordinates: []);

      final result = GeometryService.validatePolygon(empty);
      expect(result.isValid, isFalse);
      expect(result.message, contains('sem anéis'));
    });

    test('validatePolygon deve detectar auto-interseção', () {
      // Polígono em formato de "gravata borboleta"
      final selfIntersecting = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [2.0, 2.0],
          [2.0, 0.0],
          [0.0, 2.0],
          [0.0, 0.0],
        ]
      ]);

      final result = GeometryService.validatePolygon(selfIntersecting);
      expect(result.isValid, isFalse);
      expect(result.message, contains('auto-interseção'));
    });
  });

  group('GeometryService - Normalização', () {
    test('normalizePolygon deve fechar anel aberto', () {
      final unclosed = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [0.5, 1.0],
        ]
      ]);

      final normalized = GeometryService.normalizePolygon(unclosed);

      final ring = normalized.coordinates.first;
      expect(ring.length, equals(4)); // 3 pontos + fechamento
      expect(ring.first, equals(ring.last));
    });

    test('normalizePolygon deve remover duplicatas consecutivas', () {
      final withDuplicates = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 0.0], // Duplicata
          [0.5, 1.0],
          [0.0, 0.0],
        ]
      ]);

      final normalized = GeometryService.normalizePolygon(withDuplicates);

      final ring = normalized.coordinates.first;
      expect(ring.length, equals(4)); // Sem duplicata
    });
  });

  group('GeometryService - Operações', () {
    test('isPointInPolygon deve detectar ponto dentro', () {
      final ring = [
        [0.0, 0.0],
        [4.0, 0.0],
        [4.0, 4.0],
        [0.0, 4.0],
        [0.0, 0.0],
      ];

      final inside = GeometryService.isPointInPolygon(
        const LatLng(2.0, 2.0),
        ring,
      );

      expect(inside, isTrue);
    });

    test('isPointInPolygon deve detectar ponto fora', () {
      final ring = [
        [0.0, 0.0],
        [4.0, 0.0],
        [4.0, 4.0],
        [0.0, 4.0],
        [0.0, 0.0],
      ];

      final outside = GeometryService.isPointInPolygon(
        const LatLng(5.0, 5.0),
        ring,
      );

      expect(outside, isFalse);
    });

    test('simplifyPolygon deve reduzir pontos redundantes', () {
      // Linha reta com pontos intermediários desnecessários
      final complex = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [0.25, 0.0],
          [0.5, 0.0],
          [0.75, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
          [0.0, 0.0],
        ]
      ]);

      final simplified = GeometryService.simplifyPolygon(
        complex,
        toleranceMeters: 1.0,
      );

      // Espera-se menos pontos
      expect(
        simplified.coordinates.first.length,
        lessThan(complex.coordinates.first.length),
      );
    });

    test('getVertexCount deve contar vértices corretamente', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [0.5, 1.0],
          [0.0, 0.0],
        ]
      ]);

      final count = GeometryService.getVertexCount(polygon);
      expect(count, equals(4));
    });

    test('getVertexCount de geometria nula deve retornar 0', () {
      final count = GeometryService.getVertexCount(null);
      expect(count, equals(0));
    });
  });

  group('GeometryService - MultiPolygon', () {
    test('calculateArea de MultiPolygon deve somar áreas', () {
      // Dois quadrados de ~1km cada = ~200ha total
      final multiPolygon = DrawingMultiPolygon(coordinates: [
        [
          [
            [-47.0, 0.0],
            [-47.0, 0.009],
            [-47.009, 0.009],
            [-47.009, 0.0],
            [-47.0, 0.0],
          ]
        ],
        [
          [
            [-47.02, 0.0],
            [-47.02, 0.009],
            [-47.029, 0.009],
            [-47.029, 0.0],
            [-47.02, 0.0],
          ]
        ],
      ]);

      final area = GeometryService.calculateArea(multiPolygon);

      // Esperado: ~200 hectares (±10%)
      expect(area, greaterThan(180.0));
      expect(area, lessThan(220.0));
    });
  });
}
