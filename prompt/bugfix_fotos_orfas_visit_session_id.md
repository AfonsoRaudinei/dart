# PROMPT 3/3 — Bugfix: fotos órfãs sem visit_session_id
**Agente:** Engenheiro Sênior Flutter/Dart
**Arquivo salvo em:** `prompt/bugfix_fotos_orfas_visit_session_id.md`
**Data:** 17/08/2026
**Risco:** MÉDIO — alteração de persistência; requer cuidado com estado de sessão
**PROMPT BASE ATIVO:** SOLOFORTE_PROMPT_BASE_v2.1
**MÓDULO ATIVO:** PERSISTENCIA_OFFLINE
**Módulo afetado (prompt):** `operacao/` — **descoberta:** captura vive em `consultoria/quick_photo/`
**Tipo:** bugfix — dado de contexto ausente no momento da persistência
**Objetivo:** Injetar visit_session_id ativo ao salvar fotos de Foto rápida e Inversão vegetal
**Altera contrato de interface?** NÃO — campo já existe na entidade
**Altera fronteira entre módulos?** NÃO
**arch_check.sh:** OBRIGATÓRIO exit 0

---

## CONTEXTO

Fotos capturadas via "Foto rápida" e "Inversão vegetal" são salvas no banco
sem `visit_session_id`, mesmo quando há uma sessão de visita ativa no momento
da captura. Isso faz com que apareçam como "Sem visita vinculada / Órfã" na
aba Mídia do Relatório.

O campo `visit_session_id` já existe na entidade de foto/mídia.
O bug está no momento da persistência: a sessão ativa não está sendo lida
e injetada no registro da foto.

**Importante:** fotos capturadas **sem** sessão ativa devem continuar sendo
salvas normalmente — apenas sem `visit_session_id` (comportamento correto).
O campo é opcional. Não bloquear a captura se não houver sessão.

---

## OBJETIVO

No momento de salvar uma foto (Foto rápida ou Inversão vegetal), verificar
se existe uma `VisitSession` ativa via provider/repositório e, se existir,
injetar o `visit_session_id` no registro da foto antes de persistir.

---

## PASSO 0 — DESCOBERTA OBRIGATÓRIA

(comandos do prompt original)

**Reportar antes do GATE 1:**
- [ ] Arquivo/método exato onde a foto é persistida
- [ ] Provider/método exato que retorna a sessão ativa
- [ ] Se `visit_session_id` já é passado como parâmetro (mas vazio) ou nem é considerado
- [ ] Camada onde a injeção deve ocorrer (UseCase, Service ou DAO)

---

## GATE 1 — Aprovação do mapeamento
> PARE. Reporte e aguarde aprovação antes de qualquer alteração.

---

## FORA DO ESCOPO

- Retroativamente vincular fotos órfãs já existentes no banco
- Alterar a aba Mídia (feito no Prompt 2/3)
- Alterar o fluxo de captura de imagem
- Criar migration de banco para fotos existentes
