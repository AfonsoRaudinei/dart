import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_access_reader_provider.dart';
import 'package:soloforte_app/core/domain/occurrence_recomendacao_ordem.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import '../../domain/occurrence.dart';
import '../../data/occurrence_repository.dart';
import 'package:uuid/uuid.dart';

final occurrenceRepositoryProvider = Provider<OccurrenceRepository>((ref) {
  return OccurrenceRepository();
});

final occurrencesListProvider = FutureProvider.autoDispose<List<Occurrence>>((
  ref,
) async {
  // Troca de conta reexecuta a lista. Sem Supabase (teste) o watch falha e a
  // leitura local segue; no app a sessão sobe e a dependência fica ativa.
  try {
    ref.watch(sessionControllerProvider);
  } catch (_) {}
  final repo = ref.watch(occurrenceRepositoryProvider);
  final activeClientIds = await ref
      .watch(occurrenceAccessReaderProvider)
      .loadActiveClientIds();
  if (activeClientIds.isEmpty) return repo.getAllOccurrences();
  return repo.getAllAuthorizedOccurrences(authorizedClientIds: activeClientIds);
});

// ignore: unused_element
final _occurrencesLogoutInvalidationRegistration = () {
  SessionController.registerLogoutInvalidation(
    key: 'occurrencesListProvider',
    invalidate: (ref) => ref.invalidate(occurrencesListProvider),
  );
  return true;
}();

/// Ocorrência atualizada na lista (evita snapshot stale no detalhe).
Occurrence resolveLiveOccurrence(List<Occurrence>? list, Occurrence seed) {
  if (list == null) return seed;
  for (final item in list) {
    if (item.id == seed.id) return item;
  }
  return seed;
}

/// Ocorrência atual no repositório antes de regravar; [seed] se não encontrada.
///
/// Não usa [occurrencesListProvider]: o detalhe já fechou quando o confirm roda.
Future<Occurrence> loadLiveOccurrence(
  OccurrenceRepository repository,
  Occurrence seed,
) async {
  return await repository.getById(seed.id) ?? seed;
}

const kOccurrenceDeletedMessage = 'Esta ocorrência foi excluída.';

/// Tombstone (soft delete): não pode ser regravada, senão volta ao mapa.
bool isOccurrenceDeleted(Occurrence occurrence) {
  return occurrence.deletedAt != null ||
      SyncStatusContract.normalize(occurrence.syncStatus) ==
          SyncStatusContract.deletedLocal;
}

/// Regrava a partir do registro vivo; `false` sem gravar se foi excluída.
Future<bool> updateLiveOccurrence(
  OccurrenceRepository repository,
  Occurrence seed,
  Occurrence Function(Occurrence live) build,
) async {
  final live = await loadLiveOccurrence(repository, seed);
  if (isOccurrenceDeleted(live)) return false;
  await repository.updateOccurrence(build(live));
  return true;
}

class OccurrenceController {
  final Ref ref;
  final OccurrenceRepository _repository;

  OccurrenceController(this.ref, this._repository);

  Future<String> createOccurrence({
    required String type,
    required String description,
    String? clientId,
    String? photoPath,
    double? lat,
    double? long,
    String? category,
    String? status,
    // v14 — campos agronômicos
    String? cultivar,
    String? dataPlantio,
    String? estadioFenologico,
    String? tipoOcorrencia,
    bool amostraSolo = false,
    String? recomendacoes,
    String? recomendacaoAcao,
    String? recomendacaoDose,
    String? recomendacaoQuando,
    String? metricasJson,
    String? nutrientesJson,
    String? categoriasJson,
    String? notasCategoriasJson,
    String? fotosCategoriasJson,
    String? dataEmergencia,
    double? sementesPorMetro,
    int? estandePlantas,
    String? avaliacaoPlantio,
    String? objetivoPlantio,
    String? dataFimPlantio,
    int? cicloDias,
    String? cultura,
    String? safra,
    String? audioPath,
    int? audioDurationSec,
    String? amostraCodigo,
    String? amostraColetor,
    String? amostraTramite,
    String? amostraLaudoTexto,
    String? fieldId,
  }) async {
    final visitLookup = ref.read(visitSessionLookupProvider);
    final activeSession = await visitLookup.getActiveSession();
    final String? sessionId = activeSession?.isActive == true
        ? activeSession!.id
        : null;
    // Área visitada: client_id só por ação explícita — nunca herda sessão ativa.
    final resolvedClientId = isAreaVisitadaCategory(category)
        ? clientId
        : (clientId ??
              (activeSession?.isActive == true
                  ? activeSession!.producerId
                  : null));

    String? geometry;
    if (lat != null && long != null) {
      geometry = jsonEncode({
        'type': 'Point',
        'coordinates': [long, lat],
      });
    }

    final occurrence = Occurrence(
      id: const Uuid().v4(),
      visitSessionId: sessionId,
      clientId: resolvedClientId,
      type: type,
      description: description,
      photoPath: photoPath,
      lat: lat,
      long: long,
      geometry: geometry,
      createdAt: DateTime.now(),
      category: category,
      status: status ?? 'draft',
      // v14 agronômico
      cultivar: cultivar,
      dataPlantio: dataPlantio,
      estadioFenologico: estadioFenologico,
      tipoOcorrencia: tipoOcorrencia,
      amostraSolo: amostraSolo,
      recomendacaoAcao: OccurrenceRecomendacaoOrdem.normalize(recomendacaoAcao),
      recomendacaoDose: OccurrenceRecomendacaoOrdem.normalize(recomendacaoDose),
      recomendacaoQuando: OccurrenceRecomendacaoOrdem.normalize(
        recomendacaoQuando,
      ),
      recomendacoes: OccurrenceRecomendacaoOrdem.mirrorLegacy(
        acao: recomendacaoAcao,
        dose: recomendacaoDose,
        quando: recomendacaoQuando,
        legacy: recomendacoes,
      ),
      metricasJson: metricasJson,
      nutrientesJson: nutrientesJson,
      categoriasJson: categoriasJson,
      notasCategoriasJson: notasCategoriasJson,
      fotosCategoriasJson: fotosCategoriasJson,
      dataEmergencia: dataEmergencia,
      sementesPorMetro: sementesPorMetro,
      estandePlantas: estandePlantas,
      avaliacaoPlantio: avaliacaoPlantio,
      objetivoPlantio: objetivoPlantio,
      dataFimPlantio: dataFimPlantio,
      cicloDias: cicloDias,
      cultura: _nonEmpty(cultura),
      safra: _nonEmpty(safra),
      audioPath: audioPath,
      audioDurationSec: audioDurationSec,
      amostraCodigo: amostraCodigo,
      amostraColetor: amostraColetor,
      amostraTramite: amostraTramite,
      amostraLaudoTexto: amostraLaudoTexto,
      fieldId: _nonEmpty(fieldId),
    );

    await _repository.saveOccurrence(occurrence);

    ref.invalidate(occurrencesListProvider);
    return occurrence.id;
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

final occurrenceControllerProvider = Provider<OccurrenceController>((ref) {
  return OccurrenceController(ref, ref.watch(occurrenceRepositoryProvider));
});
