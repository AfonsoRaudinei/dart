# ADR-033 — Visitas como Bounded Context de Sessão de Campo

**Data:** Mai/2026
**Status:** APROVADO
**Origem:** PRD Auditoria v1.0 — Fase 3
**Módulo:** `lib/modules/visitas/`

---

## Contexto

O módulo `visitas/` concentra o ciclo operacional de visitas em campo:
check-in, check-out, geofence, estatísticas e sincronização de `VisitSession`.
ADRs anteriores já resolveram acoplamentos críticos com `consultoria/`, mas a
decisão de contexto precisava ficar registrada de forma curta e atualizada.

---

## Decisão

`visitas/` é o bounded context oficial para sessão de visita em campo.

Responsabilidades do contexto:

- Criar e encerrar `VisitSession`
- Controlar sessão ativa
- Calcular e expor estado de geofence
- Persistir e sincronizar visitas
- Expor leitura para outros contextos via contratos neutros

Outros módulos não devem importar entidades, controllers ou repositórios de
`visitas/` diretamente para obter estado de sessão. O acesso permitido deve
passar pelos contratos em `core/contracts/`.

---

## Contratos Permitidos

| Contrato | Uso |
|---|---|
| `IVisitSessionLookup` | Consulta neutra de sessão ativa ou por id |
| `IVisitClientLookup` | Lookup neutro de cliente para UI de visita |

Adapters concretos podem viver em `visitas/infra/`, mas consumidores externos
devem depender apenas dos contratos.

---

## Regras

| Direção | Status |
|---|---|
| `visitas/` → `consultoria/` | Proibido |
| `visitas/` → `drawing/` | Proibido |
| `consultoria/` → `visitas/` | Somente via `core/contracts/` |
| `map/` → `visitas/` | Permitido apenas por composição/contrato |
| `agenda/` → `visitas/` | Permitido quando orquestra início/fim de visita |

---

## Consequências

- Novos fluxos que precisem de sessão de visita devem criar ou ampliar contrato
  neutro antes de cruzar fronteiras.
- Regras de geofence permanecem no contexto `visitas/`.
- `arch_check.sh` continua sendo o gate para impedir regressões conhecidas.

---

## Gate

- `./tool/arch_check.sh` deve passar.
- Testes de `visitas/` devem continuar verdes.
- Novos imports laterais envolvendo `visitas/` exigem ADR ou contrato em
  `core/contracts/`.
