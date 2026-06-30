import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/visita_html_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test(
    'renderiza relatório grande com ocorrências e fotos em tempo mensurável',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'large_report_render_',
      );
      try {
        final photoPaths = await _createSamplePhotos(tempDir, count: 8);
        final relatorio = _largeReport(photoPaths: photoPaths);

        final stopwatch = Stopwatch()..start();
        final html = await VisitaHtmlRenderer.render(
          relatorio: relatorio,
          agronomistNome: 'Agronomo Performance',
          clienteNome: 'Cliente Performance',
          publicacoesTitulos: const {
            'pub-1': 'Manejo integrado de pragas',
            'pub-2': 'Boletim de ferrugem asiatica',
          },
        );
        stopwatch.stop();

        final elapsedMs = stopwatch.elapsedMilliseconds;
        final sizeKb = (html.length / 1024).round();
        // ignore: avoid_print
        print('large_report_render_ms=$elapsedMs html_size_kb=$sizeKb');

        expect(html, isNotEmpty);
        expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
        expect(html, contains('Ocorrência 119'));
        expect(html, contains('Talhao 24'));
        expect(html, contains('data:image/jpeg;base64,'));

        // Limite pragmático para CI local: falha apenas se houver regressão séria.
        expect(
          elapsedMs,
          lessThan(5000),
          reason: 'Renderização grande ficou lenta demais para uso interativo.',
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    },
  );
}

Future<List<String>> _createSamplePhotos(
  Directory dir, {
  required int count,
}) async {
  final paths = <String>[];
  for (var i = 0; i < count; i++) {
    final image = img.Image(width: 1800, height: 1200);
    final base = img.ColorRgb8(40 + i * 12, 120, 80 + i * 8);
    img.fill(image, color: base);
    img.drawString(
      image,
      'Foto $i',
      font: img.arial48,
      x: 80,
      y: 80,
      color: img.ColorRgb8(255, 255, 255),
    );
    final file = File('${dir.path}/foto_$i.jpg');
    await file.writeAsBytes(img.encodeJpg(image, quality: 92), flush: true);
    paths.add(file.path);
  }
  return paths;
}

Map<String, dynamic> _largeReport({required List<String> photoPaths}) {
  final now = DateTime.utc(2026, 6, 4, 12);
  return {
    'id': 'rel-large-1',
    'status': 'pendente_revisao',
    'title': 'Relatorio grande de performance',
    'farmName': 'Fazenda Performance',
    'periodStart': now.subtract(const Duration(hours: 6)).toIso8601String(),
    'periodEnd': now.toIso8601String(),
    'customNotes': 'Relatorio sintetico para medir renderizacao HTML.',
    'ocorrencias': List.generate(120, (index) {
      return {
        'id': 'occ-$index',
        'tipo': index.isEven ? 'Insetos' : 'Doenca',
        'descricao': 'Ocorrência $index com descrição agronômica detalhada.',
        'lat': -10.0 - index / 1000,
        'lng': -48.0 - index / 1000,
        'fotoPath': index < photoPaths.length ? photoPaths[index] : null,
        'registradaEm': now
            .subtract(Duration(minutes: index * 3))
            .toIso8601String(),
      };
    }),
    'talhoes': List.generate(25, (index) {
      return {
        'talhaoId': 'talhao-$index',
        'nomeTalhao': 'Talhao $index',
        'areaHectares': 10.0 + index,
        'cultura': index.isEven ? 'Soja' : 'Milho',
        'safra': '2025/26',
      };
    }),
    'monitoramentos': List.generate(40, (index) {
      return {
        'id': 'mon-$index',
        'tipo': index.isEven ? 'Fenologia' : 'MIP',
        'dados': {
          'estadio': 'V${index % 8}',
          'pressao': index % 4,
          'observacao': 'Monitoramento $index',
        },
        'coletadoEm': now
            .subtract(Duration(minutes: index * 5))
            .toIso8601String(),
      };
    }),
    'fotos': photoPaths,
    'publicacoesRefs': const ['pub-1', 'pub-2'],
  };
}
