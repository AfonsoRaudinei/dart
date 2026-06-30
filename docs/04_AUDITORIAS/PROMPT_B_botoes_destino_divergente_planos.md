# PROMPT — Grupo B: Remoção de Botões com Destino Divergente (planos/ L2+)

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em UX e Arquitetura de Navegação
**Tipo:** Correção Estrutural — Divergência de Destino de Navegação
**PRD Referência:** PRD_SMART_BUTTON_UNIFICACAO.md — Erro 2 (L2+) — Prioridade 2 Alta
**Branch:** release/v1.1

---

## 1. ESCOPO

**Módulo:** `planos/`

**Arquivos tocados (apenas estes):**
- `lib/modules/planos/presentation/screens/pagamento_screen.dart`
- `lib/modules/planos/presentation/screens/indicacoes_screen.dart`

> ⚠️ `confirmacao_screen.dart` é tratada **separadamente** — ver seção 7.

🚫 **Proibido alterar:**
- Lógica de pagamento (Mercado Pago, providers, callbacks)
- Qualquer arquivo fora dos 2 listados
- Rotas, tema, design system

---

## 2. OBJETIVO

Remover os botões de header nas telas `pagamento_screen` e `indicacoes_screen` que navegam para `/planos` (destino divergente do SmartButton que vai para `/map`), e adicionar `SizedBox(height: kFabSafeArea)` ao fim dos scrollables.

---

## 3. ANÁLISE DE RISCO (LEIA ANTES DE EXECUTAR)

**Situação atual:**
- `PagamentoScreen` (L2+): botão header → `/planos`; SmartButton → `/map`
- `IndicacoesScreen` (L2+): botão header → `/planos`; SmartButton → `/map`

**Decisão arquitetural:**
O contrato Map-First define que qualquer tela L2+ usa o SmartButton para retornar ao `/map`. O fluxo `/planos/pagamento → /planos` é navegação contextual dentro do módulo que deve ser eliminada em favor da arquitetura declarativa.

**Consequência para o usuário:**
Após remoção, o usuário em `/planos/pagamento` só terá o SmartButton (→ `/map`). Se precisar voltar para a lista de planos, deve reentrar via SideMenu. Isso é comportamento aceitável per arquitetura Map-First.

**Risco classificado:** MÉDIO

---

## 4. AÇÕES POR ARQUIVO

### 4.1 `pagamento_screen.dart`

**Localizar em `_buildHeader()`:**
```dart
GestureDetector(
  onTap: () {
    HapticFeedback.lightImpact();
    context.go('/planos');  // ← destino divergente
  },
  child: Container(
    width: 40, height: 40,
    decoration: BoxDecoration(color: Color(0xFF1C1C1E), ...),
    child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF32D74B)),
  ),
),
```

**Ação:** Remover o `GestureDetector` inteiro.
**Se o header ficar com layout quebrado:** Substituir por `const SizedBox(width: 40)` para manter alinhamento do título centralizado.

**Adicionar ao fim do ListView/Column:**
```dart
SizedBox(height: kFabSafeArea),
```

### 4.2 `indicacoes_screen.dart`

Mesma ação que 4.1: localizar e remover `GestureDetector` com `context.go('/planos')` no header.
Adicionar `SizedBox(height: kFabSafeArea)` ao fim do scrollable.

---

## 5. IMPORT CHECK

Verificar se `HapticFeedback` fica órfão após remoção em cada arquivo. Se sim, remover o import correspondente.

---

## 6. VALIDAÇÃO FINAL

```bash
flutter analyze
```
Resultado esperado: **0 errors**

```bash
arch_check.sh
```
Resultado esperado: **Exit 0**

---

## 7. NOTA SOBRE `confirmacao_screen.dart`

A `ConfirmacaoScreen` tem botão local → `/planos/meu-plano` (fluxo pós-compra).
Esta tela **não está neste prompt** — requer decisão arquitetural separada antes de execução:
- O usuário acabou de confirmar uma compra: retornar ao `/map` (SmartButton) é suficiente?
- Ou deve haver uma ação explícita "Ver meu plano" no body da tela (não como botão de retorno)?

**Aguardar decisão antes de executar para `confirmacao_screen.dart`.**

---

## 8. CHECKLIST DE ENCERRAMENTO

- [ ] `pagamento_screen.dart`: GestureDetector de retorno removido
- [ ] `indicacoes_screen.dart`: GestureDetector de retorno removido
- [ ] `kFabSafeArea` adicionado aos 2 arquivos
- [ ] Imports órfãos removidos
- [ ] `flutter analyze` → 0 errors
- [ ] `arch_check.sh` → Exit 0
- [ ] `confirmacao_screen.dart` NÃO alterada (aguardando decisão)

**Dashboard alterado?** NÃO
**Outros módulos alterados?** NÃO
**Navegação mudou?** NÃO
**Contrato alterado?** NÃO
**Apenas os 2 arquivos alvo foram afetados?** SIM

---

## 9. ENCERRAMENTO PADRÃO

Os botões de retorno divergentes foram removidos de `pagamento_screen` e `indicacoes_screen`.
O SmartButton passa a ser o único mecanismo de saída nessas telas.
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.
