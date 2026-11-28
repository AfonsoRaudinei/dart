import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/roi_bloco.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/produtividade_unidade.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/edit_case_sheet.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/foto_picker_widget.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/fotos_resultado_picker_widget.dart';

void main() {
  group('EditCaseSheet', () {
    testWidgets('não permite trocar tipo e sanitiza campos de avaliação', (
      tester,
    ) async {
      MarketingCase? savedCase;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseAvaliacao(),
            onClose: () {},
            onSalvar: (updatedCase) async {
              savedCase = updatedCase;
            },
          ),
        ),
      );

      expect(find.text('Resultado'), findsNothing);
      expect(find.text('Antes/\nDepois'), findsNothing);
      expect(find.text('Avaliação'), findsWidgets);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Produção ideal'),
        '72,5',
      );
      await tester.ensureVisible(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(savedCase, isNotNull);
      expect(savedCase!.tipo, CaseTipo.avaliacao);
      expect(savedCase!.produtividadeValor, 72.5);
      expect(savedCase!.produtividadeUnidade, ProdutividadeUnidade.scHa);
      expect(savedCase!.fotoPrincipalUrl, isNull);
      expect(savedCase!.fotosResultado, isEmpty);
      expect(savedCase!.fotoAntesUrl, isNull);
      expect(savedCase!.fotoDepoisUrl, isNull);
      expect(savedCase!.parametros, isEmpty);
    });

    testWidgets('exibe seção de fotos para case tipo resultado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto(),
            onClose: () {},
            onSalvar: (_) async {},
          ),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('FOTOS DO RESULTADO'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('FOTOS DO RESULTADO'), findsOneWidget);
      expect(find.byType(FotosResultadoPickerWidget), findsOneWidget);
      expect(find.byType(FotoPickerWidget), findsNothing);
      final picker = tester.widget<FotosResultadoPickerWidget>(
        find.byType(FotosResultadoPickerWidget),
      );
      expect(picker.urls, ['https://example.com/resultado.jpg']);
    });

    testWidgets('hidrata a lista de fotos do case resultado', (tester) async {
      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto().copyWith(
              fotoPrincipalUrl: 'https://example.com/a.jpg',
              fotosResultado: const [
                'https://example.com/a.jpg',
                'https://example.com/b.jpg',
              ],
            ),
            onClose: () {},
            onSalvar: (_) async {},
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.byType(FotosResultadoPickerWidget),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final picker = tester.widget<FotosResultadoPickerWidget>(
        find.byType(FotosResultadoPickerWidget),
      );
      expect(picker.urls, [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
      ]);
      expect(find.text('2/5'), findsOneWidget);
    });

    testWidgets('salva capa = 1ª foto e a lista ao editar case resultado', (
      tester,
    ) async {
      MarketingCase? savedCase;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto(),
            onClose: () {},
            onSalvar: (updatedCase) async {
              savedCase = updatedCase;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byType(FotosResultadoPickerWidget),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final picker = tester.widget<FotosResultadoPickerWidget>(
        find.byType(FotosResultadoPickerWidget),
      );
      picker.onChanged([
        'https://example.com/nova-foto.jpg',
        'https://example.com/resultado.jpg',
      ]);
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(savedCase, isNotNull);
      expect(savedCase!.fotoPrincipalUrl, 'https://example.com/nova-foto.jpg');
      expect(savedCase!.fotosResultado, [
        'https://example.com/nova-foto.jpg',
        'https://example.com/resultado.jpg',
      ]);
    });

    testWidgets('exibe dois pickers de foto para case antes/depois', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseAntesDepois(),
            onClose: () {},
            onSalvar: (_) async {},
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('FOTOS'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('FOTOS'), findsOneWidget);
      expect(find.byType(FotoPickerWidget), findsNWidgets(2));
      expect(find.text('Antes'), findsOneWidget);
      expect(find.text('Depois'), findsOneWidget);
    });

    testWidgets('mantém tipo resultado fixo ao salvar edição', (tester) async {
      MarketingCase? savedCase;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto(),
            onClose: () {},
            onSalvar: (updatedCase) async {
              savedCase = updatedCase;
            },
          ),
        ),
      );

      expect(find.text('Resultado'), findsWidgets);
      expect(find.text('Antes/\nDepois'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(savedCase, isNotNull);
      expect(savedCase!.tipo, CaseTipo.resultado);
      expect(savedCase!.produtorFazenda, 'Produtor A');
      expect(savedCase!.fotoPrincipalUrl, 'https://example.com/resultado.jpg');
      expect(savedCase!.fotosResultado, ['https://example.com/resultado.jpg']);
      expect(savedCase!.prodSemProduto, 60);
      expect(savedCase!.prodComProduto, 68);
    });

    testWidgets('bloqueia salvar resultado sem foto principal', (tester) async {
      var saveCalled = false;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto(),
            onClose: () {},
            onSalvar: (_) async {
              saveCalled = true;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byType(FotosResultadoPickerWidget),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final picker = tester.widget<FotosResultadoPickerWidget>(
        find.byType(FotosResultadoPickerWidget),
      );
      picker.onChanged(const <String>[]);
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(saveCalled, isFalse);
      expect(
        find.text('Foto principal obrigatória para o tipo Resultado.'),
        findsOneWidget,
      );
    });

    testWidgets('bloqueia salvar antes/depois sem nenhuma foto', (
      tester,
    ) async {
      var saveCalled = false;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseAntesDepois(),
            onClose: () {},
            onSalvar: (_) async {
              saveCalled = true;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byType(FotoPickerWidget).first,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final total = tester.widgetList(find.byType(FotoPickerWidget)).length;
      for (var i = 0; i < total; i++) {
        tester
            .widget<FotoPickerWidget>(find.byType(FotoPickerWidget).at(i))
            .onChanged(null);
        await tester.pump();
      }

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(saveCalled, isFalse);
      expect(
        find.text('Adicione pelo menos uma foto na Comparação 1.'),
        findsOneWidget,
      );
    });

    testWidgets('salva antes/depois com só a foto antes', (tester) async {
      MarketingCase? savedCase;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseAntesDepois(fotoDepoisUrl: null),
            onClose: () {},
            onSalvar: (updatedCase) async {
              savedCase = updatedCase;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(savedCase, isNotNull);
      expect(savedCase!.fotoAntesUrl, 'https://example.com/antes.jpg');
      expect(savedCase!.fotoDepoisUrl, isNull);
    });

    testWidgets(
      'trocar a foto antes atualiza o primeiro bloco e mantém o lado C',
      (tester) async {
        MarketingCase? savedCase;
        const ladoC = 'https://example.com/lado-c.jpg';
        const antesNovo = 'https://example.com/antes-novo.jpg';
        final avaliacoesJson = jsonEncode([
          {
            'id': 'av-1',
            'titulo': 'Comparação 1',
            'nome_lado_a': 'Antes',
            'nome_lado_b': 'Depois',
            'nome_lado_c': 'Concorrente',
            'foto_lado_a_path': 'https://example.com/antes.jpg',
            'foto_lado_b_path': 'https://example.com/depois.jpg',
            'foto_lado_c_path': ladoC,
            'observacoes': 'nota do bloco',
            'parametros': [
              {'id': 'p1', 'titulo': 'Vagens', 'testemunha': 10, 'teste': 12},
            ],
          },
          {
            'id': 'av-2',
            'titulo': 'Comparação 2',
            'nome_lado_a': 'A',
            'nome_lado_b': 'B',
            'foto_lado_a_path': 'https://example.com/extra-a.jpg',
          },
        ]);

        await tester.pumpWidget(
          _wrap(
            EditCaseSheet(
              caso: _caseAntesDepois(avaliacoesJson: avaliacoesJson),
              onClose: () {},
              onSalvar: (updatedCase) async {
                savedCase = updatedCase;
              },
            ),
          ),
        );

        await tester.scrollUntilVisible(
          find.byType(FotoPickerWidget).first,
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        tester
            .widgetList<FotoPickerWidget>(find.byType(FotoPickerWidget))
            .first
            .onChanged(antesNovo);
        await tester.pump();

        await tester.scrollUntilVisible(
          find.text('Salvar'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        await tester.tap(find.text('Salvar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(savedCase, isNotNull);
        final raw = jsonDecode(savedCase!.avaliacoesJson!) as List;
        final primeiro = Map<String, dynamic>.from(raw.first as Map);
        final segundo = Map<String, dynamic>.from(raw[1] as Map);
        expect(primeiro['foto_lado_a_path'], antesNovo);
        expect(primeiro['foto_lado_c_path'], ladoC);
        expect(primeiro['nome_lado_c'], 'Concorrente');
        expect(primeiro['observacoes'], 'nota do bloco');
        expect(primeiro['titulo'], 'Comparação 1');
        expect(primeiro['parametros'], hasLength(1));
        expect(segundo['id'], 'av-2');
        expect(segundo['foto_lado_a_path'], 'https://example.com/extra-a.jpg');
        expect(savedCase!.fotoAntesUrl, antesNovo);
      },
    );

    testWidgets(
      'abre com 2 blocos e 3 fotos e ao salvar preserva blocos, rótulos, textos, parâmetros e conclusão',
      (tester) async {
        MarketingCase? savedCase;
        final avaliacoesJson = jsonEncode([
          {
            'id': 'av-1',
            'titulo': 'Comparação 1',
            'nome_lado_a': 'Testemunha',
            'nome_lado_b': 'Com produto',
            'nome_lado_c': 'Concorrente',
            'foto_lado_a_path': 'https://example.com/a1.jpg',
            'foto_lado_b_path': 'https://example.com/b1.jpg',
            'foto_lado_c_path': 'https://example.com/c1.jpg',
            'cultura': 'Soja',
            'observacoes': 'Raiz mais vigorosa',
            'parametros': [
              {'id': 'p1', 'titulo': 'Vagens', 'testemunha': 10, 'teste': 12},
            ],
          },
          {
            'id': 'av-2',
            'titulo': 'Comparação 2',
            'nome_lado_a': 'Faixa norte',
            'nome_lado_b': 'Faixa sul',
            'foto_lado_a_path': 'https://example.com/a2.jpg',
            'foto_lado_b_path': 'https://example.com/b2.jpg',
            'cultura': 'Soja',
            'observacoes': 'Segundo ponto',
            'parametros': [
              {'id': 'p2', 'titulo': 'Altura', 'testemunha': 50, 'teste': 55},
            ],
          },
        ]);

        await tester.pumpWidget(
          _wrap(
            EditCaseSheet(
              caso: _caseAntesDepois(
                avaliacoesJson: avaliacoesJson,
                conclusaoTecnica: 'Produto elevou o vigor.',
              ),
              onClose: () {},
              onSalvar: (updatedCase) async {
                savedCase = updatedCase;
              },
            ),
          ),
        );

        await tester.scrollUntilVisible(
          find.text('Comparação 2'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();

        expect(find.text('Comparação 1'), findsOneWidget);
        expect(find.text('Comparação 2'), findsOneWidget);
        expect(find.byType(FotoPickerWidget), findsNWidgets(5));
        expect(find.text('Testemunha'), findsWidgets);
        expect(find.text('Concorrente'), findsOneWidget);
        expect(find.text('Faixa norte'), findsOneWidget);
        expect(find.text('Raiz mais vigorosa'), findsOneWidget);
        expect(find.text('Segundo ponto'), findsOneWidget);
        expect(find.text('Produto elevou o vigor.'), findsOneWidget);
        expect(find.text('Conclusão técnica'), findsNothing);

        await tester.scrollUntilVisible(
          find.text('Salvar'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        await tester.tap(find.text('Salvar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(savedCase, isNotNull);
        final raw = jsonDecode(savedCase!.avaliacoesJson!) as List;
        expect(raw, hasLength(2));
        final primeiro = Map<String, dynamic>.from(raw[0] as Map);
        final segundo = Map<String, dynamic>.from(raw[1] as Map);
        expect(primeiro['id'], 'av-1');
        expect(primeiro['titulo'], 'Comparação 1');
        expect(primeiro['nome_lado_a'], 'Testemunha');
        expect(primeiro['nome_lado_b'], 'Com produto');
        expect(primeiro['nome_lado_c'], 'Concorrente');
        expect(primeiro['foto_lado_a_path'], 'https://example.com/a1.jpg');
        expect(primeiro['foto_lado_b_path'], 'https://example.com/b1.jpg');
        expect(primeiro['foto_lado_c_path'], 'https://example.com/c1.jpg');
        expect(primeiro['observacoes'], 'Raiz mais vigorosa');
        expect(primeiro['cultura'], 'Soja');
        expect(primeiro['parametros'], hasLength(1));
        expect(segundo['id'], 'av-2');
        expect(segundo['titulo'], 'Comparação 2');
        expect(segundo['nome_lado_a'], 'Faixa norte');
        expect(segundo['nome_lado_b'], 'Faixa sul');
        expect(segundo['nome_lado_c'], isNull);
        expect(segundo['foto_lado_b_path'], 'https://example.com/b2.jpg');
        expect(segundo['observacoes'], 'Segundo ponto');
        expect(segundo['parametros'], hasLength(1));

        expect(savedCase!.conclusaoTecnica, 'Produto elevou o vigor.');
        expect(savedCase!.fotoAntesUrl, 'https://example.com/a1.jpg');
        expect(savedCase!.fotoDepoisUrl, 'https://example.com/b1.jpg');
        expect(savedCase!.parametros, hasLength(1));
        expect(savedCase!.parametros.first.titulo, 'Vagens');
      },
    );

    testWidgets(
      'par legado sem avaliacoes_json vira a Comparação 1 e grava blocos',
      (tester) async {
        MarketingCase? savedCase;

        await tester.pumpWidget(
          _wrap(
            EditCaseSheet(
              caso: _caseAntesDepois(
                parametrosJson: jsonEncode([
                  {
                    'id': 'p1',
                    'titulo': 'Vagens',
                    'testemunha': 10,
                    'teste': 12,
                  },
                ]),
              ),
              onClose: () {},
              onSalvar: (updatedCase) async {
                savedCase = updatedCase;
              },
            ),
          ),
        );

        await tester.scrollUntilVisible(
          find.text('Salvar'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(find.byType(FotoPickerWidget), findsNWidgets(2));
        await tester.tap(find.text('Salvar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(savedCase, isNotNull);
        final raw = jsonDecode(savedCase!.avaliacoesJson!) as List;
        expect(raw, hasLength(1));
        final primeiro = Map<String, dynamic>.from(raw.first as Map);
        expect(primeiro['titulo'], 'Comparação 1');
        expect(primeiro['nome_lado_a'], 'Antes');
        expect(primeiro['nome_lado_b'], 'Depois');
        expect(primeiro['foto_lado_a_path'], 'https://example.com/antes.jpg');
        expect(primeiro['foto_lado_b_path'], 'https://example.com/depois.jpg');
        expect(primeiro['parametros'], hasLength(1));
        expect(savedCase!.fotoAntesUrl, 'https://example.com/antes.jpg');
        expect(savedCase!.parametros, hasLength(1));
      },
    );

    testWidgets(
      'bloco sem foto/parâmetro com legado preenchido hidrata o legado e salva coerente',
      (tester) async {
        MarketingCase? savedCase;
        await tester.pumpWidget(
          _wrap(
            EditCaseSheet(
              caso: _caseAntesDepois(
                avaliacoesJson: jsonEncode([
                  {'id': 'av-1', 'titulo': 'Comparação 1'},
                ]),
                parametrosJson: jsonEncode([
                  {
                    'id': 'p1',
                    'titulo': 'Vagens',
                    'testemunha': 10,
                    'teste': 12,
                  },
                ]),
              ),
              onClose: () {},
              onSalvar: (updatedCase) async {
                savedCase = updatedCase;
              },
            ),
          ),
        );

        await tester.scrollUntilVisible(
          find.text('Salvar'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(find.byType(FotoPickerWidget), findsNWidgets(2));
        await tester.tap(find.text('Salvar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(savedCase, isNotNull);
        final raw = jsonDecode(savedCase!.avaliacoesJson!) as List;
        expect(raw, hasLength(1));
        final primeiro = Map<String, dynamic>.from(raw.first as Map);
        expect(primeiro['id'], 'av-1');
        expect(primeiro['foto_lado_a_path'], 'https://example.com/antes.jpg');
        expect(primeiro['foto_lado_b_path'], 'https://example.com/depois.jpg');
        expect(primeiro['parametros'], hasLength(1));
        expect(savedCase!.fotoAntesUrl, 'https://example.com/antes.jpg');
        expect(savedCase!.parametros, hasLength(1));
      },
    );

    testWidgets(
      'decisão: bloco só com texto + legado hidrata o legado e preserva o texto do mesmo id',
      (tester) async {
        MarketingCase? savedCase;
        await tester.pumpWidget(
          _wrap(
            EditCaseSheet(
              caso: _caseAntesDepois(
                avaliacoesJson: jsonEncode([
                  {
                    'id': 'av-1',
                    'titulo': 'Comparação 1',
                    'observacoes': 'Nota do campo',
                  },
                ]),
              ),
              onClose: () {},
              onSalvar: (updatedCase) async {
                savedCase = updatedCase;
              },
            ),
          ),
        );

        await tester.scrollUntilVisible(
          find.text('Salvar'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(find.text('Nota do campo'), findsOneWidget);
        expect(find.byType(FotoPickerWidget), findsNWidgets(2));
        await tester.tap(find.text('Salvar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final raw = jsonDecode(savedCase!.avaliacoesJson!) as List;
        final primeiro = Map<String, dynamic>.from(raw.first as Map);
        expect(primeiro['id'], 'av-1');
        expect(primeiro['observacoes'], 'Nota do campo');
        expect(primeiro['foto_lado_a_path'], 'https://example.com/antes.jpg');
        expect(savedCase!.fotoAntesUrl, 'https://example.com/antes.jpg');
      },
    );

    testWidgets('editar o texto da Comparação 2 e remover a conclusão', (
      tester,
    ) async {
      MarketingCase? savedCase;
      final avaliacoesJson = jsonEncode([
        {
          'id': 'av-1',
          'titulo': 'Comparação 1',
          'nome_lado_a': 'Antes',
          'nome_lado_b': 'Depois',
          'foto_lado_a_path': 'https://example.com/a1.jpg',
          'foto_lado_b_path': 'https://example.com/b1.jpg',
        },
        {
          'id': 'av-2',
          'titulo': 'Comparação 2',
          'nome_lado_a': 'Antes',
          'nome_lado_b': 'Depois',
          'foto_lado_a_path': 'https://example.com/a2.jpg',
          'observacoes': 'texto velho',
        },
      ]);

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseAntesDepois(
              avaliacoesJson: avaliacoesJson,
              conclusaoTecnica: 'Conclusão antiga',
            ),
            onClose: () {},
            onSalvar: (updatedCase) async {
              savedCase = updatedCase;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('texto velho'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.text('texto velho'), 'texto novo');
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(savedCase, isNotNull);
      final raw = jsonDecode(savedCase!.avaliacoesJson!) as List;
      final segundo = Map<String, dynamic>.from(raw[1] as Map);
      expect(segundo['observacoes'], 'texto novo');
      expect(segundo['nome_lado_b'], 'Depois');
      expect(segundo['foto_lado_b_path'], isNull);
      expect(savedCase!.conclusaoTecnica, 'Conclusão antiga');
    });

    testWidgets(
      'tipo avaliação legado preserva avaliacoes_json e conclusão técnica',
      (tester) async {
        MarketingCase? savedCase;
        final avaliacoesJson = jsonEncode([
          {
            'id': 'av-1',
            'titulo': 'Avaliação 1',
            'nome_lado_a': 'Lado A',
            'nome_lado_b': 'Lado B',
            'nome_lado_c': 'Lado C',
            'foto_lado_a_path': 'https://example.com/a1.jpg',
            'foto_lado_b_path': 'https://example.com/b1.jpg',
            'foto_lado_c_path': 'https://example.com/c1.jpg',
            'observacoes': 'nota',
          },
        ]);

        await tester.pumpWidget(
          _wrap(
            EditCaseSheet(
              caso: _caseAvaliacao().copyWith(
                avaliacoesJson: avaliacoesJson,
                conclusaoTecnica: 'Conclusão da avaliação',
              ),
              onClose: () {},
              onSalvar: (updatedCase) async {
                savedCase = updatedCase;
              },
            ),
          ),
        );

        await tester.ensureVisible(find.text('Salvar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(savedCase, isNotNull);
        expect(savedCase!.avaliacoesJson, avaliacoesJson);
        expect(savedCase!.conclusaoTecnica, 'Conclusão da avaliação');
      },
    );

    testWidgets('mantém sourceCaseId e janela pública ao salvar', (
      tester,
    ) async {
      MarketingCase? savedCase;
      final liberado = DateTime.utc(2026, 9, 1);
      final ate = DateTime.utc(2026, 10, 1);

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto().copyWith(
              sourceCaseId: 'origem-1',
              liberadoEm: liberado,
              publicoAte: ate,
            ),
            onClose: () {},
            onSalvar: (updatedCase) async {
              savedCase = updatedCase;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(savedCase!.sourceCaseId, 'origem-1');
      expect(savedCase!.liberadoEm, liberado);
      expect(savedCase!.publicoAte, ate);
    });

    testWidgets('no fim do scroll o botão Salvar fica acima da área do FAB', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseAntesDepois(),
            onClose: () {},
            onSalvar: (_) async {},
          ),
        ),
      );

      final scroll = find.byType(SingleChildScrollView).first;
      await tester.drag(scroll, const Offset(0, -30000));
      await tester.pump(const Duration(seconds: 1));

      final viewportBottom = tester.getRect(scroll).bottom;
      final salvarBottom = tester.getRect(find.byType(FilledButton)).bottom;
      expect(viewportBottom - salvarBottom, greaterThanOrEqualTo(kFabSafeArea));
    });

    testWidgets('dropdown de unidade não herda fundo branco do tema', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientLookupProvider.overrideWithValue(_FakeClientLookup()),
          ],
          child: MaterialApp(
            theme: ThemeData(
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            home: MediaQuery(
              data: const MediaQueryData(size: Size(800, 1400)),
              child: Scaffold(
                body: EditCaseSheet(
                  caso: _caseResultadoCompleto(),
                  onClose: () {},
                  onSalvar: (_) async {},
                ),
              ),
            ),
          ),
        ),
      );

      final decorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byType(DropdownButtonFormField<ProdutividadeUnidade>),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(decorator.decoration.filled, isFalse);
    });

    testWidgets(
      'com clientId, limpar produtor ao salvar usa fallback do nome do cliente',
      (tester) async {
        MarketingCase? savedCase;

        await tester.pumpWidget(
          _wrap(
            EditCaseSheet(
              caso: _caseResultadoComClienteLegado(),
              onClose: () {},
              onSalvar: (updatedCase) async {
                savedCase = updatedCase;
              },
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final produtorField = find.widgetWithText(
          TextFormField,
          'Produtor / Fazenda',
        );
        await tester.enterText(produtorField, '');
        await tester.pump();

        await tester.scrollUntilVisible(
          find.text('Salvar'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        await tester.tap(find.text('Salvar'));
        await tester.pump();

        expect(savedCase, isNotNull);
        expect(savedCase!.clientId, 'client-1');
        expect(savedCase!.produtorFazenda, 'Cliente Teste');
      },
    );

    testWidgets('mantém loading até o save terminar e mostra erro em falha', (
      tester,
    ) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto(),
            onClose: () {},
            onSalvar: (_) => completer.future,
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('Salvando...'), findsOneWidget);

      completer.completeError(Exception('falha'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('Não foi possível salvar as alterações. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.text('Salvar'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [clientLookupProvider.overrideWithValue(_FakeClientLookup())],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 1400)),
        child: Scaffold(body: child),
      ),
    ),
  );
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async {
    return (await listAtivos()).where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<List<ClientSummary>> listAtivos() async => const [
    ClientSummary(id: 'client-1', name: 'Cliente Teste', active: true),
  ];
}

MarketingCase _caseAvaliacao() {
  final now = DateTime.utc(2026, 9, 9, 12);
  return MarketingCase(
    id: 'case-avaliacao',
    tipo: CaseTipo.avaliacao,
    visibilidade: PlanoMarketing.ouro,
    lat: -12.345,
    lng: -47.89,
    localizacaoTexto: 'São domingos',
    produtorFazenda: 'Afonso',
    produtoUtilizado: 'coach',
    dataCase: now,
    nomeVendedor: 'RAUDINEI',
    telefoneVendedor: '63992418349',
    nomeTalhao: 'São domingos',
    tamanhoHa: 100,
    criadoEm: now,
    atualizadoEm: now,
  );
}

MarketingCase _caseAntesDepois({
  String? fotoAntesUrl = 'https://example.com/antes.jpg',
  String? fotoDepoisUrl = 'https://example.com/depois.jpg',
  String? avaliacoesJson,
  String? parametrosJson,
  String? conclusaoTecnica,
}) {
  final now = DateTime.utc(2026, 8, 15, 12);
  return MarketingCase(
    id: 'case-antes-depois',
    tipo: CaseTipo.antesDepois,
    visibilidade: PlanoMarketing.ouro,
    lat: -12.345,
    lng: -47.89,
    localizacaoTexto: 'Fazenda Sul',
    produtorFazenda: 'Produtor B',
    produtoUtilizado: 'Produto Y',
    dataCase: now,
    fotoAntesUrl: fotoAntesUrl,
    fotoDepoisUrl: fotoDepoisUrl,
    avaliacoesJson: avaliacoesJson,
    parametrosJson: parametrosJson,
    conclusaoTecnica: conclusaoTecnica,
    criadoEm: now,
    atualizadoEm: now,
  );
}

MarketingCase _caseResultadoComClienteLegado() {
  final now = DateTime.utc(2026, 7, 28, 12);
  return MarketingCase(
    id: 'case-resultado-cliente',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.ouro,
    lat: -12.345,
    lng: -47.89,
    localizacaoTexto: 'Fazenda Central',
    produtorFazenda: 'Cliente Teste',
    produtoUtilizado: 'Produto X',
    dataCase: now,
    clientId: 'client-1',
    fotoPrincipalUrl: 'https://example.com/resultado.jpg',
    criadoEm: now,
    atualizadoEm: now,
  );
}

MarketingCase _caseResultadoCompleto() {
  final now = DateTime.utc(2026, 7, 28, 12);
  return MarketingCase(
    id: 'case-resultado',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.ouro,
    lat: -12.345,
    lng: -47.89,
    localizacaoTexto: 'Fazenda Central',
    produtorFazenda: 'Produtor A',
    produtoUtilizado: 'Produto X',
    dataCase: now,
    produtividadeValor: 65,
    fotoPrincipalUrl: 'https://example.com/resultado.jpg',
    prodSemProduto: 60,
    prodComProduto: 68,
    unidadeProdutividade: 'sc/ha',
    custoProdutoPorHa: 95,
    valorGrao: 120,
    parametrosJson: jsonEncode([
      const ParametroComparativo(
        id: 'param-1',
        titulo: 'Número de grãos',
        testemunha: 10,
        teste: 12,
      ).toJson(),
    ]),
    roi: const RoiBloco(investimento: 100, retorno: 200, roiCalculado: 100),
    criadoEm: now,
    atualizadoEm: now,
  );
}
