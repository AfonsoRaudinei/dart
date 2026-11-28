import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/marketing_case_repository_impl.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_resultado_fotos.dart';

Map<String, dynamic> _json({Map<String, dynamic> extra = const {}}) => {
  'id': 'case-1',
  'tipo': 'resultado',
  'visibilidade': 'ouro',
  'lat': -10.0,
  'lng': -48.0,
  'localizacao_texto': 'Palmas',
  'produtor_fazenda': 'Produtor',
  'produto_utilizado': 'Produto',
  'criado_em': '2026-11-27T12:00:00.000Z',
  'atualizado_em': '2026-11-27T12:00:00.000Z',
  ...extra,
};

MarketingCase _case({String? capa, List<String> fotos = const []}) =>
    MarketingCase(
      id: 'case-1',
      tipo: CaseTipo.resultado,
      visibilidade: PlanoMarketing.ouro,
      lat: -10,
      lng: -48,
      localizacaoTexto: 'Palmas',
      produtorFazenda: 'Produtor',
      produtoUtilizado: 'Produto',
      fotoPrincipalUrl: capa,
      fotosResultado: fotos,
      criadoEm: DateTime.utc(2026, 11, 27),
      atualizadoEm: DateTime.utc(2026, 11, 27),
    );

void main() {
  group('MarketingCase.fotosResultado (ADR-065)', () {
    test('roundtrip toJson/fromJson preserva a lista e a ordem', () {
      final original = _case(
        capa: 'https://x/1.jpg',
        fotos: ['https://x/1.jpg', 'https://x/2.jpg', 'https://x/3.jpg'],
      );

      final json = original.toJson();
      expect(json['fotos_resultado_json'], isA<String>());
      expect(jsonDecode(json['fotos_resultado_json'] as String), [
        'https://x/1.jpg',
        'https://x/2.jpg',
        'https://x/3.jpg',
      ]);

      final lido = MarketingCase.fromJson(json);
      expect(lido.fotosResultado, original.fotosResultado);
      expect(lido.fotoPrincipalUrl, 'https://x/1.jpg');
      expect(lido.fotosResultadoEfetivas, original.fotosResultado);
    });

    test('toJson não grava a coluna quando a lista é vazia', () {
      expect(
        _case(
          capa: 'https://x/1.jpg',
        ).toJson().containsKey('fotos_resultado_json'),
        isFalse,
      );
    });

    test('legado só com foto_principal_url vira lista efetiva de 1', () {
      final legado = MarketingCase.fromJson(
        _json(extra: {'foto_principal_url': 'https://x/capa.jpg'}),
      );

      expect(legado.fotosResultado, isEmpty);
      expect(legado.fotosResultadoEfetivas, ['https://x/capa.jpg']);
    });

    test('sem nenhuma foto a lista efetiva é vazia', () {
      expect(MarketingCase.fromJson(_json()).fotosResultadoEfetivas, isEmpty);
      expect(
        MarketingCase.fromJson(
          _json(extra: {'foto_principal_url': '  '}),
        ).fotosResultadoEfetivas,
        isEmpty,
      );
    });

    test('aceita String JSON, List e null', () {
      final deString = MarketingCase.fromJson(
        _json(extra: {'fotos_resultado_json': '["https://x/a.jpg"]'}),
      );
      final deLista = MarketingCase.fromJson(
        _json(
          extra: {
            'fotos_resultado_json': ['https://x/b.jpg'],
          },
        ),
      );
      final deNull = MarketingCase.fromJson(
        _json(extra: {'fotos_resultado_json': null}),
      );

      expect(deString.fotosResultado, ['https://x/a.jpg']);
      expect(deLista.fotosResultado, ['https://x/b.jpg']);
      expect(deNull.fotosResultado, isEmpty);
    });

    test('JSON malformado vira lista vazia sem lançar', () {
      for (final raw in <Object>['{nao-json', '"texto"', '{"a":1}', 42, '']) {
        final c = MarketingCase.fromJson(
          _json(
            extra: {
              'foto_principal_url': 'https://x/capa.jpg',
              'fotos_resultado_json': raw,
            },
          ),
        );
        expect(c.fotosResultado, isEmpty, reason: '$raw');
        expect(c.fotosResultadoEfetivas, ['https://x/capa.jpg']);
      }
    });

    test('filtra strings vazias, brancas e não-string', () {
      final c = MarketingCase.fromJson(
        _json(
          extra: {
            'fotos_resultado_json': jsonEncode([
              'https://x/1.jpg',
              '',
              '   ',
              null,
              7,
              ' https://x/2.jpg ',
            ]),
          },
        ),
      );

      expect(c.fotosResultado, ['https://x/1.jpg', 'https://x/2.jpg']);
    });

    test('respeita o limite máximo de fotos', () {
      final muitas = [for (var i = 0; i < 9; i++) 'https://x/$i.jpg'];
      final c = MarketingCase.fromJson(
        _json(extra: {'fotos_resultado_json': jsonEncode(muitas)}),
      );

      expect(kMarketingResultadoFotosMax, 5);
      expect(kMarketingResultadoFotosMin, 1);
      expect(c.fotosResultado, muitas.take(5).toList());
      expect(normalizeFotosResultado(muitas), hasLength(5));
    });

    test('copyWith atualiza e preserva a lista', () {
      final c = _case(fotos: ['https://x/1.jpg']);

      expect(c.copyWith(fotosResultado: ['https://x/2.jpg']).fotosResultado, [
        'https://x/2.jpg',
      ]);
      expect(c.copyWith(produtoUtilizado: 'Outro').fotosResultado, [
        'https://x/1.jpg',
      ]);
    });
  });

  group('MarketingCaseRepositoryImpl (ADR-065)', () {
    test('remoteColumns contém fotos_resultado_json', () {
      expect(
        MarketingCaseRepositoryImpl.remoteColumns,
        contains('fotos_resultado_json'),
      );
    });

    test('toRemoteRow inclui a coluna e a capa legada', () {
      final row = MarketingCaseRepositoryImpl.toRemoteRow(
        _case(
          capa: 'https://x/1.jpg',
          fotos: ['https://x/1.jpg', 'https://x/2.jpg'],
        ),
        userId: 'user-1',
        syncStatus: 'pending_sync',
      );

      expect(row['foto_principal_url'], 'https://x/1.jpg');
      expect(jsonDecode(row['fotos_resultado_json'] as String), [
        'https://x/1.jpg',
        'https://x/2.jpg',
      ]);
    });

    test('toRemoteRow omite a coluna em case legado sem lista', () {
      final row = MarketingCaseRepositoryImpl.toRemoteRow(
        _case(capa: 'https://x/1.jpg'),
        userId: 'user-1',
        syncStatus: 'pending_sync',
      );

      expect(row.containsKey('fotos_resultado_json'), isFalse);
      expect(row['foto_principal_url'], 'https://x/1.jpg');
    });
  });
}
