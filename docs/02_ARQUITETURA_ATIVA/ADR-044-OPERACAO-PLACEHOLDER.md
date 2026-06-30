# ADR-044 — `operacao/` — Placeholder arquitetural (sem código ativo)

**Data:** 27/06/2026  
**Status:** ATIVO  
**Tipo:** GOVERNANÇA DE BOUNDED CONTEXT  
**Altera fronteira entre módulos?** NÃO  
**Relacionado:** ADR-024 (visitas absorveu geofence legado de operacao/)

---

## 1. Contexto

`lib/modules/operacao/` está registrado em `AGENTS.md` raiz e no baseline v1.1 como bounded context de "execução de visitas". Porém:

- O diretório contém **apenas** `AGENTS.md` — zero arquivos `.dart`.
- ADR-024 registra **DT-023-8 resolvido**: geofence duplicado `operacao/` vs `visitas/` — legado `operacao/` removido.
- Fluxos operacionais de campo (check-in, geofence, sessão) vivem em **`visitas/`** (ADR-023, ADR-033).
- Tabs "Operações" no mapa (`operations_tab_content.dart`) são **UI shell** em `ui/`, não domínio `operacao/`.

Reintroduzir código em `operacao/` sem ADR criaria **duplicação** com `visitas/` e `map/`.

---

## 2. Decisão

1. **`operacao/` permanece como placeholder documental** até existir responsabilidade de domínio que **não caiba** em `visitas/`, `agenda/` ou `map/`.
2. **Não implementar código** em `operacao/` na release v1.2 sem ADR que justifique split de bounded context.
3. **`AGENTS.md` de operacao/** permanece como guard rail para implementações futuras.
4. Referências históricas (`operacao_id` em drawing remote store, docs PRD) são **legado de schema/nomenclatura** — não implicam módulo ativo.

---

## 3. Responsabilidades atuais (onde vive cada fluxo)

| Fluxo operacional | Bounded context atual |
|---|---|
| Sessão de visita / check-in-out | `visitas/` |
| Geofence no mapa | `visitas/` + contratos `IFieldLookupGeofence` |
| Planejamento de visita | `agenda/` |
| Orquestração espacial no mapa | `map/` + `ui/screens/` |
| Operações tab (UI agregadora) | `ui/components/map/tabs/` |

---

## 4. Quando reativar `operacao/` (critérios)

Só criar código Dart em `operacao/` se **todas** forem verdadeiras:

1. Nova responsabilidade de domínio distinta de `visitas/` (ex.: ordens de serviço industriais, logística de insumos).
2. ADR novo descrevendo fronteiras e contratos em `core/contracts/`.
3. Testes em `test/modules/operacao/` desde o primeiro arquivo.
4. `arch_check.sh` atualizado com regras de acoplamento específicas.

---

## 5. Consequências

| Aspecto | Efeito |
|---|---|
| CI / arch_check | Nenhuma regra extra — diretório vazio não gera imports |
| AGENTS.md raiz | `operacao` permanece listado como contexto reservado |
| Score baseline | Contabilizado como **módulo placeholder**, não zumbi com código morto |
| Risco de duplicação | Mitigado — decisão explícita contra reimplementação silenciosa |

---

## 6. Alternativas rejeitadas

| Alternativa | Motivo da rejeição |
|---|---|
| Deletar `operacao/` e remover de AGENTS.md | Perde slot semântico documentado para expansão futura |
| Mover tabs de operações para `operacao/` agora | Seria refactor cosmético sem ganho; violaria escopo v1.2 |
| Reimplementar visitas dentro de operacao/ | Regressão arquitetural pós ADR-024 |

---

*Fase 0 — Baseline & Instrumentação | Jun/2026*
