# ADR-061 — Calendário do produtor após confirmação da visita

**Status:** ATIVO  
**Data:** Nov/2026  
**Relacionados:** ADR-040 · ADR-041 · ADR-060

## Contexto

O perfil produtor não tem a agenda do consultor. `AppAccess` não libera `/agenda`
e o menu do produtor não mostra essa entrada. A visita e as ocorrências feitas
pelo consultor precisam aparecer para o produtor, num calendário próprio, só
depois que o consultor confirmar a visita.

## Decisão

1. A agenda do consultor permanece exclusiva do perfil consultor.
2. O consultor confirma a visita concluída. A confirmação guarda sessão,
   cliente, data, fazenda e talhão.
3. O produtor vê a visita e as ocorrências daquela sessão em
   `/produtor/calendario`. Sem confirmação, a visita não entra nesse calendário.
4. Contrato `IProducerVisitCalendar` em `core/contracts/`. `produtor/` não
   importa `agenda/` nem `consultoria/`.
5. Persistência local em SQLite v54 (`visit_producer_confirmations`) e espelho
   remoto com RLS: o consultor escreve a própria confirmação; o produtor lê
   quando o vínculo do cliente está ativo.
6. Sem hard delete.

## Não-objetivos

- Não abrir a agenda de planejamento para o produtor.
- Não publicar a visita automaticamente no encerramento.
