import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/clima/domain/clima_fonte.dart';
import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_shared_widgets.dart';

void main() {
  group('ClimaSharePayload', () {
    final clima = ClimaAtual(
      temperatura: 31,
      sensacaoTermica: 33,
      condicao: 'Parcialmente ensolarado',
      condicaoCodigo: '02d',
      ventoVelocidade: 8,
      ventoDirecao: 'NE',
      umidade: 48,
      precipitacao: 0,
      pressao: 1015,
      visibilidade: 16,
      coberturaNuvens: 30,
      indiceUV: 5,
      nascerSol: DateTime(2026, 7, 10, 6, 31),
      porSol: DateTime(2026, 7, 10, 18, 5),
      latitude: -10.18,
      longitude: -48.33,
      cidade: 'Palmas, TO',
      atualizadoEm: DateTime(2026, 7, 10, 10),
      fonte: ClimaFonte.googleWeather,
    );

    test('atual inclui frase curta, sem chuva e fonte', () {
      final payload = ClimaSharePayloadAtual(clima);
      final message = payload.buildWhatsAppMessage();

      expect(message, contains('Palmas, TO'));
      expect(message, contains('31° agora. Parcialmente ensolarado.'));
      expect(message, contains('Umidade 48%'));
      expect(message, contains('Sem chuva'));
      expect(message, contains('SoloForte · Fonte: Google Weather'));
      expect(message, isNot(contains('0.0 mm')));
    });

    test('sem fonte o rodapé não inventa empresa', () {
      final semFonte = ClimaSharePayloadAtual(
        ClimaAtual(
          temperatura: 25,
          sensacaoTermica: 26,
          condicao: 'Ensolarado',
          condicaoCodigo: '01d',
          ventoVelocidade: 5,
          ventoDirecao: 'SO',
          umidade: 61,
          precipitacao: 0,
          pressao: 1012,
          visibilidade: 10,
          coberturaNuvens: 0,
          indiceUV: 0,
          nascerSol: DateTime(2026, 7, 10, 6, 3),
          porSol: DateTime(2026, 7, 10, 18, 10),
          latitude: -10.7,
          longitude: -48.4,
          cidade: 'Porto Nacional, TO',
          atualizadoEm: DateTime(2026, 7, 10, 6),
        ),
      );
      final message = semFonte.buildWhatsAppMessage();
      expect(message, endsWith('SoloForte'));
      expect(message, contains('UV baixo'));
      expect(message, isNot(contains('Fonte:')));
    });

    test('horaria resume no máximo 8 horas', () {
      final payload = ClimaSharePayloadHoraria(
        cidadeLabel: 'Palmas, TO',
        fonte: ClimaFonte.googleWeather,
        previsoes: [
          for (var h = 0; h < 9; h++)
            PrevisaoHoraria(
              hora: DateTime(2026, 7, 10, 10 + h),
              temperatura: 30,
              precipitacao: h == 8 ? 1.2 : 0,
              probabilidadeChuva: 0,
              condicao: 'Parcialmente ensolarado',
              condicaoCodigo: '02d',
            ),
        ],
      );

      final message = payload.buildWhatsAppMessage();
      expect(message, contains('Próximas horas'));
      expect(message, contains('10h 30°'));
      expect(message, contains('17h 30°'));
      expect(message, isNot(contains('18h')));
      expect(message, contains('sem chuva'));
      expect(message, isNot(contains('0.0 mm')));
      expect(message, isNot(contains('1.2 mm')));
    });

    test('semanal resume dias', () {
      final payload = ClimaSharePayloadSemanal(
        cidadeLabel: 'Palmas, TO',
        fonte: ClimaFonte.googleWeather,
        previsoes: [
          PrevisaoDiaria(
            data: DateTime(2026, 7, 10),
            tempMin: 23,
            tempMax: 34,
            precipitacao: 0,
            ventoMedio: 8,
            condicao: 'Predominantemente ensolarado',
            condicaoCodigo: '01d',
            temAlerta: false,
          ),
        ],
      );

      final message = payload.buildWhatsAppMessage();
      expect(message, contains('34°/23°'));
      expect(message, contains('sem chuva'));
      expect(message, isNot(contains('0.0 mm')));
      expect(message, contains('SoloForte · Fonte: Google Weather'));
    });
  });

  group('climaCityMatchKey', () {
    test('ignora UF e maiúsculas', () {
      expect(climaCityMatchKey('Porto Nacional, TO'), 'porto nacional');
      expect(climaCityMatchKey('porto nacional'), 'porto nacional');
      expect(climaCityMatchKey(null), '');
    });
  });

  group('climaPhoneIsValid', () {
    test('aceita telefone com 10+ dígitos', () {
      expect(climaPhoneIsValid('(63) 99999-1234'), isTrue);
    });

    test('rejeita telefone vazio', () {
      expect(climaPhoneIsValid(''), isFalse);
      expect(climaPhoneIsValid(null), isFalse);
    });
  });

  group('ClimaWhatsAppSheet clientes', () {
    testWidgets('lista clientes e desabilita checkbox sem telefone', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(480, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientLookupProvider.overrideWithValue(_FakeClientLookup()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ClimaWhatsAppSheet(
                payload: ClimaSharePayloadAtual(
                  ClimaAtual(
                    temperatura: 31,
                    sensacaoTermica: 33,
                    condicao: 'Ensolarado',
                    condicaoCodigo: '01d',
                    ventoVelocidade: 8,
                    ventoDirecao: 'NE',
                    umidade: 48,
                    precipitacao: 0,
                    pressao: 1015,
                    visibilidade: 16,
                    coberturaNuvens: 0,
                    indiceUV: 5,
                    nascerSol: DateTime(2026, 7, 10, 6, 31),
                    porSol: DateTime(2026, 7, 10, 18, 5),
                    latitude: -10.18,
                    longitude: -48.33,
                    cidade: 'Palmas, TO',
                    atualizadoEm: DateTime(2026, 7, 10, 10),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cliente Com Telefone'), findsOneWidget);
      expect(find.text('Cliente Sem Telefone'), findsOneWidget);
      expect(find.text('Sem telefone cadastrado'), findsOneWidget);
      expect(find.text('Nenhum cliente cadastrado.'), findsNothing);

      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkboxes.length, 2);
      expect(checkboxes.first.onChanged, isNotNull);
      expect(checkboxes.last.onChanged, isNull);
      expect(find.text('Cliente Outra Cidade'), findsNothing);
      expect(find.text('Enviar pelo WhatsApp'), findsNothing);
      expect(find.text('Selecione destinatários'), findsOneWidget);

      final enviar = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(enviar.onPressed, isNull);

      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();
      expect(find.text('Cliente Outra Cidade'), findsOneWidget);

      await tester.tap(find.text('Palmas'));
      await tester.pumpAndSettle();
      expect(find.text('Cliente Outra Cidade'), findsNothing);

      await tester.tap(find.text('Marcar com telefone'));
      await tester.pumpAndSettle();
      expect(find.text('Enviar pelo WhatsApp (1)'), findsOneWidget);
      expect(find.text('Ver card'), findsOneWidget);
    });

    testWidgets('cidade sem cliente mostra estado vazio', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientLookupProvider.overrideWithValue(_FakeClientLookup()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ClimaWhatsAppSheet(
                payload: ClimaSharePayloadAtual(
                  ClimaAtual(
                    temperatura: 25,
                    sensacaoTermica: 26,
                    condicao: 'Ensolarado',
                    condicaoCodigo: '01d',
                    ventoVelocidade: 5,
                    ventoDirecao: 'N',
                    umidade: 61,
                    precipitacao: 0,
                    pressao: 1012,
                    visibilidade: 10,
                    coberturaNuvens: 0,
                    indiceUV: 0,
                    nascerSol: DateTime(2026, 7, 10, 6, 3),
                    porSol: DateTime(2026, 7, 10, 18, 10),
                    latitude: -10.7,
                    longitude: -48.4,
                    cidade: 'Gurupi, TO',
                    atualizadoEm: DateTime(2026, 7, 10, 10),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nenhum cliente em Gurupi.'), findsOneWidget);
      expect(find.text('Cliente Com Telefone'), findsNothing);
    });
  });
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<List<ClientSummary>> listAtivos() async {
    return const [
      ClientSummary(
        id: '1',
        name: 'Cliente Com Telefone',
        phone: '63999991234',
        city: 'Palmas',
        active: true,
      ),
      ClientSummary(
        id: '2',
        name: 'Cliente Sem Telefone',
        phone: '',
        city: 'Palmas, TO',
        active: true,
      ),
      ClientSummary(
        id: '3',
        name: 'Cliente Outra Cidade',
        phone: '63988887777',
        city: 'Porto Nacional',
        active: true,
      ),
    ];
  }

  @override
  Future<ClientSummary?> findById(String id) async => null;
}
