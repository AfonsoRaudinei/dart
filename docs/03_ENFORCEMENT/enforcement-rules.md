# SoloForte — Regras de Enforcement Arquitetural

**Versão:** v1.1  
**Script:** `tool/arch_check.sh`  
**CI:** `.github/workflows/architecture.yml`  
**Status:** ATIVO — AUTOMÁTICO  

---

## Visão Geral

O enforcement arquitetural do SoloForte é **automático e bloqueante**.  
Toda violação detectada pelo `arch_check.sh` bloqueia o PR antes do merge.

Não existe manual override. Não existe exceção temporária sem ADR.

---

## REGRA 1 — Core Isolado

**Fundamento:** `core/` é infraestrutura pura. Conhecer módulos de negócio cria acoplamento descendente.

```
lib/core/** → NÃO PODE importar lib/modules/**
```

**Exceção documentada (ADR implícito — Seção 3 da Baseline):**
- `lib/core/router/app_router.dart` → ponto de composição oficial de rotas.  
  É o **único** arquivo de `core/` autorizado a conhecer módulos.

**Verificação automática:**
```bash
grep -rn "import.*modules/" lib/core/ --include="*.dart" \
  | grep -v "lib/core/router/app_router\.dart" \
  | grep -v "^\s*//"
```

---

## REGRA 2 — Bloqueio de Acoplamento Lateral

**Fundamento:** Módulos de domínio não devem criar dependências cruzadas não declaradas.

| Direção | Status | Motivo |
|---|---|---|
| `drawing → consultoria` | ❌ PROIBIDO | Domínios independentes |
| `agenda → consultoria` | ❌ PROIBIDO | Domínios independentes |
| `consultoria → drawing` | ❌ PROIBIDO | Domínios independentes |
| `visitas → consultoria` | ❌ PROIBIDO | ADR-023 — acesso via `core/contracts/` |
| `visitas → drawing` | ❌ PROIBIDO | ADR-023 — domínios independentes |
| `visitas → agenda/presentation` | ❌ PROIBIDO | ADR-023 — acesso via `core/contracts/` |

**Solução para `drawing × consultoria`:**  
`ClientsRepositoryAdapter` em `drawing/infra/` serve como única ponte autorizada, sem violar direções proibidas.

**Solução para `visitas × consultoria/drawing/agenda`:**  
Contratos em `core/contracts/` (ex: `IVisitSessionLookup`) são a única ponte autorizada.  
Dívidas ativas DT-023-3 e DT-023-4 têm exceção temporária — serão removidas no ADR-024.

**Verificação automática:**
```bash
grep -rn "import.*modules/consultoria" lib/modules/drawing/ --include="*.dart"
grep -rn "import.*modules/consultoria" lib/modules/agenda/ --include="*.dart"
grep -rn "import.*modules/drawing" lib/modules/consultoria/ --include="*.dart"
# REGRA-VISITAS-1 (ADR-023) — exceções DT-023-3, DT-023-4 autorizadas:
grep -rn "import.*modules/consultoria" lib/modules/visitas/ --include="*.dart" \
  | grep -v "visit_controller\.dart" | grep -v "geofence_controller\.dart"
# REGRA-VISITAS-2 (ADR-023):
grep -rn "import.*modules/drawing" lib/modules/visitas/ --include="*.dart"
# REGRA-VISITAS-3 (ADR-023) — exceção DT-023-3 autorizada:
grep -rn "import.*modules/agenda.*presentation" lib/modules/visitas/ --include="*.dart" \
  | grep -v "visit_controller\.dart"
```

**Exceções autorizadas (dívidas técnicas ativas — ADR-023 §9):**

| Arquivo | Dívida | Aguarda |
|---|---|---|
| `visit_controller.dart` | DT-023-3 | ADR-024 (`IOccurrenceRepository`, `IReportRepository`) |
| `geofence_controller.dart` | DT-023-4 | ADR-024 (expansão `IFieldLookup` + geometry) |

---

## REGRA 3 — Limite de Crescimento Estrutural

**Fundamento:** Arquivos grandes concentram responsabilidades e dificultam manutenção.

```
Novos arquivos Dart: máximo 900 linhas
```

**Arquivos legados monitorados (WARN — não bloqueante):**
4 arquivos históricos >900 linhas estão marcados como `WARN` e monitorados.  
Nenhum novo arquivo pode ultrapassar o limite.

**Verificação automática:**
```bash
find lib/ -name "*.dart" -newer .baseline_marker | xargs wc -l | awk '$1 > 900'
```

---

## Como Executar Localmente

```bash
# Na raiz do projeto:
chmod +x tool/arch_check.sh
./tool/arch_check.sh

# Saída esperada:
# Exit 0 → arquitetura conforme
# Exit 1 → violação detectada
```

---

## Como Adicionar Nova Regra

1. Criar ADR em `02_ARQUITETURA_ATIVA/` documentando a decisão
2. Implementar verificação em `tool/arch_check.sh`
3. Atualizar este documento
4. Atualizar `01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md` — Seção 3

---

## Violações e Consequências

| Regra | Severidade | Consequência |
|---|---|---|
| REGRA 1 | CRÍTICA | PR bloqueado automaticamente |
| REGRA 2 | CRÍTICA | PR bloqueado automaticamente |
| REGRA 3 | ALERTA | Aviso em PR — revisão manual obrigatória |

---

*Referência: `tool/arch_check.sh` · `01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md` — Seções 3 e 5*
