import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/enums/perfil_atendimento_tipo.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/perfil_atendimento_abordagem.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_perfil_abordagem_sheet.dart';

void main() {
  group('abordagemDe', () {
    test('os quatro perfis têm copy de venda preenchida', () {
      for (final tipo in PerfilAtendimentoTipo.values) {
        final abordagem = abordagemDe(tipo);
        expect(abordagem.tipo, tipo);
        expect(abordagem.essencia, isNotEmpty);
        expect(abordagem.resumo, isNotEmpty);
        expect(abordagem.essencia.startsWith(abordagem.resumo), isTrue);
        expect(abordagem.comoVender, isNotEmpty);
        expect(abordagem.scriptAbertura, isNotEmpty);
        expect(abordagem.evite, isNotEmpty);
        expect(abordagem.abordagemIdeal, isNotEmpty);
        expect(abordagem.prova, isNotEmpty);
        expect(abordagem.fechamento, isNotEmpty);
      }
    });

    test('só o analítico tem estrutura da proposta', () {
      expect(
        abordagemDe(PerfilAtendimentoTipo.analitico).estruturaProposta,
        hasLength(10),
      );
      expect(
        abordagemDe(PerfilAtendimentoTipo.pragmatico).estruturaProposta,
        isNull,
      );
      expect(
        abordagemDe(PerfilAtendimentoTipo.afavel).estruturaProposta,
        isNull,
      );
      expect(
        abordagemDe(PerfilAtendimentoTipo.expressivo).estruturaProposta,
        isNull,
      );
    });

    test('fechamento adequado só em afável e expressivo', () {
      expect(
        abordagemDe(PerfilAtendimentoTipo.afavel).fechamentoAdequado,
        isNotNull,
      );
      expect(
        abordagemDe(PerfilAtendimentoTipo.expressivo).fechamentoAdequado,
        isNotNull,
      );
      expect(
        abordagemDe(PerfilAtendimentoTipo.pragmatico).fechamentoAdequado,
        isNull,
      );
      expect(
        abordagemDe(PerfilAtendimentoTipo.analitico).fechamentoAdequado,
        isNull,
      );
    });

    test('frase e passos só nos pares previstos', () {
      expect(
        fraseCombinacao(
          PerfilAtendimentoTipo.afavel,
          PerfilAtendimentoTipo.pragmatico,
        ),
        isNotNull,
      );
      expect(
        fraseCombinacao(
          PerfilAtendimentoTipo.analitico,
          PerfilAtendimentoTipo.afavel,
        ),
        isNotNull,
      );
      expect(
        fraseCombinacao(
          PerfilAtendimentoTipo.pragmatico,
          PerfilAtendimentoTipo.expressivo,
        ),
        isNull,
      );
      expect(
        passosCombinacao(
          PerfilAtendimentoTipo.afavel,
          PerfilAtendimentoTipo.pragmatico,
        ),
        hasLength(6),
      );
      expect(
        passosCombinacao(
          PerfilAtendimentoTipo.analitico,
          PerfilAtendimentoTipo.afavel,
        ),
        isNull,
      );
      expect(
        passosCombinacao(
          PerfilAtendimentoTipo.pragmatico,
          PerfilAtendimentoTipo.expressivo,
        ),
        isNull,
      );
    });

    test('dicas de conversão têm 7 itens', () {
      expect(kDicasConversao, hasLength(7));
      expect(kDicasConversao.every((dica) => dica.isNotEmpty), isTrue);
    });
  });

  testWidgets('sheet do pragmático mostra o script dele', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showClientPerfilAbordagemSheet(
                context: context,
                clientName: 'Ademir Rossato',
                dominante: PerfilAtendimentoTipo.pragmatico,
                secundario: null,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vou ser direto'), findsOneWidget);
    expect(find.textContaining('Antes de falar de preço'), findsNothing);
  });
}
