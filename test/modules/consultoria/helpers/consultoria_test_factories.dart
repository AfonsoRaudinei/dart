import 'package:soloforte_app/modules/consultoria/publicacoes/models/publicacao_tecnica.dart';
import 'package:soloforte_app/modules/consultoria/publicacoes/models/publicacao_tema.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_status.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_tecnico.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/visit_session_snapshot.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Constantes padrão reutilizáveis nos testes
// ──────────────────────────────────────────────────────────────────────────────

const _kSessionId = 'sess-test-1';
const _kClientId = 'cli-test-1';
const _kAgronomistId = 'agro-test-1';
const _kFarmName = 'Fazenda Teste';
const _kRelatorioId = 'rel-test-1';
const _kPublicacaoId = 'pub-test-1';
const _kAuthorId = 'agro-test-1';

/// Data base: 48h atrás — garante que `startedAt` < `finishedAt`
/// e que ambos estão no passado (útil para validações de datas).
DateTime get _baseStart =>
    DateTime.now().toUtc().subtract(const Duration(hours: 48));

DateTime get _baseEnd =>
    DateTime.now().toUtc().subtract(const Duration(hours: 46));

// ──────────────────────────────────────────────────────────────────────────────
// makeSnapshot — VisitSessionSnapshot
// ──────────────────────────────────────────────────────────────────────────────

/// Cria um [VisitSessionSnapshot] com valores padrão válidos.
///
/// Todos os campos são opcionais — use os overrides apenas no que importa
/// para o teste em questão.
VisitSessionSnapshot makeSnapshot({
  String? sessionId,
  String? clientId,
  String? agronomistId,
  String? farmName,
  DateTime? startedAt,
  DateTime? finishedAt,
  List<OcorrenciaSnapshot>? ocorrencias,
  List<TalhaoVisitado>? talhoes,
}) {
  return VisitSessionSnapshot(
    sessionId: sessionId ?? _kSessionId,
    clientId: clientId ?? _kClientId,
    agronomistId: agronomistId ?? _kAgronomistId,
    farmName: farmName ?? _kFarmName,
    startedAt: startedAt ?? _baseStart,
    finishedAt: finishedAt ?? _baseEnd,
    ocorrencias: ocorrencias ?? const [],
    talhoes: talhoes ?? const [],
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// makeRelatorio — RelatorioTecnico
// ──────────────────────────────────────────────────────────────────────────────

/// Cria um [RelatorioTecnico] com valores padrão válidos.
///
/// Status padrão: [RelatorioStatus.pendente_revisao]
/// SyncStatus padrão: [RelatorioSyncStatus.local_only]
///
/// Use os overrides para testar transições de estado.
RelatorioTecnico makeRelatorio({
  String? id,
  String? visitSessionId,
  String? clientId,
  String? agronomistId,
  String? farmName,
  RelatorioStatus? status,
  RelatorioSyncStatus? syncStatus,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? periodStart,
  DateTime? periodEnd,
  DateTime? deletedAt,
}) {
  final now = createdAt ?? DateTime.now().toUtc();
  return RelatorioTecnico(
    id: id ?? _kRelatorioId,
    visitSessionId: visitSessionId ?? _kSessionId,
    clientId: clientId ?? _kClientId,
    agronomistId: agronomistId ?? _kAgronomistId,
    farmName: farmName ?? _kFarmName,
    periodStart: periodStart ?? _baseStart,
    periodEnd: periodEnd ?? _baseEnd,
    status: status ?? RelatorioStatus.pendente_revisao,
    syncStatus: syncStatus ?? RelatorioSyncStatus.local_only,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    deletedAt: deletedAt,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// makePublicacao — PublicacaoTecnica
// ──────────────────────────────────────────────────────────────────────────────

/// Cria uma [PublicacaoTecnica] com valores padrão válidos.
///
/// Tema padrão: [PublicacaoTema.doencas]
/// Visibility padrão: [PublicacaoVisibility.privada]
/// SyncStatus padrão: [PublicacaoSyncStatus.local_only]
///
/// Use os overrides para testar validações de conteúdo e transições de sync.
PublicacaoTecnica makePublicacao({
  String? id,
  String? authorId,
  PublicacaoTema? tema,
  String? titulo,
  String? conteudo,
  PublicacaoVisibility? visibility,
  PublicacaoSyncStatus? syncStatus,
  String? safra,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  final now = createdAt ?? DateTime.now().toUtc();
  return PublicacaoTecnica(
    id: id ?? _kPublicacaoId,
    authorId: authorId ?? _kAuthorId,
    tema: tema ?? PublicacaoTema.doenca,
    titulo: titulo ?? 'Mancha Foliar em Soja — Diagnóstico e Controle',
    conteudo:
        conteudo ??
        'Conteúdo técnico padrão para uso nos testes de unidade do módulo consultoria.',
    visibility: visibility ?? PublicacaoVisibility.restrita,
    syncStatus: syncStatus ?? PublicacaoSyncStatus.local_only,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    deletedAt: deletedAt,
    safra: safra,
  );
}
