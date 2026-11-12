# ADR-060 — Visita de campo registrada na agenda

**Status:** ATIVO  
**Data:** Nov/2026  
**Relacionados:** ADR-024 · ADR-025 · ADR-048

## Contexto

O check-in pelo mapa grava `visit_sessions` e não cria evento em `agenda_events`.
No encerramento, `markEventAsDone` não acha evento e não faz nada. O relatório
de visita só nasce quando uma sessão da agenda passa de ativa para encerrada
(`VisitCompletionObserver`). A visita feita no cliente fica fora da agenda e
fora de Relatórios → Visitas.

O ADR-048 cobre o caminho agenda → `visit_sessions` e deixou o check-in do
mapa de fora. Este ADR cobre o caminho mapa → agenda, com o mesmo UUID.

## Decisão

1. `IAgendaSessionBridge` ganha `registerFieldCheckIn`, `updateFieldVisitPlace`,
   `closeFieldVisit` e `registerFinishedFieldVisit`.
2. O check-in sem `agendaEventId` cria evento `visitaTecnica` em andamento e
   sessão em `agenda_visit_sessions` com **o mesmo id** de `visit_sessions`.
3. Troca de fazenda ou talhão atualiza o evento ligado.
4. O encerramento no mapa leva o evento `emAndamento → finalizando → concluido`,
   grava `endAtReal` e atualiza o estado em memória da agenda. O observer
   existente gera o relatório. `VisitController` continua fechando
   `visit_sessions`.
5. Falha ao registrar no check-in não impede a visita. O encerramento tenta
   de novo.
6. Visitas `finished` sem evento entram na agenda já concluídas na carga
   seguinte. Relatório da mesma sessão não é gerado duas vezes.
7. Excluir o evento da agenda é soft delete (`deleted_local`). Ocorrências e
   relatório permanecem. Evento excluído não é recriado.
8. Sem mudança de schema.

## Não-objetivos

- Não unificar `visit_sessions` e `agenda_visit_sessions`.
- Não alterar o check-in que já começa por um evento da agenda (ADR-048).
- Não apagar ocorrências nem o relatório quando o evento sai da agenda.
