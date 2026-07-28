# ADR-048 — Espelhamento de sessão agenda em visit_sessions

**Status:** ATIVO  
**Data:** Jul/2026  
**Relacionados:** ADR-009 · ADR-020 · ADR-024 · ADR-047 (OccurrenceSummary)

## Contexto

Check-in pela agenda criava sessão apenas em `agenda_visit_sessions`. Ocorrências,
fotos rápidas e relatórios usam `visit_sessions` / `IOccurrenceRead.getBySessionId`.
IDs divergentes → `visit_session_id = NULL` nas ocorrências e relatórios vazios.

## Decisão

1. Novo contrato `IVisitSessionWriter` em `core/contracts/`.
2. `StartEventUseCase` espelha sessão em `visit_sessions` com **o mesmo UUID**
   após `saveSession()` na agenda.
3. `CompleteEventUseCase` e `CancelEventUseCase` chamam `finishMirrorSession`
   ao fechar a sessão da agenda.
4. Implementação em `visitas/infra/visit_session_writer_adapter.dart`.
5. Falha no espelho é logada (`debugPrint`) e **não** reverte persistência da agenda.

## Mapeamento do espelho (check-in)

| visit_sessions | Origem |
|---|---|
| `id` | `agenda_visit_sessions.id` |
| `producer_id` | `event.clienteId` |
| `farm_id` | `event.fazendaId` |
| `area_id` | `event.talhaoId` |
| `activity_type` | `event.tipo.name` |
| `start_time` | `session.startAtReal` |
| `initial_lat/long` | `event.latitude/longitude ?? 0.0` |
| `status` | `'active'` |
| `sync_status` | `1` |

## Não-objetivos

- Não alterar schema SQLite (v40).
- Não unificar tabelas em uma só.
- Não alterar fluxo de check-in pelo mapa (`VisitController.startSession`).

## Consequências

- Ocorrências criadas durante visita iniciada pela agenda recebem FK válida.
- `visit_completion_observer` popula relatório com ocorrências reais.
- Guard de sessão ativa do mapa passa a detectar visitas iniciadas pela agenda.
