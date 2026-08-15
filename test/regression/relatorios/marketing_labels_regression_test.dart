import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BUG-007 — Relatórios → Marketing: labels Gerado/Gerados não devem voltar
/// no badge de status nem no chip de filtro de cases publicados.
void main() {
  group('BUG-007 marketing_labels_regression', () {
    test('status publicado e chip de filtro usam Marketing (não Gerado/Gerados)', () {
      final source = File(
        'lib/modules/consultoria/relatorios/presentation/relatorios_marketing_reports.dart',
      ).readAsStringSync();

      expect(source.contains("return 'Marketing';"), isTrue);
      expect(source.contains("return 'Não gerado';"), isTrue);
      expect(
        source.contains(
          "_statusChip(context, 'Marketing', _MarketingCaseStatusFilter.published)",
        ),
        isTrue,
      );
      expect(
        source.contains(
          "_statusChip(context, 'Gerados', _MarketingCaseStatusFilter.published)",
        ),
        isFalse,
      );
      expect(source.contains("case 'published':\n      return 'Gerado';"), isFalse);
      expect(source.contains('showPackShare: false'), isTrue);
    });

    test('barra de segmentos exibe Marketing (não Gerados)', () {
      final source = File(
        'lib/modules/consultoria/relatorios/presentation/relatorios_shared_widgets.dart',
      ).readAsStringSync();

      expect(
        source.contains("_seg(context, 'Marketing', _RelatoriosSegment.gerados"),
        isTrue,
      );
      expect(
        source.contains("_seg(context, 'Gerados', _RelatoriosSegment.gerados"),
        isFalse,
      );
    });
  });
}
