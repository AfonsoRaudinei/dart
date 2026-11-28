import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/campo_teste_case_seed.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/presentation/screens/novo_case_sheet.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/fotos_resultado_picker_widget.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/novo_case_publicar_button.dart';

import 'fake_teste_execucao_lookup.dart';

Widget _sheet({
  CampoTesteCaseSeed? campoTeste,
  required void Function(MarketingCase) onPublicar,
}) {
  return ProviderScope(
    overrides: [
      clientLookupProvider.overrideWithValue(_FakeClientLookup()),
      fakeTesteExecucaoLookupOverride,
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 2400)),
        child: Scaffold(
          body: NovoCaseSheet(
            lat: -10.0,
            lng: -48.0,
            tipo: CaseTipo.resultado,
            campoTeste: campoTeste,
            onClose: () {},
            onPublicar: onPublicar,
          ),
        ),
      ),
    ),
  );
}

Future<void> _preencher(WidgetTester tester) async {
  Future<void> digitar(String label, String valor) async {
    final campo = find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(campo);
    await tester.enterText(campo, valor);
  }

  await digitar('Produtor / Fazenda *', 'Produtor A');
  await digitar('Produto Utilizado *', 'Produto X');
  await digitar('Localização (ex: Jataizinho - PR) *', 'Palmas - TO');
  await digitar('Produção Testemunha (sem produto) *', '60');
  await digitar('Produção com Produto *', '68');
  await digitar('Custo do produto (R\$/ha) *', '95');
  await digitar('Valor do grão (R\$/sc) *', '120');
  await tester.pump();
}

Future<void> _publicar(WidgetTester tester) async {
  final botao = find.byType(NovoCasePublicarButton);
  await tester.ensureVisible(botao);
  await tester.pumpAndSettle();
  await tester.tap(botao);
  await tester.pump();
}

void main() {
  testWidgets('Resultado sem foto continua bloqueado ao publicar', (
    tester,
  ) async {
    MarketingCase? publicado;
    await tester.pumpWidget(_sheet(onPublicar: (c) => publicado = c));
    await tester.pumpAndSettle();

    expect(find.byType(FotosResultadoPickerWidget), findsOneWidget);
    expect(find.text('Obrigatória'), findsOneWidget);

    await _preencher(tester);
    await _publicar(tester);

    expect(publicado, isNull);
    expect(
      find.text('Foto principal obrigatória para o tipo Resultado.'),
      findsOneWidget,
    );
  });

  testWidgets('foto do campo de teste vira a 1ª foto e a capa do case', (
    tester,
  ) async {
    MarketingCase? publicado;
    await tester.pumpWidget(
      _sheet(
        campoTeste: const CampoTesteCaseSeed(
          drawingId: 'draw-1',
          nome: 'Teste A',
          areaHa: 2.5,
          photoPath: 'https://cdn.test/campo-teste.jpg',
        ),
        onPublicar: (c) => publicado = c,
      ),
    );
    await tester.pumpAndSettle();

    final picker = tester.widget<FotosResultadoPickerWidget>(
      find.byType(FotosResultadoPickerWidget),
    );
    expect(picker.urls, ['https://cdn.test/campo-teste.jpg']);
    expect(find.text('Obrigatória'), findsNothing);

    await _preencher(tester);
    await _publicar(tester);

    expect(publicado, isNotNull);
    expect(publicado!.tipo, CaseTipo.resultado);
    expect(publicado!.fotoPrincipalUrl, 'https://cdn.test/campo-teste.jpg');
    expect(publicado!.fotosResultado, ['https://cdn.test/campo-teste.jpg']);
    expect(publicado!.drawingId, 'draw-1');
  });

  testWidgets('adicionar fotos pelo picker grava capa = 1ª e a lista', (
    tester,
  ) async {
    MarketingCase? publicado;
    await tester.pumpWidget(
      _sheet(
        campoTeste: const CampoTesteCaseSeed(
          drawingId: 'draw-1',
          nome: 'Teste A',
          areaHa: 2.5,
          photoPath: 'https://cdn.test/1.jpg',
        ),
        onPublicar: (c) => publicado = c,
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<FotosResultadoPickerWidget>(
          find.byType(FotosResultadoPickerWidget),
        )
        .onChanged(['https://cdn.test/1.jpg', 'https://cdn.test/2.jpg']);
    await tester.pump();
    expect(find.text('2/5'), findsOneWidget);

    await _preencher(tester);
    await _publicar(tester);

    expect(publicado, isNotNull);
    expect(publicado!.fotoPrincipalUrl, 'https://cdn.test/1.jpg');
    expect(publicado!.fotosResultado, [
      'https://cdn.test/1.jpg',
      'https://cdn.test/2.jpg',
    ]);
  });
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async => null;

  @override
  Future<List<ClientSummary>> listAtivos() async => const [];
}
