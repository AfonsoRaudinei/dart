import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/contracts/i_farm_lookup_provider.dart';
import '../../../../core/contracts/i_field_lookup_provider.dart';
import '../../../../core/contracts/i_visit_session_lookup_provider.dart';
import '../../../../core/html_templates/ocorrencia_html_renderer.dart';
import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../occurrences/domain/occurrence.dart';
import '../../occurrences/domain/occurrence_photo_paths.dart';
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

Future<String> _resolveClienteNome(IClientLookup lookup, String clientId) async {
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
  if (lookup == null) return '';
  final name = await _resolveClienteNome(lookup, id);
  return name == id ? '' : name;
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
