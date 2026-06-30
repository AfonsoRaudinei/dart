import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/visit_session_snapshot.dart';
import '../../helpers/consultoria_test_factories.dart';

void main() {
  // =========================================================================
  group('Serialização — toJson / fromJson round-trip', () {
    test('snapshot completo → toJson() → fromJson() → igual ao original', () {
      final original = makeSnapshot(
        sessionId: 'sess-abc',
        clientId: 'cli-abc',
        agronomistId: 'agro-abc',
        farmName: 'Fazenda Round-Trip',
        startedAt: DateTime(2026, 2, 1, 8, 0).toUtc(),
        finishedAt: DateTime(2026, 2, 1, 11, 30).toUtc(),
      );

      final json = original.toJson();
      final restored = VisitSessionSnapshot.fromJson(json);

      expect(restored.sessionId, equals(original.sessionId));
      expect(restored.clientId, equals(original.clientId));
      expect(restored.agronomistId, equals(original.agronomistId));
      expect(restored.farmName, equals(original.farmName));
      expect(restored.startedAt, equals(original.startedAt));
      expect(restored.finishedAt, equals(original.finishedAt));
    });

    test(
      'snapshot com ocorrencias vazias → round-trip preserva lista vazia',
      () {
        final original = makeSnapshot(ocorrencias: const []);

        final restored = VisitSessionSnapshot.fromJson(original.toJson());

        expect(restored.ocorrencias, isEmpty);
      },
    );

    test('snapshot com talhoes vazios → round-trip preserva lista vazia', () {
      final original = makeSnapshot(talhoes: const []);

      final restored = VisitSessionSnapshot.fromJson(original.toJson());

      expect(restored.talhoes, isEmpty);
    });

    test('snapshot com fotos vazias → round-trip preserva lista vazia', () {
      final original = makeSnapshot();

      final restored = VisitSessionSnapshot.fromJson(original.toJson());

      expect(restored.fotos, isEmpty);
    });

    test('datas são preservadas sem perda de precisão', () {
      final preciseStart = DateTime(2026, 2, 15, 7, 30, 45, 123).toUtc();
      final preciseEnd = preciseStart.add(
        const Duration(hours: 2, minutes: 15),
      );
      final original = makeSnapshot(
        startedAt: preciseStart,
        finishedAt: preciseEnd,
      );

      final restored = VisitSessionSnapshot.fromJson(original.toJson());

      expect(
        restored.startedAt.millisecondsSinceEpoch,
        equals(original.startedAt.millisecondsSinceEpoch),
      );
      expect(
        restored.finishedAt.millisecondsSinceEpoch,
        equals(original.finishedAt.millisecondsSinceEpoch),
      );
    });
  });

  // =========================================================================
  group('Imutabilidade — copyWith', () {
    test('copyWith() sem parâmetros → retorna objeto equivalente', () {
      final original = makeSnapshot();

      final copy = original.copyWith();

      expect(copy.sessionId, equals(original.sessionId));
      expect(copy.clientId, equals(original.clientId));
      expect(copy.agronomistId, equals(original.agronomistId));
      expect(copy.farmName, equals(original.farmName));
      expect(copy.startedAt, equals(original.startedAt));
      expect(copy.finishedAt, equals(original.finishedAt));
    });

    test("copyWith(farmName: 'x') → farmName muda, resto preservado", () {
      final original = makeSnapshot(
        sessionId: 'sess-original',
        clientId: 'cli-original',
      );

      final copy = original.copyWith(farmName: 'Nova Fazenda');

      expect(copy.farmName, equals('Nova Fazenda'));
      expect(copy.sessionId, equals('sess-original'));
      expect(copy.clientId, equals('cli-original'));
    });

    test('copyWith(ocorrencias: [...]) → lista nova, resto preservado', () {
      final original = makeSnapshot(sessionId: 'sess-xyz');

      final novaOcorrencia = OcorrenciaSnapshot(
        id: 'ocr-1',
        tipo: 'praga',
        descricao: 'Lagarta-do-cartucho detectada',
        registradaEm: DateTime.now().toUtc(),
      );

      final copy = original.copyWith(ocorrencias: [novaOcorrencia]);

      expect(copy.ocorrencias, hasLength(1));
      expect(copy.ocorrencias.first.id, equals('ocr-1'));
      expect(copy.sessionId, equals('sess-xyz'));
    });

    test('objeto original não é mutado após copyWith', () {
      final original = makeSnapshot(farmName: 'Fazenda Original');

      original.copyWith(farmName: 'Fazenda Alterada');

      // O original não deve ter sido alterado
      expect(original.farmName, equals('Fazenda Original'));
    });
  });

  // =========================================================================
  group('Invariantes', () {
    test('sessionId não vazio no snapshot padrão', () {
      final snapshot = makeSnapshot();

      expect(snapshot.sessionId, isNotEmpty);
    });

    test('finishedAt >= startedAt no snapshot padrão', () {
      final snapshot = makeSnapshot();

      expect(
        snapshot.finishedAt.isAfter(snapshot.startedAt) ||
            snapshot.finishedAt.isAtSameMomentAs(snapshot.startedAt),
        isTrue,
        reason: 'finishedAt deve ser posterior ou igual a startedAt',
      );
    });

    test(
      'snapshot com OcorrenciaSnapshot preserva todos os campos após round-trip',
      () {
        final ocorrencia = OcorrenciaSnapshot(
          id: 'ocr-test',
          tipo: 'doença',
          descricao: 'Ferrugem asiática identificada na lavoura',
          lat: -15.7834,
          lng: -47.9267,
          fotoPath: '/storage/fotos/foto_001.jpg',
          registradaEm: DateTime(2026, 2, 10, 14, 30).toUtc(),
        );

        final snapshot = makeSnapshot(ocorrencias: [ocorrencia]);
        final restored = VisitSessionSnapshot.fromJson(snapshot.toJson());

        final restoredOcr = restored.ocorrencias.first;
        expect(restoredOcr.id, equals('ocr-test'));
        expect(restoredOcr.tipo, equals('doença'));
        expect(
          restoredOcr.descricao,
          equals('Ferrugem asiática identificada na lavoura'),
        );
        expect(restoredOcr.lat, equals(-15.7834));
        expect(restoredOcr.lng, equals(-47.9267));
        expect(restoredOcr.fotoPath, equals('/storage/fotos/foto_001.jpg'));
      },
    );
  });
}
