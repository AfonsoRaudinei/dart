import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/contracts/i_farm_lookup_provider.dart';
import '../../../../core/contracts/i_field_lookup_provider.dart';
import '../../../../core/contracts/i_occurrence_access_reader_provider.dart';
import '../../../../core/contracts/i_visit_session_lookup_provider.dart';
import '../../../../core/html_templates/ocorrencia_html_renderer.dart';
import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../../../core/contracts/i_field_lookup.dart';
import '../../occurrences/domain/occurrence.dart';
import '../../occurrences/domain/occurrence_amostra_solo.dart';
import '../../occurrences/domain/occurrence_historico_talhao.dart';
import '../../occurrences/domain/occurrence_soy_age.dart' as soy_age;
import '../../occurrences/domain/occurrence_photo_paths.dart';
import '../../occurrences/presentation/controllers/occurrence_controller.dart';
import '../../../../core/domain/soy_phenology.dart';
import '../../relatorio_visita/data/image_storage_service.dart';
import '../presentation/relatorios_occurrence_location_resolver.dart';
import 'relatorio_visit_html_builder.dart';

T? _tryReadContract<T>(T Function() read) {
  try {
    return read();
  } catch (_) {
    return null;
  }
}

Future<String> _resolveClienteNome(
  IClientLookup lookup,
  String clientId,
) async {
  try {
    final client = await lookup.findById(clientId);
    final name = client?.name.trim();
    if (name != null && name.isNotEmpty) return name;
  } catch (_) {
    // Lookup indisponível em testes sem override.
  }
  return clientId;
}

/// Vazio quando o nome não resolve — o HTML não exibe o UUID cru.
Future<String> _occurrenceClienteNome(WidgetRef ref, String? clientId) async {
  final id = clientId?.trim() ?? '';
  if (id.isEmpty) return '';
  final lookup = _tryReadContract(() => ref.read(clientLookupProvider));
  if (lookup != null) {
    final name = await _resolveClienteNome(lookup, id);
    if (name.isNotEmpty && name != id) return name;
  }
  final linked = await ref.read(linkedClientNamesProvider.future);
  return linked[id]?.trim() ?? '';
}

Future<String> _historicoTalhaoLinha(
  WidgetRef ref,
  Occurrence occurrence,
) async {
  try {
    if (isHistoricoExcludedOccurrence(occurrence)) return '';
    if (occurrencePragaKey(occurrence) == null) return '';
    final clientId = occurrence.clientId?.trim() ?? '';
    if (clientId.isEmpty) return '';

    final fieldLookup = _tryReadContract(() => ref.read(iFieldLookupProvider));
    var fieldId = occurrence.fieldId?.trim() ?? '';
    if (fieldId.isEmpty) {
      fieldId =
          (await resolveFieldIdForOccurrence(
            clientId: occurrence.clientId,
            lat: occurrence.lat,
            lng: occurrence.long,
            visitSessionId: occurrence.visitSessionId,
            farmLookup: _tryReadContract(() => ref.read(iFarmLookupProvider)),
            fieldLookup: fieldLookup,
          ))?.trim() ??
          '';
    }
    if (fieldId.isEmpty) return '';

    final repo = _tryReadContract(() => ref.read(occurrenceRepositoryProvider));
    if (repo == null) return '';
    final rows = await repo.getOccurrencesByClientId(clientId);
    return buildOccurrenceHistoricoTalhaoLinha(
          current: occurrence,
          candidates: rows,
          fieldId: fieldId,
          field: await _fieldForHistorico(fieldLookup, fieldId),
        ) ??
        '';
  } catch (_) {
    return '';
  }
}

Future<FieldSummary?> _fieldForHistorico(
  IFieldLookup? fieldLookup,
  String fieldId,
) async {
  if (fieldLookup == null) return null;
  try {
    return await fieldLookup.findById(fieldId);
  } catch (_) {
    return null;
  }
}

EstadioData? _findEstadio(String? code) {
  final value = code?.trim() ?? '';
  if (value.isEmpty) return null;
  for (final estadio in kEstadios) {
    if (estadio.code == value) return estadio;
  }
  return null;
}

Future<String> buildOccurrenceReportHtml(
  WidgetRef ref,
  Occurrence occurrence, {
  bool asFragment = false,
}) async {
  final data = occurrence.toMap();
  final cover = coverPhotoPath(occurrence);
  data['foto_base64'] =
      await RelatorioHtmlRenderer.photoPathToBase64(cover) ?? '';
  if (occurrence.fotosCategoriasJson != null) {
    data['fotos_categorias_json'] = encodeFotosCategoriasJson(
      occurrence.fotosCategoriasJson,
      ImageStorageService().toStoredPath,
    );
  }
  if (cover != null) {
    data['photo_path'] = ImageStorageService().toStoredPath(cover);
  }
  data['audio_base64'] =
      await RelatorioHtmlRenderer.audioPathToBase64(occurrence.audioPath) ?? '';
  final audioSec = occurrence.audioDurationSec;
  if (audioSec != null && audioSec > 0) {
    data['audio_duration_label'] = 'Duração: ${audioSec}s';
  }
  data['cliente_nome'] = await _occurrenceClienteNome(ref, occurrence.clientId);
  final location = await resolveOccurrenceLocationNames(
    clientId: occurrence.clientId,
    lat: occurrence.lat,
    lng: occurrence.long,
    visitSessionId: occurrence.visitSessionId,
    farmLookup: _tryReadContract(() => ref.read(iFarmLookupProvider)),
    fieldLookup: _tryReadContract(() => ref.read(iFieldLookupProvider)),
    visitSessionLookup: _tryReadContract(
      () => ref.read(visitSessionLookupProvider),
    ),
  );
  data['fazenda_nome'] = location.fazenda;
  data['talhao_nome'] = location.talhao;
  data['historico_talhao_linha'] = await _historicoTalhaoLinha(ref, occurrence);
  final estadio = _findEstadio(occurrence.estadioFenologico);
  final estadioDisplay = soy_age.occurrenceEstadioDisplay(
    occurrence,
    estadioLabel: estadio?.name,
  );
  if (estadio != null) {
    data['estadio_atencao'] = estadio.attention;
  }
  if (estadioDisplay.isNotEmpty) {
    data['estadio_fenologico'] = estadioDisplay;
    data['estadio_fenologico_label'] = estadioDisplay;
  }
  if (occurrenceIsAmostraSolo(occurrence)) {
    final tramite = OccurrenceAmostraTramite.fromStorage(
      occurrence.amostraTramite,
    );
    data['amostra_tramite_label'] = tramite?.label;
  }
  final branding = await resolveReportBrandingContext(
    ref,
    fallbackConsultantName: 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
  );
  return OcorrenciaHtmlRenderer.renderDetalhe(
    data,
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantName: branding.consultantName,
    consultantRole: branding.consultantRole,
    asFragment: asFragment,
  );
}
