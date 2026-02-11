import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

/// ✅ TESTES UNITÁRIOS - Drawing Models
/// 
/// Valida serialização e deserialização de modelos de desenho.
void main() {
  group('DrawingPolygon', () {
    test('deve criar polígono válido', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
          [0.0, 0.0],
        ]
      ]);

      expect(polygon.type, equals('Polygon'));
      expect(polygon.coordinates.length, equals(1));
      expect(polygon.coordinates.first.length, equals(5));
    });

    test('deve auto-fechar anel aberto', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
        ]
      ]);

      // Auto-close deve ter adicionado o ponto inicial
      final ring = polygon.coordinates.first;
      expect(ring.first[0], equals(ring.last[0]));
      expect(ring.first[1], equals(ring.last[1]));
    });

    test('deve serializar para JSON corretamente', () {
      final polygon = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [0.0, 0.0],
        ]
      ]);

      final json = polygon.toJson();

      expect(json['type'], equals('Polygon'));
      expect(json['coordinates'], isA<List>());
      expect(json['coordinates'][0][0], equals([0.0, 0.0]));
    });

    test('deve deserializar de JSON corretamente', () {
      final json = {
        'type': 'Polygon',
        'coordinates': [
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [0.0, 0.0],
          ]
        ]
      };

      final polygon = DrawingPolygon.fromJson(json);

      expect(polygon.type, equals('Polygon'));
      expect(polygon.coordinates.length, equals(1));
      expect(polygon.coordinates.first.length, equals(4));
    });
  });

  group('DrawingProperties', () {
    test('deve criar propriedades válidas', () {
      final props = DrawingProperties(
        nome: 'Talhão 1',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        status: DrawingStatus.rascunho,
        autorId: 'user-123',
        autorTipo: AuthorType.consultor,
        areaHa: 100.5,
        versao: 1,
        ativo: true,
        createdAt: DateTime(2026, 2, 11),
        updatedAt: DateTime(2026, 2, 11),
      );

      expect(props.nome, equals('Talhão 1'));
      expect(props.tipo, equals(DrawingType.talhao));
      expect(props.areaHa, equals(100.5));
      expect(props.versao, equals(1));
      expect(props.ativo, isTrue);
    });

    test('deve serializar para JSON com todos os campos', () {
      final props = DrawingProperties(
        nome: 'Talhão 1',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        status: DrawingStatus.rascunho,
        autorId: 'user-123',
        autorTipo: AuthorType.consultor,
        clienteId: 'cliente-456',
        fazendaId: 'fazenda-789',
        areaHa: 100.5,
        versao: 1,
        ativo: true,
        createdAt: DateTime(2026, 2, 11),
        updatedAt: DateTime(2026, 2, 11),
      );

      final json = props.toJson();

      expect(json['nome'], equals('Talhão 1'));
      expect(json['tipo'], equals('talhao'));
      expect(json['cliente_id'], equals('cliente-456'));
      expect(json['fazenda_id'], equals('fazenda-789'));
      expect(json['area_ha'], equals(100.5));
      expect(json['versao'], equals(1));
      expect(json['ativo'], isTrue);
    });

    test('deve deserializar de JSON corretamente', () {
      final json = {
        'nome': 'Talhão 1',
        'tipo': 'talhao',
        'origem': 'desenho_manual',
        'status': 'rascunho',
        'autor_id': 'user-123',
        'autor_tipo': 'consultor',
        'cliente_id': 'cliente-456',
        'fazenda_id': 'fazenda-789',
        'area_ha': 100.5,
        'versao': 1,
        'ativo': true,
        'created_at': '2026-02-11T00:00:00.000',
        'updated_at': '2026-02-11T00:00:00.000',
        'sync_status': 'local_only',
      };

      final props = DrawingProperties.fromJson(json);

      expect(props.nome, equals('Talhão 1'));
      expect(props.tipo, equals(DrawingType.talhao));
      expect(props.clienteId, equals('cliente-456'));
      expect(props.fazendaId, equals('fazenda-789'));
      expect(props.areaHa, equals(100.5));
    });

    test('copyWith deve criar cópia com campos modificados', () {
      final original = DrawingProperties(
        nome: 'Talhão 1',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        status: DrawingStatus.rascunho,
        autorId: 'user-123',
        autorTipo: AuthorType.consultor,
        areaHa: 100.5,
        versao: 1,
        ativo: true,
        createdAt: DateTime(2026, 2, 11),
        updatedAt: DateTime(2026, 2, 11),
      );

      final modified = original.copyWith(
        nome: 'Talhão 1 - Modificado',
        status: DrawingStatus.aprovado,
      );

      expect(modified.nome, equals('Talhão 1 - Modificado'));
      expect(modified.status, equals(DrawingStatus.aprovado));
      expect(modified.tipo, equals(original.tipo)); // Não modificado
      expect(modified.areaHa, equals(original.areaHa)); // Não modificado
    });
  });

  group('DrawingFeature', () {
    test('deve criar feature completa', () {
      final geometry = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 0.0],
        ]
      ]);

      final properties = DrawingProperties(
        nome: 'Talhão 1',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        status: DrawingStatus.rascunho,
        autorId: 'user-123',
        autorTipo: AuthorType.consultor,
        areaHa: 100.5,
        versao: 1,
        ativo: true,
        createdAt: DateTime(2026, 2, 11),
        updatedAt: DateTime(2026, 2, 11),
      );

      final feature = DrawingFeature(
        id: 'feature-001',
        geometry: geometry,
        properties: properties,
      );

      expect(feature.type, equals('Feature'));
      expect(feature.id, equals('feature-001'));
      expect(feature.geometry, equals(geometry));
      expect(feature.properties, equals(properties));
    });

    test('deve serializar feature completa para JSON', () {
      final feature = DrawingFeature(
        id: 'feature-001',
        geometry: DrawingPolygon(coordinates: [
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [0.0, 0.0],
          ]
        ]),
        properties: DrawingProperties(
          nome: 'Talhão 1',
          tipo: DrawingType.talhao,
          origem: DrawingOrigin.desenho_manual,
          status: DrawingStatus.rascunho,
          autorId: 'user-123',
          autorTipo: AuthorType.consultor,
          areaHa: 100.5,
          versao: 1,
          ativo: true,
          createdAt: DateTime(2026, 2, 11),
          updatedAt: DateTime(2026, 2, 11),
        ),
      );

      final json = feature.toJson();

      expect(json['type'], equals('Feature'));
      expect(json['id'], equals('feature-001'));
      expect(json['geometry'], isA<Map>());
      expect(json['properties'], isA<Map>());
    });

    test('isPivot deve retornar true para subtipo pivo', () {
      final feature = DrawingFeature(
        id: 'feature-001',
        geometry: DrawingPolygon(coordinates: [
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [0.0, 0.0],
          ]
        ]),
        properties: DrawingProperties(
          nome: 'Pivô 1',
          tipo: DrawingType.talhao,
          origem: DrawingOrigin.desenho_manual,
          status: DrawingStatus.rascunho,
          autorId: 'user-123',
          autorTipo: AuthorType.consultor,
          subtipo: 'pivo',
          areaHa: 50.0,
          versao: 1,
          ativo: true,
          createdAt: DateTime(2026, 2, 11),
          updatedAt: DateTime(2026, 2, 11),
        ),
      );

      expect(feature.isPivot, isTrue);
    });

    test('createNewVersion deve criar versão incrementada', () {
      final original = DrawingFeature(
        id: 'feature-001',
        geometry: DrawingPolygon(coordinates: [
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [0.0, 0.0],
          ]
        ]),
        properties: DrawingProperties(
          nome: 'Talhão 1',
          tipo: DrawingType.talhao,
          origem: DrawingOrigin.desenho_manual,
          status: DrawingStatus.rascunho,
          autorId: 'user-123',
          autorTipo: AuthorType.consultor,
          areaHa: 100.5,
          versao: 1,
          ativo: true,
          createdAt: DateTime(2026, 2, 11),
          updatedAt: DateTime(2026, 2, 11),
        ),
      );

      final newGeometry = DrawingPolygon(coordinates: [
        [
          [0.0, 0.0],
          [2.0, 0.0],
          [2.0, 2.0],
          [0.0, 0.0],
        ]
      ]);

      final newVersion = original.createNewVersion(
        newId: 'feature-002',
        newName: 'Talhão 1 - Editado',
        newGeometry: newGeometry,
        newAreaHa: 150.0,
        authorId: 'user-456',
        authorType: AuthorType.consultor,
      );

      expect(newVersion.id, equals('feature-002'));
      expect(newVersion.properties.nome, equals('Talhão 1 - Editado'));
      expect(newVersion.properties.versao, equals(2)); // Incrementado
      expect(newVersion.properties.versaoAnteriorId, equals('feature-001'));
      expect(newVersion.properties.areaHa, equals(150.0));
    });
  });

  group('Enums', () {
    test('DrawingType deve serializar/deserializar', () {
      expect(DrawingType.talhao.toJson(), equals('talhao'));
      expect(DrawingType.fromJson('talhao'), equals(DrawingType.talhao));
    });

    test('DrawingStatus deve serializar/deserializar', () {
      expect(DrawingStatus.rascunho.toJson(), equals('rascunho'));
      expect(
        DrawingStatus.fromJson('rascunho'),
        equals(DrawingStatus.rascunho),
      );
    });

    test('SyncStatus deve serializar/deserializar', () {
      expect(SyncStatus.local_only.toJson(), equals('local_only'));
      expect(
        SyncStatus.fromJson('local_only'),
        equals(SyncStatus.local_only),
      );
    });
  });
}
