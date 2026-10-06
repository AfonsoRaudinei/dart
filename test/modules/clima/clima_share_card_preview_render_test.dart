import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/domain/clima_fonte.dart';
import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_share_card.dart';

/// Gera PNGs do card para conferência visual rápida (não roda no CI padrão).
void main() {
  testWidgets('render semanal', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: const Color(0xFF0B1E42),
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: ClimaShareCard(
                payload: ClimaSharePayloadSemanal(
                  cidadeLabel: 'Porto Nacional, TO',
                  fonte: ClimaFonte.googleWeather,
                  previsoes: [
                    for (var i = 0; i < 5; i++)
                      PrevisaoDiaria(
                        data: DateTime(2026, 10, 5).add(Duration(days: i)),
                        tempMin: 23 + i % 3,
                        tempMax: 35 + i % 4,
                        precipitacao: i == 0 ? 1.6 : (i == 3 ? 0.2 : 0),
                        probabilidadeChuva: i == 0 ? 55 : i * 5,
                        ventoMedio: 8 + i.toDouble(),
                        condicao: i.isEven
                            ? 'Predominantemente ensolarado'
                            : 'Parcialmente nublado',
                        condicaoCodigo: i.isEven ? '01d' : '02d',
                        temAlerta: false,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _dump(tester, key, 'clima_card_semanal.png');
  });

  testWidgets('render atual', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: const Color(0xFF0B1E42),
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: ClimaShareCard(
                payload: ClimaSharePayloadAtual(
                  ClimaAtual(
                    temperatura: 33,
                    sensacaoTermica: 36,
                    condicao: 'Nublado',
                    condicaoCodigo: '04d',
                    ventoVelocidade: 12,
                    ventoDirecao: 'SE',
                    umidade: 78,
                    precipitacao: 1.6,
                    pressao: 1012,
                    visibilidade: 12,
                    coberturaNuvens: 80,
                    indiceUV: 6,
                    nascerSol: DateTime(2026, 10, 5, 6),
                    porSol: DateTime(2026, 10, 5, 18, 10),
                    latitude: -10.7,
                    longitude: -48.4,
                    cidade: 'Porto Nacional, TO',
                    atualizadoEm: DateTime(2026, 10, 5, 10),
                    fonte: ClimaFonte.googleWeather,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _dump(tester, key, 'clima_card_atual.png');
  });
}

Future<void> _dump(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('/tmp/clima_preview')..createSync(recursive: true);
    File('${dir.path}/$name').writeAsBytesSync(data!.buffer.asUint8List());
  });
}
