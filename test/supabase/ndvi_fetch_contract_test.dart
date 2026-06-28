import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final edgeFunction = File(
    'supabase/functions/ndvi-fetch/index.ts',
  ).readAsStringSync();

  test('resposta inclui payload completo de NDVI', () {
    expect(edgeFunction, contains('available_dates'));
    expect(edgeFunction, contains('ndvi_min'));
    expect(edgeFunction, contains('ndvi_max'));
    expect(edgeFunction, contains('ndvi_mean'));
    expect(edgeFunction, contains('is_ndvi'));
    expect(edgeFunction, contains('image_base64'));
  });

  test('Planet fallback e marcado como preview RGB, nao NDVI', () {
    expect(edgeFunction, contains('planet_preview'));
    expect(edgeFunction, contains('is_ndvi: usedSource === "sentinel"'));
    expect(edgeFunction, contains('Fallback: Planet (preview RGB'));
  });

  test('Sentinel permanece fonte primaria com stats dedicados', () {
    expect(edgeFunction, contains('fetchSentinelNdviStats'));
    expect(edgeFunction, contains('NDVI_STATS_SAMPLE_EVALSCRIPT'));
    expect(edgeFunction, contains('SENTINEL_HUB_TOKEN'));
  });

  test('validacao de entrada exige area_id e bbox ou geometry', () {
    expect(
      edgeFunction,
      contains('area_id e bbox ou geometry são obrigatórios'),
    );
    expect(edgeFunction, contains('bboxFromGeometry'));
  });

  test('404 explicito quando nenhuma imagem esta disponivel', () {
    expect(edgeFunction, contains('no_images_available'));
    expect(edgeFunction, contains('status: 404'));
  });
}
