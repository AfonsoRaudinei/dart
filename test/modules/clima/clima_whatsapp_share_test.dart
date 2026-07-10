import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
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
    );

    test('atual inclui cidade e métricas na mensagem WhatsApp', () {
      final payload = ClimaSharePayloadAtual(clima);
      final message = payload.buildWhatsAppMessage();

      expect(message, contains('Palmas, TO'));
      expect(message, contains('31°C'));
      expect(message, contains('Umidade: 48%'));
    });

    test('horaria resume próximas horas', () {
      final payload = ClimaSharePayloadHoraria(
        cidadeLabel: 'Palmas, TO',
        previsoes: [
          PrevisaoHoraria(
            hora: DateTime(2026, 7, 10, 10),
            temperatura: 30,
            precipitacao: 0,
            probabilidadeChuva: 0,
            condicao: 'Parcialmente ensolarado',
            condicaoCodigo: '02d',
          ),
        ],
      );

      final message = payload.buildWhatsAppMessage();
      expect(message, contains('Próximas 24h'));
      expect(message, contains('10h'));
    });

    test('semanal resume dias', () {
      final payload = ClimaSharePayloadSemanal(
        cidadeLabel: 'Palmas, TO',
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
      expect(message, contains('Previsão semanal'));
      expect(message, contains('34°/23°'));
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
        active: true,
      ),
      ClientSummary(
        id: '2',
        name: 'Cliente Sem Telefone',
        phone: '',
        active: true,
      ),
    ];
  }

  @override
  Future<ClientSummary?> findById(String id) async => null;
}
