import 'package:soloforte_app/core/contracts/i_teste_execucao_lookup.dart';
import 'package:soloforte_app/core/contracts/i_teste_execucao_lookup_provider.dart';

/// Lookup vazio para widget tests de [NovoCaseSheet] (Avaliação / Antes-Depois).
class FakeTesteExecucaoLookup implements ITesteExecucaoLookup {
  @override
  Future<List<TesteExecucaoOption>> listByClient({
    required String clientId,
    String? farmId,
  }) async =>
      const [];
}

final fakeTesteExecucaoLookupOverride = iTesteExecucaoLookupProvider
    .overrideWithValue(FakeTesteExecucaoLookup());