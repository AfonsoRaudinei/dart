# ADR-010 — Proxy `event.titulo → farmName` em `VisitSessionSnapshot`

**Data:** 24/02/2026
**Branch:** `release/v1.1`
**Status:** APROVADO — DÍVIDA TÉCNICA CONTROLADA
**Autor:** Engenheiro Sênior Flutter
**Módulo afetado:** `map` (`visit_completion_observer.dart`)
**Tipo de alteração:** DECISÃO DE MAPEAMENTO — sem alteração estrutural
**Altera fronteira entre módulos?** NÃO
**Altera contrato de interface?** NÃO
**arch_check.sh:** SEM IMPACTO

---

## 1. Contexto

Durante o Passo 2 do ADR-009, ao montar `VisitSessionSnapshot` a partir de `VisitSession` (via `VisitCompletionObserver`), identificou-se que o modelo `VisitSession` em `operacao` **não possui o campo `farmName`**.

O campo `farmName` é obrigatório em `VisitSessionSnapshot` (contrato ADR-009) e representa o nome da fazenda onde a visita foi realizada.

---

## 2. Decisão

Utilizar `event.titulo` como proxy temporário para `farmName` no mapeamento dentro de `visit_completion_observer.dart`.

```dart
// TODO(ADR-010): proxy temporário — substituir quando VisitSession
// expor farmName diretamente.
// Raiz: VisitSession não possui farmName; usando event.titulo como proxy.
snapshot = VisitSessionSnapshot(
  ...
  farmName: event.titulo, // proxy
  ...
);
```

---

## 3. Justificativa

| Opção | Descrição | Decisão |
|---|---|---|
| A | Usar `event.titulo` como proxy imediato | ✅ ADOTADA |
| B | Bloquear geração de relatório até `farmName` existir em `VisitSession` | ❌ REJEITADA |
| C | Adicionar `farmName` a `VisitSession` agora | ❌ REJEITADA neste ciclo |

A Opção B foi rejeitada porque impede o fluxo completo de funcionar — o relatório não seria gerado mesmo com todos os outros dados disponíveis.

A Opção C foi rejeitada porque adicionar `farmName` a `VisitSession` é uma alteração de contrato em `operacao` que requer ADR próprio, migração de banco (database_helper v12) e validação de impacto nos testes de `Agenda`.

A Opção A é a escolha correta para este ciclo: entrega o fluxo funcional com dado aproximado e registra a dívida de forma rastreável.

---

## 4. Impacto no Produto

| Cenário | Comportamento atual | Comportamento esperado |
|---|---|---|
| `event.titulo` = "Visita Fazenda São João" | `farmName` = "Visita Fazenda São João" | `farmName` = "São João" |
| `event.titulo` genérico ("Visita técnica") | `farmName` = "Visita técnica" | `farmName` = nome real da fazenda |

O impacto é cosmético — o relatório é gerado corretamente, o nome da fazenda pode ser editado pelo agrônomo no campo `title` da tela de detalhe antes de publicar.

---

## 5. Condição de Encerramento

Esta dívida é encerrada quando **uma das seguintes condições** for atendida:

**Condição A (preferida):** `VisitSession` em `operacao` receber o campo `farmName` via ADR futuro. Ao implementar, atualizar:
- `visit_completion_observer.dart` — remover proxy, usar `session.farmName`
- `VisitSessionSnapshot` — nenhuma alteração necessária (campo já existe)
- Remover o TODO do código

**Condição B (alternativa):** Criar um serviço de resolução de fazenda por `clientId` em `map/`, que busca o nome real via repositório de clientes antes de montar o snapshot.

---

## 6. Arquivo afetado

```
lib/modules/map/presentation/providers/visit_completion_observer.dart

Linha aproximada do proxy:
  farmName: event.titulo, // TODO(ADR-010): proxy temporário
```

---

## 7. Rastreabilidade

| Campo | Valor |
|---|---|
| Identificado em | ADR-009 — Passo 2 |
| Registrado em | ADR-010 (este documento) |
| TODO no código | `// TODO(ADR-010): proxy temporário` |
| Prioridade | Baixa — impacto cosmético, editável pelo usuário |
| Bloqueante? | NÃO |

---

## 8. Checklist de Conformidade

- [x] Decisão documentada com justificativa
- [x] Opções avaliadas e rejeitadas com motivo
- [x] TODO no código referencia este ADR
- [x] Condição de encerramento definida
- [x] Nenhuma alteração estrutural introduzida
- [x] `00_INDEX_OFICIAL.md` — ADR-010 adicionado na Seção 3.2
- [x] `00_INDEX_OFICIAL.md` — ADR-010 adicionado na Seção 8 (histórico de ADRs)

---

## Referências

- [ADR-009](ADR-009-RELATORIO-PUBLICACAO.md) — origem da dívida
- `02_ARQUITETURA_ATIVA/bounded_contexts.md` — fronteiras de módulo
- `visit_completion_observer.dart` — arquivo com o proxy

---

*ADR-010 — SoloForte App v1.1 — 24/02/2026 — Branch: `release/v1.1`*
