# SOLOFORTE — PROMPT SKILL OFICIAL

**Perfil:** Engenheiro Sênior Flutter (Dart) — Top 0,1%  
**Foco:** Arquitetura limpa, contratos reais, estado previsível, zero improviso.

**Arquivo:** `claude/PROMPT_UI_TOOLBAR_CONTEXTUAL_SELECAO_TALHAO.md`  
**Doc irmão (índice curto):** mesma pasta · implementação via `soloforte-executor` + revisor Grok 4.6

---

## ⚙️ MODO DE EXECUÇÃO DESTE PROMPT

Execução autônoma segura — **sem checkpoint** de volta a este chat. Cursor Composer executa do início ao fim; a revisão de qualidade é feita pelo **Grok 4.6** já configurado no pipeline do agente (`soloforte-revisor`), não por um retorno aqui. Os freios de segurança abaixo (PASSO 0, escopo travado, regra de decisão já aplicada, validação final, `arch_check.sh` + `flutter analyze` antes do commit) substituem o gate humano intermediário — não removem segurança, só removem o vaivém.

---

## 0️⃣ CONTEXTO FIXO

- **Projeto:** SoloForte App  
- **Tecnologia:** Flutter (Dart)  
- **Arquitetura:** Map-First + Stack-Based  
- **Estado:** Riverpod  
- App mobile-first · Sem AppBar fixa · Navegação central via mapa  

🚫 Nunca tratar como Flutter Web  
🚫 Nunca criar rotas fora das oficiais  
🚫 Nunca inventar dados  

---

## 📐 REGRA DE DECISÃO UI — PADRÃO PERMANENTE

Bottom sheet completo (ícone + título + descrição) **só** quando pelo menos uma condição é verdadeira:

1. a ação exige explicação textual para ser compreendida;  
2. existem 5+ opções;  
3. a ação tem múltiplos sub-passos ou formulário embutido.

Caso contrário: **toolbar contextual compacta** (ícone + label curto, sem descrição), ancorada próxima ao ponto de seleção no mapa, sem cobrir a área de trabalho — espírito Apple Maps/Pages.

### Classificação já aplicada (não pendente de aprovação)

| Ação | Destino | Justificativa |
|---|---|---|
| Editar Geometria | toolbar | ação única, ícone conhecido |
| Vincular / editar dados | toolbar | gatilho; formulário em outro fluxo |
| Ver mapa NDVI | toolbar | ação única, sem sub-passos no sheet |

Se o PASSO 0 revelar **outras** ações no sheet compact, o agente aplica a mesma regra, decide sozinho e documenta no **RELATÓRIO** — **sem pausar**.

---

## 1️⃣ ESCOPO (OBRIGATÓRIO)

**Módulo:** Drawing (seleção de feature no mapa que hoje abre sheet “Ferramentas de Desenho”)  
**Rota(s):** fluxo de seleção no mapa (sem rotas novas)

🚫 **Proibido alterar:** outros módulos listados no prompt original; rotas globais; tema; Design System (`sheet_tokens`, `premium_app_theme`); providers compartilhados de `core/`; estrutura de pastas; contrato Map-First; `suppressesMapContextTaps` + `AbsorbPointer` em marcadores (PR#27).

**Se sair do escopo → INTERROMPER e registrar no RELATÓRIO** (não prosseguir).

---

## 2️⃣ OBJETIVO

Substituir o **bottom sheet completo** como entrada das três ações acima por **toolbar contextual** ancorada próxima à feature selecionada.

---

## 3️⃣ REGRAS ABSOLUTAS

- ❌ Não mover arquivos · não refatorar fora do objetivo · não alterar estado global compartilhado sem necessidade  
- ❌ Não remover ações do `DrawingActionsBar` — mudar só o **container/gatilho** no fluxo compact  
- ❌ Não duplicar lógica dos sub-fluxos — mesmos handlers de hoje  
- ❌ `git add .` / `git add -A`  
- ✅ `arch_check.sh` Exit 0 + `flutter analyze` 0 issues novos antes de commit · commit **por arquivo**

---

## 4️⃣ PASSO 0

```bash
find lib/ -iname "*drawing*sheet*" -o -iname "*map_bottom_sheet*"
rg -n "Ferramentas de Desenho" lib/
rg -n "Editar Geometria" lib/
rg -n "suppressesMapContextTaps" lib/
rg -n "DrawingFeatureActionsMode\\.compact" lib/
```

Arquivos tocados = lista **real** do PASSO 0.

**Entrada:** feature selecionada (estado Riverpod existente).  
**Saída:** mesmos callbacks/eventos do sheet.  
**Persistência:** nenhuma nova.

---

## 5️⃣–9️⃣ Contrato, estado, performance, testes, Map-First

Conforme prompt original: sem entidade nova; provider novo preferencialmente não; testes feliz/erro/borda; não criar sub-rota `/map`.

---

## 🔟 RISCO

**Médio** — confirmar no PASSO 0 outros chamadores do sheet antes de deixar de abrir `MapSheetType.draw` no tap compact.

---

## 1️⃣1️⃣ EXECUÇÃO

Um passo autônomo. Se regra absoluta ou Map-First Check falhar → **interromper** e RELATÓRIO.

**Implementação (referência código):**

- Tap feature compact hoje: `map_build_orchestrator.dart` → `selectFeature(..., compact)` + `setSheetState(MapSheetType.draw)` — **ajustar** para não exigir sheet só pelas 3 ações.  
- Handlers: `drawing_sheet_builders_b.dart` (`startEditMode`, metadata, NDVI providers).  
- UI host: `lib/ui/components/map/` (política 4A).  
- Keys sugeridas: `map_talhao_toolbar_edit_geometry`, `map_talhao_toolbar_edit_metadata`, `map_talhao_toolbar_ndvi`.

---

## 1️⃣2️⃣ VALIDAÇÃO FINAL (RELATÓRIO)

Responder: Dashboard? Outros módulos? Navegação? Tema? Contrato? Só módulo alvo?  
Se ≠ NÃO → **desfazer** e registrar.

---

## 1️⃣3️⃣ ENCERRAMENTO

RELATÓRIO com arquivos reais, classificação de ações extras, `arch_check` + analyze, pendências QA física.

**Branch:** `cursor/ui-talhao-context-toolbar-148e`  
**Entrega:** PR + revisor + merge supervisor (`REGRA-ENTREGA-1`).

---

## 🧱 PRINCÍPIOS

Zero achismo · zero dado inventado · zero refatoração oportunista · Arquitetura > rapidez · Contrato > UI · Estado previsível > mágica
