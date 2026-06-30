import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/relatorio_status.dart';
import '../models/relatorio_tecnico.dart';
import '../providers/relatorio_repository_provider.dart';

part 'publish_relatorio_use_case.g.dart';

/// Use case: Publicar Relatório Técnico — ADR-009
///
/// Transiciona um [RelatorioTecnico] do status [RelatorioStatus.pendente_revisao]
/// para [RelatorioStatus.publicado] e o enfileira para sincronização.
///
/// Responsabilidades:
///   - Validar que o relatório existe e está em [pendente_revisao]
///   - Atualizar status para [RelatorioStatus.publicado]
///   - Atualizar syncStatus para [RelatorioSyncStatus.pending_sync]
///   - Persistir a atualização via [IRelatorioRepository.update]
///   - Retornar o relatório atualizado
///
/// Regras ADR-009:
///   ❌ NÃO chama API diretamente — enfileira via pending_sync
///   ❌ Não é possível publicar um relatório já [arquivado]
///   ✅ Produtor passa a ter acesso após esta transição
@riverpod
Future<RelatorioTecnico> publishRelatorio(Ref ref, String relatorioId) async {
  final repository = ref.watch(relatorioRepositoryProvider);

  final relatorio = await repository.getById(relatorioId);

  if (relatorio == null) {
    throw ArgumentError('Relatório não encontrado: $relatorioId');
  }

  if (relatorio.status == RelatorioStatus.arquivado) {
    throw StateError(
      'Não é possível publicar um relatório arquivado (id: $relatorioId).',
    );
  }

  if (relatorio.status == RelatorioStatus.publicado) {
    return relatorio;
  }

  final atualizado = relatorio.copyWith(
    status: RelatorioStatus.publicado,
    syncStatus: RelatorioSyncStatus.pending_sync,
    updatedAt: DateTime.now().toUtc(),
  );

  await repository.update(atualizado);

  return atualizado;
}
