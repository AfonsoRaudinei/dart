# PROMPT — Decisão Arquitetural: `confirmacao_screen.dart` + Índice de Execução

**Agente:** Arquiteto Flutter/Dart — Decisão de UX e Fluxo de Compra
**Tipo:** Decisão Arquitetural (não-código)
**PRD Referência:** PRD_SMART_BUTTON_UNIFICACAO.md — Erro 2 (confirmacao) — Prioridade 2 Alta
**Branch:** release/v1.1

---

## 1. CONTEXTO

A `ConfirmacaoScreen` (`/planos/confirmacao`) tem botão header que navega para `/planos/meu-plano`. É a tela de pós-compra do fluxo Mercado Pago.

**Situação atual:**
- Botão local header → `/planos/meu-plano` (ver plano ativo)
- SmartButton (L2+) → `/map`

**Por que esta tela requer decisão separada:**
O usuário acabou de confirmar uma compra. Existe uma lógica de UX específica:
- Retornar ao mapa (SmartButton) pode fazer sentido — "voltar ao trabalho"
- Mas o CTA natural pós-compra é "Ver meu plano" — que é o que o botão local faz

---

## 2. OPÇÕES ARQUITETURAIS

### Opção A — Remover botão header, adicionar CTA no body
Remover o `GestureDetector` do header.
Adicionar um `ElevatedButton` ou `FilledButton` explícito no corpo da tela:
```dart
ElevatedButton(
  onPressed: () => context.go('/planos/meu-plano'),
  child: const Text('Ver meu plano'),
),
```
**Prós:** Conforme contrato SmartButton. CTA explícito no body tem mais visibilidade que botão de header.
**Contras:** Requer redesign parcial da tela.

### Opção B — Remover botão header, deixar SmartButton como único retorno
Remover o `GestureDetector` do header. Não adicionar nada.
O SmartButton leva ao `/map`. O usuário pode acessar "Meu Plano" via SideMenu → Planos.
**Prós:** Mais simples, 100% conforme ao contrato.
**Contras:** UX de pós-compra menos guiada.

### Opção C — Manter fluxo de compra como exceção documentada
Manter o botão local como exceção formal documentada em ADR.
**Prós:** Preserva UX de compra.
**Contras:** Exceção ao contrato SmartButton — cria precedente.

---

## 3. RECOMENDAÇÃO

**Opção A** — CTA no body.

É a solução que respeita o contrato E mantém a UX do fluxo de compra. O botão de body não conflita com o SmartButton visualmente (posições distintas: body center vs canto inferior direito).

---

## 4. AÇÃO APÓS DECISÃO

Quando a decisão for tomada, criar prompt de execução específico para `confirmacao_screen.dart` seguindo o template padrão SoloForte com:
- Arquivo: `confirmacao_screen.dart`
- Remoção do `GestureDetector` no header
- Adição do CTA escolhido no body
- `kFabSafeArea` no fim do scrollable

---

---

# ÍNDICE DE EXECUÇÃO — SmartButton Unificação

**Status geral: 6 prompts gerados**

## Ordem de Execução Recomendada

### Fase 1 — Sem risco de regressão (executar imediatamente)

| Ordem | Prompt | Arquivo(s) | Complexidade |
|-------|--------|------------|--------------|
| 1 | `PROMPT_F_dead_code_removal.md` | `private_app_shell.dart`, `floating_menu_button.dart` | Trivial |
| 2 | `PROMPT_E_appshell_safearea.md` | `app_shell.dart` | Baixa |
| 3 | `PROMPT_A_botoes_duplicados_mesmo_destino.md` | `planos_screen`, `meu_plano_screen`, `publicacao_editor_screen`, `feedback_screen` | Baixa |

### Fase 2 — Com análise de UX (executar após Fase 1 validada)

| Ordem | Prompt | Arquivo(s) | Complexidade |
|-------|--------|------------|--------------|
| 4 | `PROMPT_B_botoes_destino_divergente_planos.md` | `pagamento_screen`, `indicacoes_screen` | Média |
| 5 | `PROMPT_C_agenda_appbar_pop.md` | 3 telas de agenda | Média |

### Fase 3 — Decisão + execução (após aprovação arquitetural)

| Ordem | Prompt | Arquivo(s) | Complexidade |
|-------|--------|------------|--------------|
| 6 | `PROMPT_D_fabsafearea_client_detail.md` | `client_detail_screen`, `agenda_month_page` | Média |
| 7 | [A criar após decisão] | `confirmacao_screen.dart` | Baixa-Média |

---

## Critérios de Aceite Global (após todos os prompts executados)

```bash
# 1. Nenhum botão de retorno duplicado
grep -r "FloatingActionButton\|arrow_back_ios_new" lib/modules/ --include="*.dart" \
  | grep -v "map_controls_overlay"  # exceção legítima (desenho)
# Resultado esperado: zero

# 2. Nenhum pop() de navegação
grep -r "context\.pop()\|Navigator\.pop(context)" lib/ --include="*.dart" \
  | grep -v "showDialog\|showModalBottomSheet\|showBottomSheet"
# Resultado esperado: zero

# 3. Dead code removido
ls lib/ui/components/private_app_shell.dart 2>/dev/null && echo "ERRO: ainda existe" || echo "OK: removido"
ls lib/ui/components/map/floating_menu_button.dart 2>/dev/null && echo "ERRO: ainda existe" || echo "OK: removido"

# 4. Análise e arquitetura
flutter analyze  # → 0 errors
arch_check.sh    # → Exit 0
```

---

## Nota Final

O template PROMPT SKILL OFICIAL está coerente. Os 8 erros do PRD foram gerados por execuções que ignoraram o contrato — não por falha do template. A disciplina de processo (sempre seguir o template antes de codificar) é a mitigação real.

Os prompts acima adicionam as 3 lacunas identificadas na auditoria do template:
- `arch_check.sh` e `flutter analyze` em toda validação final
- `sync_status` e migrações idempotentes (não aplicável neste PRD — apenas UI)
- grep de `FloatingActionButton` fora do AppShell como check de conformidade
