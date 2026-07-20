// lib/modules/consultoria/relatorios/infra/report_writer_adapter.dart
//
// Adapter autorizado: implementa IReportWriter usando generateRelatorioProvider.
// É a única ponte entre core/contracts/IReportWriter e consultoria/relatorios/.
//
// ADR-025 — DT-025-7
// NÃO importar este arquivo fora de consultoria/ ou da injeção de dependência.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_read.dart';
import 'package:soloforte_app/core/contracts/i_report_writer.dart';

import '../models/visit_session_snapshot.dart';
import '../use_cases/generate_relatorio_use_case.dart';

/// Implementação concreta de IReportWriter.
/// Converte VisitReportInput (core/) → VisitSessionSnapshot (consultoria/)
/// e delega para generateRelatorioProvider.
/// Requer Ref para acessar o provider family — registrado via overrideWith.
class ReportWriterAdapter implements IReportWriter {
  const ReportWriterAdapter(this._ref);

  final Ref _ref;

  @override
  Future<String> generateReport(VisitReportInput input) async {
    final snapshot = _toSnapshot(input);
    final relatorio = await _ref.read(
      generateRelatorioProvider(snapshot).future,
    );
    return relatorio.id;
  }

  // ── Conversão VisitReportInput → VisitSessionSnapshot ─────────────────

  VisitSessionSnapshot _toSnapshot(VisitReportInput input) {
    return VisitSessionSnapshot(
      sessionId: input.sessionId,
      clientId: input.clientId,
      farmName: input.farmName,
      agronomistId: input.agronomistId,
      startedAt: input.startedAt,
      finishedAt: input.finishedAt,
      ocorrencias: input.occurrences.map(_toOcorrenciaSnapshot).toList(),
      talhoes: _buildTalhoes(input),
      fotos: input.fotos.map((photo) => photo.localPath).toList(),
    );
  }

  OcorrenciaSnapshot _toOcorrenciaSnapshot(OccurrenceSummary o) {
    return OcorrenciaSnapshot(
      id: o.id,
      tipo: o.type,
      descricao: o.description,
      lat: o.lat,
      lng: o.lng,
      fotoPath: o.fotoPath,
      fotoPaths: null,
      categoria: null,
      severity: null,
      geometry: null,
      status: null,
      registradaEm: o.registradaEm ?? DateTime.now().toUtc(),
      cultivar: null,
      estadioFenologico: null,
      tipoOcorrencia: null,
      recomendacoes: null,
      metricasJson: null,
      nutrientesJson: null,
      categoriasJson: null,
      notasCategoriasJson: null,
      fotosCategoriasJson: null,
    );
  }

  List<TalhaoVisitado> _buildTalhoes(VisitReportInput input) {
    if (input.talhaoId == null) return const [];
    return [
      TalhaoVisitado(
        talhaoId: input.talhaoId!,
        nomeTalhao: input.talhaoName ?? input.talhaoId!,
      ),
    ];
  }
}
