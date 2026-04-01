# ADR-025 — `map/` — Bounded Context Formal: declaração de fronteiras e inventário de dívidas

**Data:** 02/04/2026
**Branch:** release/v1.1
**Status:** ABERTO — ciclo multi-prompt em execução
**Autor:** Engenheiro Sênior SoloForte
**Tipo:** BOUNDED CONTEXT FORMAL — declaração de responsabilidades, fronteiras e inventário de dívidas
**Altera fronteira entre módulos?** SIM — formaliza fronteiras implícitas do módulo `map/`
**Altera contrato de interface?** NÃO — PROMPT 02 apenas move artefatos
**arch_check.sh:** EXIT 0 com REGRA-MAP-1 adicionada

---

## 1. Contexto

ADR-024 §8 recomendou `map/` como próximo alvo de blindagem:

> "`map/` referencia `visitas/`, `consultoria/`, `drawing/` e `agenda/` sem contratos
> formais. É o God Module de apresentação da v1.1 e o maior risco arquitetural aberto."

Auditoria PROMPT 01 identificou quatro problemas estruturais principais:

1. `sf_icons.dart` (design token de `core/`) alojado em `modules/map/design/` — criando
   acoplamento artificial em 20 arquivos de outros módulos para com `map/`
2. `visit_completion_observer.dart` com 7 imports ilegais cruzando bounded contexts
   (`consultoria/` e `agenda/` diretamente)
3. `private_map_screen.dart` com 898 linhas — 2 abaixo do limite de enforcement (900)
4. `lib/ui/components/map/` como camada de apresentação sem bounded context formal

---

## 2. Responsabilidade do Módulo `map/`

| Dimensão | Valor |
|---|---|
| **Natureza** | Agregador visual — projeção de todos os domínios no contexto espacial |
| **Dependências permitidas** | `agenda/`, `drawing/`, `consultoria/`, `operacao/`, `visitas/` (via contratos), `planos/` |
| **Regra central** | `map/` pode depender de tudo; **ninguém depende de `map/`** |
| **Exceções autorizadas (REGRA-MAP-1)** | `app_router.dart`, `main.dart`, `ui/components/map/`, `ui/screens/` — Fase 3 pending |

---

## 3. Fragmentação Atual (pré-ADR-025)

| Problema | Localização | Impacto |
|---|---|---|
| Design token `SFIcons` em `modules/map/design/` | `lib/modules/map/design/sf_icons.dart` | 20 arquivos externos dependem de `map/` apenas para ícones |
| Observer com 7 imports ilegais | `map/presentation/providers/visit_completion_observer.dart` | Quebra bounded context via `consultoria/` e `agenda/` diretos |
| God Object 898 linhas | `lib/ui/screens/private_map_screen.dart` | Risco de ultrapassar 900 linhas com próxima feature |
| UI de mapa sem bounded context | `lib/ui/components/map/` | 16+ arquivos sem governança declarada |

---

## 4. Fronteiras Declaradas (ADR-025)

```
┌─────────────────────────────────────────────────────────┐
│  modules/map/  (AGREGADOR — depende de tudo)            │
│                                                         │
│  ✅ PODE importar:                                       │
│     agenda/, drawing/, consultoria/, operacao/          │
│     visitas/ via core/contracts/                        │
│     planos/ (badge SideMenu)                            │
│                                                         │
│  ❌ NÃO PODE ser importado por:                          │
│     Qualquer módulo de domínio                          │
│                                                         │
│  ⚠️  EXCEÇÕES TEMPORÁRIAS (Fase 3 pending):              │
│     app_router.dart — composição de rotas               │
│     main.dart — bootstrap visit_completion_observer     │
│     ui/components/map/ — camada de apresentação         │
│     ui/screens/ — camada de apresentação                │
└─────────────────────────────────────────────────────────┘
```

---

## 5. Inventário de Dívidas Técnicas

