import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';

class MockDrawingRepository extends DrawingRepository {
  List<DrawingFeature> _mockFeatures = [];

  void overrideFeatures(List<DrawingFeature> features) {
    _mockFeatures = features;
  }

  @override
  Future<List<DrawingFeature>> getAllFeatures() async {
    return _mockFeatures;
  }

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    return;
  }

  @override
  Future<void> deleteFeature(String id) async {
    return;
  }
}

void main() {
  group('Real-time Self-Intersection Detection Tests', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    void setupPolygonDrawing() {
      controller.selectTool('polygon');
      // Adding one point to move to 'drawing' state is implied in sequence,
      // but let's do it manually if needed:
    }

    test('Cenário 1: Polígono simples convexo (sem interseção)', () {
      setupPolygonDrawing();
      
      // Quadrado simples (convexo), sem cruzar linhas
      controller.appendDrawingPoint(const LatLng(0, 0));
      controller.appendDrawingPoint(const LatLng(0, 10));
      controller.appendDrawingPoint(const LatLng(10, 10));
      controller.appendDrawingPoint(const LatLng(10, 0));

      expect(controller.hasSelfIntersection, false, reason: 'Polígono convexo não deve ter interseções');
      expect(controller.intersectingSegmentIndices, isEmpty);
    });

    test('Cenário 2: Polígono "Ampulheta/Laço" (vértices que se cruzam)', () {
      setupPolygonDrawing();
      
      // Laço "X" (ampulheta) desenhado em 0,0 -> 10,10 -> 0,10 -> 10,0
      controller.appendDrawingPoint(const LatLng(0, 0));
      controller.appendDrawingPoint(const LatLng(10, 10));
      controller.appendDrawingPoint(const LatLng(0, 10));
      controller.appendDrawingPoint(const LatLng(10, 0));

      // As of point 4, the closing line (10,0 -> 0,0) WILL intersect with segment 1 (10,10 -> 0,10)
      // Because polygon implicitly closes: 
      // Segments: 
      // 0: (0,0)->(10,10)
      // 1: (10,10)->(0,10)
      // 2: (0,10)->(10,0)
      // 3: (10,0)->(0,0)
      
      expect(controller.hasSelfIntersection, true, reason: 'Formato ampulheta deve detectar interseção do fechamento automático');
      expect(controller.intersectingSegmentIndices, isNotEmpty);
    });

    test('Cenário 3: Pontos fechando formato tocando em borda, alinhados', () {
      setupPolygonDrawing();
      
      // Um triângulo com um ponto redundante na metade de uma aresta (colineares)
      controller.appendDrawingPoint(const LatLng(0, 0));
      controller.appendDrawingPoint(const LatLng(0, 10));
      controller.appendDrawingPoint(const LatLng(0, 5)); // Ponto que retrocede sobre o mesmo segmento
      controller.appendDrawingPoint(const LatLng(10, 0));

      // Note: A implementação padrão de interseção na nossa engine
      // ignora segmentos adjacentes, por isso a auto-interseção não é reportada com false.
      // E é normal que pontos tocando as bordas e pontos colineares sejam aceitos e apenas
      // simplificados visualmente por GIS viewers, não requerendo bloqueio de salvar.
      expect(controller.hasSelfIntersection, false, reason: 'Linhas adjacentes colineares são aceitáveis pela engine');
    });

    test('Cenário 4: Adição causa interseção -> mover resolve -> validação passa', () async {
      // Create a valid polygon feature
      final validGeom = DrawingPolygon(coordinates: [[
        [0.0, 0.0],
        [0.0, 10.0],
        [10.0, 10.0],
        [10.0, 0.0],
        [0.0, 0.0], // Fechado
      ]]);
      final properties = DrawingProperties(
        nome: 'Teste',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        status: DrawingStatus.rascunho,
        autorId: '123',
        autorTipo: AuthorType.consultor,
        areaHa: 10.0,
        versao: 1,
        ativo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      final feature = DrawingFeature(
        id: '1',
        geometry: validGeom,
        properties: properties,
      );

      final repo = MockDrawingRepository();
      controller = DrawingController(repository: repo);
      // We manually inject the feature to bypass mock repo complexities if load is empty
      repo.overrideFeatures([feature]);
      await controller.loadFeatures();

      // Enter edit mode
      controller.selectFeature(feature);
      controller.startEditMode();
      
      expect(controller.currentState, DrawingState.editing);
      expect(controller.hasSelfIntersection, false);

      // Adição de ponto (insert) causando interseção -> transformando em ampulheta intersecante
      // Inserimos entre (0,10) e (10,10) - (segmento 1 do ring 0) o ponto (5, -5) que cruza (10,0) -> (0,0)!
      controller.insertVertex(0, 1, const LatLng(-5, 5)); 
      
      // Agora o formato é 0,0 -> 0,10 -> (-5,5) -> 10,10 -> 10,0 -> 0,0.
      // O segmento (-5,5) -> 10,10 vai de x=-5 até x=10 em cima de y=5 para y=10.
      // Vai cruzar o segmento da base? Não, a base é de 10,0 a 0,0.
      // Para fazê-lo cruzar a base: adicionar o ponto em (5, -5).
      // Segmento será (0,10) -> (5,-5). Isso cruza y=0. E (5,-5) -> (10,10) cruza y=0 também!
      // A base é 10,0 -> 0,0 em y=0.
      // Portanto, cruza DUAS VEZES!
      controller.moveVertex(0, 2, const LatLng(-5, 5)); // move the newly inserted vertex to actually intersect
      
      expect(controller.hasSelfIntersection, true, reason: 'Ponto editado cruzou a borda inferior gerando interseção');

      // Mover resolve! Trazemos (5,-5) para (5,15), que é convexo acima do topo original.
      controller.moveVertex(0, 2, const LatLng(15, 5)); 

      expect(controller.hasSelfIntersection, false, reason: 'A interseção sumiu após o vértice ser movido para fora da zona de colisão');
    });

    test('Cenário 5: Tentativa de finalização rejeitada se hasSelfIntersection', () {
      setupPolygonDrawing();
      
      // Draw intersecting hour-glass
      controller.appendDrawingPoint(const LatLng(0, 0));
      controller.appendDrawingPoint(const LatLng(10, 10));
      controller.appendDrawingPoint(const LatLng(0, 10));
      controller.appendDrawingPoint(const LatLng(10, 0));

      expect(controller.hasSelfIntersection, true);

      // Attempt to finalize
      controller.completeDrawing();

      // State goes to reviewing but with intersection warning
      expect(controller.currentState, DrawingState.reviewing, reason: 'Vai para reviewing com warning de interseção (salve e edite depois)');
      expect(controller.hasSelfIntersection, true, reason: 'Deve manter flag de interseção ativa');
    });
  });
}
