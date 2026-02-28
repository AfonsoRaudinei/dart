import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../agenda/domain/entities/event.dart';
import '../../../agenda/domain/entities/visit_session.dart';
import '../../../agenda/presentation/providers/agenda_provider.dart';
import '../../../consultoria/occurrences/data/occurrence_repository.dart';
import '../../../consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../../consultoria/relatorios/models/visit_session_snapshot.dart';
import '../../../consultoria/relatorios/use_cases/generate_relatorio_use_case.dart';

part 'visit_completion_observer.g.dart';

/// Orquestrador: VisitSession finalizada → RelatórioTécnico gerado — ADR-009
///
/// Observa o [agendaProvider] e, quando uma [VisitSession] transiciona de
/// ativa (endAtReal == null) para concluída (endAtReal != null), constrói
/// um [VisitSessionSnapshot] e dispara o [generateRelatarioProvider] de
/// forma assíncrona (fire-and-forget — sem bloquear a UI).
///
/// **Bounded context:**
///   - `agenda/` → fonte dos dados de sessão e evento
///   - `consultoria/` → destino (geração do relatório via use case)
///   - `map/` → orquestrador (este arquivo); não importa `operacao/`
///
/// **Mapeamento de campos (declarado explicitamente conforme ADR-009):**
///
/// | Fonte (Event / VisitSession)  | VisitSessionSnapshot.campo | Observação                        |
/// |-------------------------------|----------------------------|-----------------------------------|
/// | session.id                    | sessionId                  | direto                            |
/// | event.clienteId               | clientId                   | direto                            |
/// | event.fazendaId               | farmName                   | fallback se null¹                 |
/// | session.createdBy             | agronomistId               | direto                            |
/// | session.startAtReal           | startedAt                  | direto                            |
/// | session.endAtReal!            | finishedAt                 | não-null garantido                |
/// | OccurrenceRepository          | ocorrencias                | query por session.id²             |
/// | event.talhaoId                | talhoes                    | ID disponível, nome via TODO³     |
/// | (ausente)                     | fotos                      | [] — campo futuro⁴               |
/// | (ausente)                     | monitoramentos             | [] — campo futuro⁴               |
///
/// ¹ `Event.fazendaId` existe mas `farmName` (string legível) requer lookup
///   no repositório de fazendas. Usado como fallback enquanto o lookup não
///   está implementado. TODO marcado no código.
///
/// ² `OccurrenceRepository.getOccurrencesBySession(session.id)` já existe
///   em `consultoria/occurrences/data/occurrence_repository.dart`.
///   Cada `Occurrence` é mapeada para `OcorrenciaSnapshot`.
///
/// ³ `event.talhaoId` fornece o ID do talhão visitado. O nome completo
///   requer lookup via repositório de clientes/talhões. TODO marcado.
///
/// ⁴ Fotos e monitoramentos serão populados quando o módulo `operacao/`
///   expuser esses dados por sessão (iteração futura).
///
/// **Ativação:** este observer deve ser lido/assistido no boot do app para
/// que o listener seja registrado. Ver `main.dart`:
/// ```dart
/// ref.read(visitCompletionObserverProvider); // ADR-010
/// ```
@Riverpod(keepAlive: true)
class VisitCompletionObserver extends _$VisitCompletionObserver {
  static const String _tag = 'VisitCompletionObserver';

  @override
  void build() {
    ref.listen<AgendaState>(
      agendaProvider,
      (previous, next) => _onAgendaStateChanged(previous, next),
      fireImmediately: false,
    );
  }

  // ── Detecção de transição ─────────────────────────────────────────────

  /// Chamado a cada mudança no [agendaProvider].
  ///
  /// Detecta sessões que acabaram de ser concluídas comparando o estado
  /// anterior com o novo. Só dispara para transições reais
  /// (endAtReal era null → passou a não-null), o que evita:
  ///   - reprocessamento ao reiniciar o app
  ///   - duplicação por múltiplas reconstruções
  void _onAgendaStateChanged(AgendaState? previous, AgendaState next) {
    final previousSessions = previous?.sessions ?? const [];

    for (final session in next.sessions) {
      // Só interessa sessões que acabaram de ser concluídas
      if (session.endAtReal == null) continue;

      // Verifica se estava ativa (sem endAtReal) no estado anterior
      final wasActive = previousSessions.any(
        (s) => s.id == session.id && s.endAtReal == null,
      );

      if (!wasActive) continue; // Já estava concluída ou é nova — ignorar

      // Encontra o evento associado à sessão
      final event = next.events
          .where((e) => e.visitSessionId == session.id)
          .firstOrNull;

      if (event == null) {
        AppLogger.warning(
          'Sessão ${session.id} concluída mas evento associado não encontrado.',
          tag: _tag,
        );
        continue;
      }

      _dispatchReportGeneration(event: event, session: session);
    }
  }

