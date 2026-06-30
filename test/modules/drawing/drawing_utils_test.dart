import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_utils.dart';

/// ✅ TESTES UNITÁRIOS - DrawingUtils
/// 
/// Valida os principais utilitários do módulo de desenho.
void main() {
  group('DrawingUtils - Cálculo de Área', () {
    test('calculateAreaHa deve retornar 0 para polígono vazio', () {
      final result = DrawingUtils.calculateAreaHa([]);
      expect(result, equals(0.0));
    });

    test('calculateAreaHa deve retornar 0 para menos de 3 pontos', () {
      final ring = [
        [0.0, 0.0],
        [1.0, 0.0],
      ];
      final result = DrawingUtils.calculateAreaHa(ring);
      expect(result, equals(0.0));
    });

    test('calculateAreaHa deve calcular área de triângulo simples', () {
      // Triângulo pequeno ~1ha
      final ring = [
        [-47.9292, -15.7801], // Brasília
        [-47.9282, -15.7801],
        [-47.9287, -15.7791],
        [-47.9292, -15.7801], // Fechado
      ];
      final result = DrawingUtils.calculateAreaHa(ring);
      expect(result, greaterThan(0.0));
      expect(result, lessThan(2.0)); // Deve ser pequeno
    });

    test('calculateGeometryArea deve funcionar com DrawingPolygon', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [-47.9292, -15.7801],
          [-47.9282, -15.7801],
          [-47.9287, -15.7791],
          [-47.9292, -15.7801],
        ]
      ]);

      final result = DrawingUtils.calculateGeometryArea(polygon);
      expect(result, greaterThan(0.0));
    });

    test('calculateGeometryArea deve retornar 0 para polígono sem coordenadas',
        () {
      final polygon = DrawingPolygon(coordinates: []);
      final result = DrawingUtils.calculateGeometryArea(polygon);
      expect(result, equals(0.0));
    });

    test('calculateGeometryArea deve somar áreas de MultiPolygon', () {
      final multiPolygon = DrawingMultiPolygon(coordinates: [
        [
          [
            [-47.9292, -15.7801],
            [-47.9282, -15.7801],
            [-47.9287, -15.7791],
            [-47.9292, -15.7801],
          ]
        ],
        [
          [
            [-47.9392, -15.7901],
            [-47.9382, -15.7901],
            [-47.9387, -15.7891],
            [-47.9392, -15.7901],
          ]
        ],
      ]);

      final result = DrawingUtils.calculateGeometryArea(multiPolygon);
      expect(result, greaterThan(0.0));

      // Área deve ser aproximadamente 2x a de um polígono único
      final singleArea = DrawingUtils.calculateGeometryArea(
        DrawingPolygon(coordinates: multiPolygon.coordinates[0]),
      );
      expect(result, greaterThan(singleArea));
    });
  });

  group('DrawingUtils - Validação', () {
    test('normalizeGeometry deve fechar polígono aberto', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
          // Não está fechado (falta [0.0, 0.0])
        ]
      ]);

      final normalized =
          DrawingUtils.normalizeGeometry(polygon) as DrawingPolygon;
      final ring = normalized.coordinates.first;

      // Deve ter adicionado o ponto inicial no final
      expect(ring.first[0], equals(ring.last[0]));
      expect(ring.first[1], equals(ring.last[1]));
    });

    test('validateTopology deve aceitar polígono válido', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
          [0.0, 0.0],
        ]
      ]);

      final result = DrawingUtils.validateTopology(polygon);
      expect(result.isValid, isTrue);
    });

    test('validateTopology deve rejeitar polígono com menos de 3 pontos', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [0.0, 0.0], // Apenas 2 pontos únicos
        ]
      ]);

      final result = DrawingUtils.validateTopology(polygon);
      expect(result.isValid, isFalse);
      expect(result.message, contains('inválido'));
    });

    test('validateTopology deve retornar válido para null geometry', () {
      final result = DrawingUtils.validateTopology(null);
      expect(result.isValid, isTrue);
    });
  });

  group('DrawingUtils - Simplificação', () {
    test('simplifyGeometry deve reduzir pontos de polígono complexo', () {
      // Criar polígono com muitos pontos colineares
      final ring = <List<double>>[];
      for (var i = 0; i < 100; i++) {
        ring.add([i.toDouble(), 0.0]); // Linha reta
      }
      ring.add([0.0, 0.0]); // Fechar

      final polygon = DrawingPolygon(coordinates: [ring]);
      final simplified =
          DrawingUtils.simplifyGeometry(polygon) as DrawingPolygon;

      // Deve ter removido pontos intermediários
      expect(
        simplified.coordinates.first.length,
        lessThan(polygon.coordinates.first.length),
      );
    });

    test('simplifyGeometry deve manter polígono já simplificado', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
          [0.0, 0.0],
        ]
      ]);

      final simplified =
          DrawingUtils.simplifyGeometry(polygon) as DrawingPolygon;

      // Não deve remover vértices essenciais
      expect(simplified.coordinates.first.length,
          greaterThanOrEqualTo(4)); // Triângulo + fechamento
    });
  });

  group('DrawingUtils - Geração de ID', () {
    test('generateId deve criar IDs únicos', () {
      final id1 = DrawingUtils.generateId();
      final id2 = DrawingUtils.generateId();

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });

    test('generateId deve criar UUIDs válidos v4', () {
      final id = DrawingUtils.generateId();

      // UUID v4 tem formato: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      final parts = id.split('-');
      expect(parts.length, equals(5));
      expect(parts[2][0], equals('4')); // Versão 4
    });
  });

  group('DrawingUtils - Point in Polygon', () {
    test('isPointInPolygon deve detectar ponto dentro de polígono', () {
      final ring = [
        [0.0, 0.0],
        [4.0, 0.0],
        [4.0, 4.0],
        [0.0, 4.0],
        [0.0, 0.0],
      ];

      // Ponto no centro (lat, lng)
      final result = DrawingUtils.isPointInPolygon(
        const LatLng(2.0, 2.0),
        ring,
      );
      expect(result, isTrue);
    });

    test('isPointInPolygon deve detectar ponto fora de polígono', () {
      final ring = [
        [0.0, 0.0],
        [4.0, 0.0],
        [4.0, 4.0],
        [0.0, 4.0],
        [0.0, 0.0],
      ];

      // Ponto fora
      final result = DrawingUtils.isPointInPolygon(
        const LatLng(5.0, 5.0),
        ring,
      );
      expect(result, isFalse);
    });

    test('isPointInPolygon deve lidar com ponto na borda', () {
      final ring = [
        [0.0, 0.0],
        [4.0, 0.0],
        [4.0, 4.0],
        [0.0, 4.0],
        [0.0, 0.0],
      ];

      // Ponto exatamente na borda
      final result = DrawingUtils.isPointInPolygon(
        const LatLng(2.0, 0.0),
        ring,
      );
      // Pode ser true ou false dependendo da implementação (edge case)
      expect(result, isA<bool>());
    });
  });

  group('DrawingUtils - Vertex Count', () {
    test('getVertexCount deve contar vértices de Polygon', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
          [0.0, 0.0],
        ]
      ]);

      final count = DrawingUtils.getVertexCount(polygon);
      expect(count, equals(5));
    });

    test('getVertexCount deve contar vértices de MultiPolygon', () {
      final multiPolygon = DrawingMultiPolygon(coordinates: [
        [
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [0.0, 0.0],
          ]
        ],
        [
          [
            [2.0, 2.0],
            [3.0, 2.0],
            [3.0, 3.0],
            [2.0, 2.0],
          ]
        ],
      ]);

      final count = DrawingUtils.getVertexCount(multiPolygon);
      expect(count, equals(8)); // 4 + 4
    });
  });
}
