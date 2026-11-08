import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/infra/relatorio_visit_ndvi_enrichment.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/visit_session_snapshot.dart';

class _NeverCompletingLookup implements INdviLatestLookup {
  int calls = 0;

  @override
  Future<NdviLatestSummary?> getLatest(String fieldId, {String? imageDate}) {
    calls++;
    return Completer<NdviLatestSummary?>().future;
  }
}

class _ThrowingLookup implements INdviLatestLookup {
  @override
  Future<NdviLatestSummary?> getLatest(String fieldId, {String? imageDate}) {
    throw StateError('ndvi-fetch falhou');
  }
}

const _talhoes = [
  TalhaoVisitado(talhaoId: 't1', nomeTalhao: 'Talhão 1'),
  TalhaoVisitado(talhaoId: 't2', nomeTalhao: 'Talhão 2'),
  TalhaoVisitado(talhaoId: 't3', nomeTalhao: 'Talhão 3'),
];

void _expectNoNdvi(
  List<Map<String, dynamic>> result, [
  List<TalhaoVisitado> talhoes = _talhoes,
]) {
  expect(result, hasLength(talhoes.length));
  for (var i = 0; i < talhoes.length; i++) {
    expect(result[i]['talhaoId'], talhoes[i].talhaoId);
    expect(result[i].containsKey('ndviImageSrc'), isFalse);
    expect(result[i].containsKey('ndviCaption'), isFalse);
  }
}

void main() {
  group('enrichTalhoesWithNdviLookup', () {
    test('lookup que nunca completa respeita o teto global', () async {
      final lookup = _NeverCompletingLookup();
      final talhoes = [
        for (var i = 1; i <= 6; i++)
          TalhaoVisitado(talhaoId: 't$i', nomeTalhao: 'Talhão $i'),
      ];
      final stopwatch = Stopwatch()..start();

      final result = await enrichTalhoesWithNdviLookup(
        lookup,
        talhoes,
        perFieldTimeout: const Duration(milliseconds: 80),
        totalBudget: const Duration(milliseconds: 120),
      );

      stopwatch.stop();
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
      // 2 chamadas esperadas; +1 se o Timer do 2º disparar sub-ms antes do Stopwatch fechar o orçamento.
      expect(lookup.calls, lessThanOrEqualTo(3));
      _expectNoNdvi(result, talhoes);
    });

    test('lookup que lança segue sem imagem', () async {
      final result = await enrichTalhoesWithNdviLookup(
        _ThrowingLookup(),
        _talhoes,
      );

      _expectNoNdvi(result);
    });

    test('lookup null segue sem imagem', () async {
      final result = await enrichTalhoesWithNdviLookup(null, _talhoes);

      _expectNoNdvi(result);
    });
  });
}