  // ── Disparo do use case ───────────────────────────────────────────────

  /// Busca dados enriquecidos, constrói o [VisitSessionSnapshot] e dispara
  /// [generateRelatarioProvider].
  ///
  /// A operação é fire-and-forget: erros são logados mas NÃO propagados
  /// para não bloquear o fluxo de conclusão da visita.
  ///
  /// Assíncrono para permitir a query de ocorrências antes de montar o
  /// snapshot — sem bloquear o listener síncrono de [_onAgendaStateChanged].
  void _dispatchReportGeneration({
    required Event event,
    required VisitSession session,
  }) {
    // Fire-and-forget: executa de forma assíncrona sem bloquear a UI
    _buildAndDispatch(event: event, session: session).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      AppLogger.error(
        'Falha ao gerar relatório para sessão ${session.id}.',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  /// Constrói o snapshot com dados reais e dispara o use case.
  Future<void> _buildAndDispatch({
    required Event event,
    required VisitSession session,
  }) async {
    AppLogger.debug(
      'Buscando dados enriquecidos para sessão ${session.id} '
      '(cliente: ${event.clienteId})',
      tag: _tag,
    );

    final snapshot = await _buildSnapshot(event: event, session: session);

    AppLogger.debug(
      'Gerando relatório para sessão ${session.id} — '
      '${snapshot.ocorrencias.length} ocorrência(s), '
      '${snapshot.talhoes.length} talhão(ões).',
      tag: _tag,
    );

    await ref
        .read(generateRelatorioProvider(snapshot).future)
        .then(
          (relatorio) => AppLogger.debug(
            'Relatório ${relatorio.id} gerado com sucesso '
            '(status: ${relatorio.status.name}).',
            tag: _tag,
          ),
        );
  }

  // ── Construção do snapshot ────────────────────────────────────────────

  /// Mapeia [Event] + [VisitSession] para [VisitSessionSnapshot] com dados reais.
  ///
  /// Busca ocorrências via [OccurrenceRepository] antes de montar o DTO.
  /// Ver tabela de mapeamento no docstring da classe para justificativas.
  Future<VisitSessionSnapshot> _buildSnapshot({
    required Event event,
    required VisitSession session,
  }) async {
    // ── Correção A: farmName ──────────────────────────────────────────
    // TODO: substituir por lookup real via repositório de fazendas quando
    // o repositório de clientes/fazendas expuser um método getFarmById().
    // event.fazendaId está disponível para a query futura.
    final farmName = event.fazendaId ?? 'Fazenda não identificada';

    // ── Correção B: ocorrencias ───────────────────────────────────────
    // Busca ocorrências reais vinculadas à sessão via OccurrenceRepository.
    final occurrenceRepo = ref.read(occurrenceRepositoryProvider);
    final rawOccurrences = await occurrenceRepo.getOccurrencesBySession(
      session.id,
    );

    // Mapeia Occurrence → OcorrenciaSnapshot (sem alterar contrato do DTO)
    final ocorrencias = rawOccurrences
        .map(
          (o) => OcorrenciaSnapshot(
            id: o.id,
            tipo:
                o.category ??
                o.type, // category é mais semântico quando disponível
            descricao: o.description,
            lat: o.lat,
            lng: o.long,
            fotoPath: o.photoPath,
            registradaEm: o.createdAt,
          ),
        )
        .toList();

    // ── Correção C: talhoes ───────────────────────────────────────────
    // event.talhaoId fornece o ID do talhão visitado nesta sessão.
    // TODO: buscar nome e área reais via repositório de talhões
    // quando o método getTalhaoById() estiver disponível.
    // event.talhaoId pode ser usado como chave da query futura.
    final talhoes = event.talhaoId != null
        ? [
            TalhaoVisitado(
              talhaoId: event.talhaoId!,
              nomeTalhao:
                  event.talhaoId!, // TODO: substituir por nome real via lookup
            ),
          ]
        : <TalhaoVisitado>[];

    return VisitSessionSnapshot(
      // ── Campos com mapeamento direto ─────────────────────────────────
      sessionId: session.id,
      clientId: event.clienteId,
      agronomistId: session.createdBy,
      startedAt: session.startAtReal,
      finishedAt: session.endAtReal!, // endAtReal != null garantido aqui
      // ── Campos corrigidos (Correções A, B, C) ────────────────────────
      farmName: farmName,
      ocorrencias: ocorrencias,
      talhoes: talhoes,

      // ── Campos pendentes de iteração futura ──────────────────────────
      fotos:
          const [], // TODO: implementar quando módulo de fotos estiver disponível
      monitoramentos: const [],
    );
  }
}
