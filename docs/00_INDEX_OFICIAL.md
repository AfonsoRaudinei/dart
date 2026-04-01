# SoloForte — Índice Arquitetural Oficial

**Versão:** v1.1  
**Status:** ATIVO — OBRIGATÓRIO  
**Data:** 22/02/2026  

---

## 1. Hierarquia Documental

```
01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md   ← AUTORIDADE MÁXIMA
02_ARQUITETURA_ATIVA/                         ← CONTRATOS VIGENTES
03_ENFORCEMENT/                               ← REGRAS AUTOMATIZADAS
04_AUDITORIAS/                                ← HISTÓRICO DESCRITIVO
05_HISTORICO/                                 ← ARQUIVO MORTO
```

**Lei de precedência:**

```
BASELINE > ARQUITETURA_ATIVA > AUDITORIAS > HISTORICO
```

Em caso de conflito entre dois documentos, prevalece o de maior hierarquia.  
Auditoria não é contrato. Histórico não é referência.

---

## 2. Documento de Autoridade

| Campo | Valor |
|---|---|
| **Arquivo** | `01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md` |
| **Versão** | v1.1 |
| **Score** | 90/100 |
| **Estado** | CONGELADO |
| **Branch** | `release/v1.1` |
| **Commit** | `0eb0975c06b4331e937947ef921067c11d42bbaa` |

Este é o único documento que define o estado arquitetural oficial.  
Toda decisão estrutural deve ser comparada contra este documento.

---

## 3. Documentos Ativos

### 3.1 Baseline (Autoridade)
| Arquivo | Descrição |
|---|---|
| `01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md` | Estado estrutural oficial — Score 90 |

### 3.2 Arquitetura Ativa (Contratos)
| Arquivo | Descrição |
|---|---|
| `02_ARQUITETURA_ATIVA/bounded_contexts.md` | Fronteiras de domínio oficiais |
| `02_ARQUITETURA_ATIVA/arquitetura-navegacao.md` | Sistema de navegação e rotas |
| `02_ARQUITETURA_ATIVA/arquitetura-namespaces-rotas.md` | Namespaces e estrutura de rotas |
| `02_ARQUITETURA_ATIVA/arquitetura-persistencia.md` | Camada de persistência |
| `02_ARQUITETURA_ATIVA/arquitetura-ocorrencias.md` | Módulo de ocorrências |
| `02_ARQUITETURA_ATIVA/ADR-008-RIVERPOD-NORMALIZATION.md` | ADR: normalização Riverpod |
| `02_ARQUITETURA_ATIVA/ADR-011-MARKETING-CASES.md` | ADR: integração do módulo marketing ao mapa |
| `02_ARQUITETURA_ATIVA/ADR-012-MODULO-PLANOS.md` | ADR: sistema de planos, pagamentos e indicações |
| `02_ARQUITETURA_ATIVA/ADR-013-RELATORIOS-DOMAIN.md` | ADR: novo submódulo de relatórios na consultoria |
| `02_ARQUITETURA_ATIVA/ADR-020-VISITAS-CONSULTORIA-CONTRACT.md` | ADR: contratos entre visitas e consultoria via core/contracts |
| `02_ARQUITETURA_ATIVA/ADR-022-NDVI-MODULE.md` | ADR: módulo NDVI |
| `02_ARQUITETURA_ATIVA/ADR-023-MODULO-VISITAS.md` | ADR: bounded context formal de visitas/ — dívidas técnicas DT-023-1..8 |
| `02_ARQUITETURA_ATIVA/ADR-024-VISITAS-BLINDAGEM-COMPLETA.md` | ADR: resolução DT-023-3 e DT-023-4 — blindagem completa de visitas/ — ciclo fechado |

### 3.3 Enforcement (Regras Automatizadas)
| Arquivo | Descrição |
|---|---|
| `03_ENFORCEMENT/enforcement-rules.md` | Regras de fronteira documentadas |
| `03_ENFORCEMENT/arch_check_documentation.md` | Documentação do script `arch_check.sh` |

---

## 4. Fluxo Obrigatório — Antes de Qualquer Alteração Estrutural

```
1. Ler este índice (00_INDEX_OFICIAL.md)
2. Ler 01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md
3. Ler 02_ARQUITETURA_ATIVA/bounded_contexts.md
4. Declarar: qual módulo será afetado?
5. Declarar: altera contrato de interface?
6. Declarar: altera fronteira entre módulos?
7. Executar: tool/arch_check.sh → deve passar
8. Se altera contrato → atualizar baseline + este índice
```

Se algum passo for ignorado → **alteração estrutural inválida**.

---

## 5. Enforcement Automático

**Script:** `tool/arch_check.sh`  
**CI:** `.github/workflows/architecture.yml`  
**Comportamento:** bloqueia PR se houver violação de fronteira arquitetural.

Regras implementadas automaticamente:
- REGRA 1: `core/` não importa `modules/` (exceto `app_router.dart`)
- REGRA 2: acoplamentos laterais proibidos entre módulos
- REGRA 3: novos arquivos não ultrapassam 900 linhas

---

## 6. Regra de Atualização do Baseline

Nenhum agente (humano ou automatizado) pode:

- Alterar fronteiras de módulo sem atualizar `01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md`
- Introduzir nova dependência cruzada sem declarar ADR
- Criar novo módulo sem declarar bounded context em `02_ARQUITETURA_ATIVA/bounded_contexts.md`
- Remover ou mover enforcement sem aprovação explícita

Violação desta regra = alteração arquitetural não autorizada.

---

## 7. Escopo de Cada Pasta

| Pasta | Tipo | Pode ser referência? |
|---|---|---|
| `01_BASELINE/` | Contrato congelado | ✅ SIM — autoridade máxima |
| `02_ARQUITETURA_ATIVA/` | Contratos vigentes | ✅ SIM — autoridade secundária |
| `03_ENFORCEMENT/` | Regras automatizadas | ✅ SIM — como funciona o CI |
| `04_AUDITORIAS/` | Histórico descritivo | ⚠️ NÃO — apenas informativo |
| `05_HISTORICO/` | Arquivo morto | ❌ NÃO — não referenciar |

---

*Este índice é o ponto de entrada obrigatório para qualquer agente atuando no projeto SoloForte.*
