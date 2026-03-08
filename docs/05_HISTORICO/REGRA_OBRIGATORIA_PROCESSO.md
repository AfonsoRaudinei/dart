# SoloForte — Regra Obrigatória de Processo Arquitetural

**Versão:** v1.1  
**Status:** ATIVO — OBRIGATÓRIO  
**Data:** 22/02/2026  
**Aplica-se a:** qualquer agente (humano, Copilot, Antigravity, CI)

---

## REGRA FUNDAMENTAL

> Nenhuma alteração estrutural é válida sem cumprir este checklist integralmente.

---

## Checklist Obrigatório — Pré-Alteração Estrutural

```
[ ] 1. Lido: docs/00_INDEX_OFICIAL.md
[ ] 2. Lido: docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md
[ ] 3. Lido: docs/02_ARQUITETURA_ATIVA/bounded_contexts.md
[ ] 4. Declarado: módulo(s) afetado(s)
[ ] 5. Declarado: altera contrato de interface? (SIM/NÃO)
[ ] 6. Declarado: altera fronteira entre módulos? (SIM/NÃO)
[ ] 7. Executado: tool/arch_check.sh → resultado APROVADO
[ ] 8. Se SIM nos itens 5 ou 6: baseline atualizada e ADR criado
```

---

## Definição de "Alteração Estrutural"

Qualquer mudança que:

- Cria, renomeia ou remove um módulo em `lib/modules/`
- Adiciona ou remove uma importação entre módulos
- Cria ou altera uma interface de domínio (`I*.dart`)
- Altera a estrutura de `lib/core/`
- Introduz nova dependência de terceiros que cruza fronteiras
- Modifica `tool/arch_check.sh` ou `.github/workflows/architecture.yml`
- Reestrutura rotas em `lib/core/router/app_router.dart`

Mudanças **não estruturais** (UI, bugfixes dentro de um módulo, testes internos) **não** exigem este checklist.

---

## Consequência de Não Cumprimento

Se o checklist não for cumprido:

1. A alteração estrutural é **inválida**
2. PR deve ser **rejeitado**
3. A revisão deve referenciar esta regra explicitamente

---

## Protocolo de Atualização do Baseline

Se a alteração estrutural for aprovada e altera contrato ou fronteira:

```
1. Atualizar 01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md
   - Seção 4 (Bounded Contexts) se nova fronteira
   - Seção 5 (Garantias) se nova garantia
   - Seção 2 (Métricas) se métricas mudaram

2. Atualizar 02_ARQUITETURA_ATIVA/bounded_contexts.md
   - Refletir novo bounded context ou contrato

3. Criar ADR em 02_ARQUITETURA_ATIVA/
   - Formato: ADR-NNN-DESCRICAO.md
   - Declarar: contexto, decisão, consequências

4. Atualizar 00_INDEX_OFICIAL.md
   - Adicionar novo arquivo se criado
```

---

## Hierarquia de Documentos (Resumo)

```
BASELINE (01_BASELINE/)
  └─ autoridade máxima — sempre prevalece

ARQUITETURA ATIVA (02_ARQUITETURA_ATIVA/)
  └─ contratos vigentes — referência para implementação

ENFORCEMENT (03_ENFORCEMENT/)
  └─ regras automatizadas — não alterar sem ADR

AUDITORIAS (04_AUDITORIAS/)
  └─ histórico descritivo — não é contrato

HISTÓRICO (05_HISTORICO/)
  └─ arquivo morto — não referenciar
```

---

## Responsabilidade

Este documento é vinculante para:

- Engenheiros humanos
- Agentes de IA (GitHub Copilot, Antigravity, etc.)
- Scripts de CI/CD
- Revisores de PR

Não existe exceção. Não existe "urgência" que justifique ignorar este processo.

---

*Documento de governança arquitetural — SoloForte App v1.1 — 22/02/2026*