| ID | Descrição | Localização | Causa | Fase | Status |
|---|---|---|---|---|---|
| DT-025-1 | `SFIcons` alojado em `map/design/` — 20 importadores externos | `modules/map/design/sf_icons.dart` | Design token de `core/` em módulo de domínio | PROMPT 02 | ✅ RESOLVIDO |
| DT-025-2 | `visit_completion_observer.dart` — 7 imports ilegais (`consultoria/` + `agenda/`) | `map/presentation/providers/` | Sem contratos formais no momento da criação | PROMPT 03 | ⏳ Pendente |
| DT-025-3 | `map/` importa `visitas/` diretamente (herança DT-023-5) | `map/presentation/providers/` | DT-023-5 não resolvida em ADR-023/024 | PROMPT 03 | ⏳ Pendente |
| DT-025-4 | `ui/components/map/` e `ui/screens/` como exceções REGRA-MAP-1 | `lib/ui/` | Camada de apresentação sem bounded context formal | Fase 3 | ⏳ Pendente |
| DT-025-5 | `private_map_screen.dart` — 898 linhas (God Object) | `lib/ui/screens/` | Crescimento orgânico sem enforcement | PROMPT 04 | ⏳ Pendente |
| DT-025-6 | Ausência de testes unitários em `map/` | `lib/modules/map/` | Módulo nunca teve suite de testes | ADR futuro | ⏳ Pendente |
| DT-025-7 | `visit_completion_observer.dart` sem contrato neutro `IReportWriter` | `map/presentation/providers/` | Contrato não existe — precisa ser criado | PROMPT 03 | ⏳ Pendente |
| DT-025-8 | `farmName: event.fazendaId` — proxy ADR-010 (sem entidade `Farm`) | `visit_completion_observer.dart` | ADR-010 não implementado — `fazendaId` como proxy aceitável | PROMPT 03 | ⏳ Pendente |

---

## 6. Governança — `private_map_screen.dart`

**Arquivo:** `lib/ui/screens/private_map_screen.dart`
**Linhas atuais (pós PROMPT 02):** 898
**Limite enforcement:** 900 (REGRA 3 — `arch_check.sh`)

**Regra declarada (DT-025-5):**
- PROIBIDO adicionar código inline neste arquivo
- Toda nova funcionalidade DEVE ser extraída para widget separado em `lib/ui/components/map/`
- Apenas referências a widgets externos são permitidas
- Comentário de governança será inserido no PROMPT 04

---

## 7. REGRA-MAP-1 — Enforcement Automático

Adicionada a `tool/arch_check.sh` neste ADR (PROMPT 02):

```bash
# Nenhum módulo externo pode importar modules/map/ diretamente
# Exceções: app_router, main.dart, ui/components/map/, ui/screens/
# Quando Fase 3 (consolidação) for executada, remover as 4 exceções.
```

**Resultado no momento do ADR:** ✅ PASSA — 0 violações (DT-025-1 resolvida removeu todos os acoplamentos externos que existiam)

---

## 8. O que NÃO muda neste ADR (PROMPT 02)

- Nenhuma API pública de `map/` foi alterada
- Comportamento de runtime idêntico — apenas localização de artefatos movidos
- `visit_completion_observer.dart` ainda referencia `consultoria/` — DT-025-2/3 (PROMPT 03)
- `private_map_screen.dart` ainda tem 898 linhas — DT-025-5 (PROMPT 04)
- `lib/ui/components/map/` sem bounded context formal — DT-025-4 (Fase 3)

---

## 9. Resultado dos Gates de Qualidade (PROMPT 02)

| Gate | Resultado |
|---|---|
| `flutter analyze lib/` | 0 `error •` (após move sf_icons + atualização dos 20 importadores) |
| `bash tool/arch_check.sh` | ✅ EXIT 0 — REGRA-MAP-1 passa com 0 violações |
| Importadores antigos (`map/design/sf_icons`) | 0 ocorrências confirmado via grep |

---

## 10. Próximo ciclo — PROMPT 03

**Alvo:** `lib/modules/map/presentation/providers/visit_completion_observer.dart`

Migrar 7 imports ilegais para contratos em `core/contracts/`:

| Import atual | Contrato alvo |
|---|---|
| `agenda/domain/entities/event.dart` | Via `IAgendaSessionBridge` |
| `agenda/domain/entities/visit_session.dart` | `VisitSessionSummary` |
| `agenda/presentation/providers/agenda_provider.dart` | `iAgendaSessionBridgeProvider` |
| `consultoria/occurrences/data/occurrence_repository.dart` | `IOccurrenceRead` |
| `consultoria/occurrences/presentation/controllers/occurrence_controller.dart` | `IOccurrenceRead` |
| `consultoria/relatorios/models/visit_session_snapshot.dart` | DTO local construído inline |
| `consultoria/relatorios/use_cases/generate_relatorio_use_case.dart` | Novo contrato `IReportWriter` (a criar) |

**DT-025-8:** `farmName: event.fazendaId ?? 'Fazenda não identificada'` — proxy ADR-010 documentado e aceito.
