import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/i_marketing_case_reports_lookup.dart';
import '../../../core/contracts/marketing_case_report_snapshot.dart';
import '../../../core/contracts/i_occurrence_access_reader_provider.dart';
import '../../../core/html_templates/marketing_html_renderer.dart';
import '../../../core/session/local_session_identity.dart';
import '../../../core/session/user_role.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import '../../settings/presentation/providers/user_profile_provider.dart';
import '../domain/entities/marketing_case.dart';
import '../domain/marketing_case_visibility.dart';
import '../presentation/providers/marketing_providers.dart';
import '../presentation/widgets/edit_case_sheet.dart';

/// Provider interno — registrado em `main.dart` como override de
/// [marketingCaseReportsListProvider] em `core/contracts/`.
final marketingCaseReportsListImplProvider =
    Provider<AsyncValue<List<MarketingCaseReportSnapshot>>>((ref) {
      try {
        final casesAsync = ref.watch(marketingCasesProvider);
        final role = ref.watch(currentUserRoleProvider);
        final authorizedAsync = role.isProdutor
            ? ref.watch(authorizedClientIdsProvider)
            : const AsyncValue.data(<String>{});
        final currentUserId = LocalSessionIdentity.resolveUserId();

        return casesAsync.when(
          data: (cases) {
            final authorized = authorizedAsync.valueOrNull ?? const <String>{};
            final visible = cases.where((item) {
              if (item.deletadoEm != null) return false;
              if (!role.isProdutor) return true;
              return MarketingCaseVisibility.isVisibleInReports(
                marketingCase: item,
                currentUserId: currentUserId,
                authorizedClientIds: authorized,
              );
            }).map(_toSnapshot).toList();
            return AsyncData(visible);
          },
          loading: () => const AsyncLoading(),
          error: (e, st) => AsyncError(e, st),
        );
      } catch (e, st) {
        return AsyncError(e, st);
      }
    });

MarketingCaseReportSnapshot _toSnapshot(MarketingCase item) {
  return MarketingCaseReportSnapshot(
    id: item.id,
    tipo: item.tipo.toValue(),
    tipoLabel: _marketingTypeLabel(item),
    produtorFazenda: item.produtorFazenda,
    statusValue: item.status.toValue(),
    criadoEm: item.criadoEm,
    lat: item.lat,
    lng: item.lng,
    nomeVendedor: item.nomeVendedor,
  );
}

String _marketingTypeLabel(MarketingCase item) {
  switch (item.tipo.toValue()) {
    case 'antes_depois':
      return 'Antes/Depois';
    case 'avaliacao':
      return 'Avaliação';
    case 'resultado':
    default:
      return 'Resultado';
  }
}

class MarketingCaseReportsLookupAdapter implements IMarketingCaseReportsLookup {
  MarketingCaseReportsLookupAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> deleteCase(String id) async {
    await _ref.read(marketingCasesProvider.notifier).deleteCase(id);
  }

  @override
  Future<void> showEditSheet(BuildContext context, String caseId) async {
    final cases = _ref.read(marketingCasesProvider).valueOrNull ?? [];
    final item = cases.cast<MarketingCase?>().firstWhere(
      (c) => c?.id == caseId,
      orElse: () => null,
    );
    if (item == null) return;

    await showSoloForteSheet<void>(
      context: context,
      isScrollControlled: true,
      preserveMaterialDefaults: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => EditCaseSheet(
        caso: item,
        onClose: () => Navigator.of(sheetContext).pop(),
        onSalvar: (updatedCase) async {
          await _ref.read(marketingCasesProvider.notifier).updateCase(updatedCase);
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Future<MarketingCaseReportExportBundle> buildExportBundle(
    String caseId, {
    required String? fallbackConsultantName,
    required String fallbackConsultantRole,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantName,
    String? consultantRole,
  }) async {
    final cases = _ref.read(marketingCasesProvider).valueOrNull ?? [];
    final item = cases.firstWhere(
      (c) => c.id == caseId,
      orElse: () => throw StateError('MarketingCase não encontrado: $caseId'),
    );

    final resolvedConsultant = (consultantName?.trim().isNotEmpty ?? false)
        ? consultantName!.trim()
        : (fallbackConsultantName ?? 'Equipe técnica');
    final resolvedRole = (consultantRole?.trim().isNotEmpty ?? false)
        ? consultantRole!.trim()
        : fallbackConsultantRole;

    final data = {
      ...item.toJson(),
      'avaliacoes': item.avaliacoes.map((bloco) => bloco.toJson()).toList(),
      'report_brand_name': reportBrandName,
      'report_logo_path': reportLogoPath,
      'nome_vendedor': resolvedConsultant,
    };
    final html = await MarketingHtmlRenderer.render(data);

    return MarketingCaseReportExportBundle(
      title: 'Marketing ${item.produtorFazenda}',
      fileBaseName: 'marketing_${item.id}',
      html: html,
      json: {'tipo': 'marketing_case', 'case': data},
      csv: _marketingCaseCsv(item),
    );
  }
}

String _marketingCaseCsv(MarketingCase item) {
  final rows = <List<Object?>>[
    [
      'id',
      'tipo',
      'produtor_fazenda',
      'produto_utilizado',
      'status',
      'criado_em',
      'lat',
      'lng',
    ],
    [
      item.id,
      item.tipo.toValue(),
      item.produtorFazenda,
      item.produtoUtilizado,
      item.status.toValue(),
      item.criadoEm.toIso8601String(),
      item.lat,
      item.lng,
    ],
  ];
  return rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
}

String _escapeCsv(Object? value) {
  if (value == null) return '';
  final raw = value is DateTime ? value.toIso8601String() : value.toString();
  if (raw.contains(',') ||
      raw.contains('"') ||
      raw.contains('\n') ||
      raw.contains('\r')) {
    return '"${raw.replaceAll('"', '""')}"';
  }
  return raw;
}
