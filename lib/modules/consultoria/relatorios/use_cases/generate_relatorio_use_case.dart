import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/relatorio_tecnico.dart';
import '../models/visit_session_snapshot.dart';
import '../providers/relatorio_repository_provider.dart';

part 'generate_relatorio_use_case.g.dart';

/// Use case: Gerar Relatório Técnico a partir de uma VisitSession — ADR-009
///
/// Recebe um [VisitSessionSnapshot] (DTO de fronteira) e produz um
/// [RelatorioTecnico] persistido localmente.
///
/// Responsabilidades:
///   - Atribuir ID único (UUID v4) ao relatório
///   - Definir status inicial: [RelatorioStatus.pendente_revisao]
///   - Definir syncStatus inicial: [RelatorioSyncStatus.local_only]
///   - Persistir via [IRelatorioRepository.save]
///   - Retornar o relatório criado para a camada de apresentação
///
/// Regras ADR-009:
///   ❌ NÃO chama API — offline-first
///   ❌ NÃO importa nenhuma classe de lib/modules/operacao/
///   ✅ Usa [VisitSessionSnapshot] como contrato de entrada
@riverpod
Future<RelatorioTecnico> generateRelatorio(
  Ref ref,
  VisitSessionSnapshot snapshot,
) async {
  final repository = ref.watch(relatorioRepositoryProvider);
  const uuid = Uuid();
  final now = DateTime.now().toUtc();

  final relatorio = RelatorioTecnico.fromSnapshot(
    id: uuid.v4(),
    agronomistId: snapshot.agronomistId,
    snapshot: snapshot,
    now: now,
  );

  await repository.save(relatorio);

  return relatorio;
}
