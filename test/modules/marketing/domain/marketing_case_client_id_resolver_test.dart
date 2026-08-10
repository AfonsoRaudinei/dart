import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_case_client_id_resolver.dart';

void main() {
  const clients = <ClientSummary>[
    ClientSummary(id: 'cli-a', name: 'Produtor A', active: true),
    ClientSummary(id: 'cli-b', name: 'Produtor B', active: true),
  ];

  final farmsByClient = <String, List<FarmSummary>>{
    'cli-a': const [
      FarmSummary(id: 'farm-a1', clientId: 'cli-a', name: 'Fazenda Norte'),
    ],
    'cli-b': const [
      FarmSummary(id: 'farm-b1', clientId: 'cli-b', name: 'Fazenda Sul'),
    ],
  };

  group('MarketingCaseClientIdCoverage', () {
    test('audit calcula percentual', () {
      final coverage = MarketingCaseClientIdCoverage.audit([
        'cli-a',
        null,
        '',
        'cli-b',
      ]);
      expect(coverage.total, 4);
      expect(coverage.withClientId, 2);
      expect(coverage.withoutClientId, 2);
      expect(coverage.percentWithClientId, 50);
    });
  });

  group('resolveMarketingCaseClientId', () {
    test('match por padrao Cliente - Fazenda', () {
      expect(
        resolveMarketingCaseClientId(
          produtorFazenda: 'Produtor A - Fazenda Norte',
          clients: clients,
          farmsByClientId: farmsByClient,
        ),
        'cli-a',
      );
    });

    test('match por nome de cliente unico no label', () {
      expect(
        resolveMarketingCaseClientId(
          produtorFazenda: 'Visita Produtor B',
          clients: clients,
          farmsByClientId: farmsByClient,
        ),
        'cli-b',
      );
    });

    test('match ambiguo retorna null', () {
      expect(
        resolveMarketingCaseClientId(
          produtorFazenda: 'Produtor A e Produtor B',
          clients: clients,
          farmsByClientId: farmsByClient,
        ),
        isNull,
      );
    });

    test('sem match retorna null', () {
      expect(
        resolveMarketingCaseClientId(
          produtorFazenda: 'Texto sem vinculo',
          clients: clients,
          farmsByClientId: farmsByClient,
        ),
        isNull,
      );
    });

    test('match unico por nome de fazenda', () {
      expect(
        resolveMarketingCaseClientId(
          produtorFazenda: 'Case na Fazenda Sul',
          clients: clients,
          farmsByClientId: farmsByClient,
        ),
        'cli-b',
      );
    });

    test('label vazio retorna null', () {
      expect(
        resolveMarketingCaseClientId(
          produtorFazenda: '   ',
          clients: clients,
          farmsByClientId: farmsByClient,
        ),
        isNull,
      );
    });
  });
}
