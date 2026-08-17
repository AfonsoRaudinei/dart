# PROMPT 2/3 — Ocultar aba "Mídia" na tela de Relatórios
**Agente:** Engenheiro Sênior Flutter/Dart
**Arquivo salvo em:** `prompt/ocultar_aba_midia_relatorio.md`
**Data:** 17/08/2026
**Risco:** BAIXO — ocultação de tab sem remoção de lógica
**PROMPT BASE ATIVO:** SOLOFORTE_PROMPT_BASE_v2.1
**Módulo afetado:** `consultoria/relatorios/`
**Bounded context:** `consultoria/relatorios/`
**Tipo:** ocultação condicional de UI — sem deletar código
**Objetivo:** Ocultar a aba "Mídia" na tela de Relatórios sem remover o código
**Altera contrato de interface?** NÃO
**Altera fronteira entre módulos?** NÃO
**arch_check.sh:** OBRIGATÓRIO exit 0

---

## CONTEXTO

A tela de Relatórios possui abas: Visitas, Ocorrências, Marketing,
Consolidados, Mídia.

A aba "Mídia" foi criada para exibir fotos avulsas (Foto rápida e
Inversão vegetal) capturadas sem vínculo de case. Com a mudança de fluxo
(fotos agora nascem dentro de cases), essa aba perdeu a função principal
e exibe uma lista de itens órfãos.

Decisão: **ocultar** a aba Mídia — não deletar o código. O código permanece
intacto para reativação futura quando o módulo de marketing tiver relatório
HTML próprio.

---

## OBJETIVO

Ocultar a aba "Mídia" da barra de tabs da tela de Relatórios.
O código da aba e do conteúdo permanece no arquivo — apenas não é incluído
na lista de tabs visíveis.

---

## PASSO 0 — DESCOBERTA OBRIGATÓRIA

```bash
# 1. Localizar a tela de Relatórios e sua lista de abas
grep -rn "Mídia\|Midia\|midia\|TabBar\|TabController" lib/modules --include="*.dart" | grep -i "relatorio\|report"

# 2. Localizar o arquivo da tela de Relatórios
find lib/ -name "*relatorio*" -o -name "*report*" | grep "\.dart$" | grep -v test

# 3. Confirmar quantas abas existem e como estão declaradas
grep -rn "Tab(\|TabBarView\|tabs:" lib/modules --include="*.dart" | grep -v test | head -20

# 4. Verificar se Mídia tem provider/state próprio que pode ser mantido parado
grep -rn "midiaProvider\|MidiaNotifier\|MidiaState\|midiaTab" lib/ --include="*.dart"

# 5. Verificar se há rota ou deep link apontando para a aba Mídia
grep -rn "midia\|Midia\|Mídia" lib/core --include="*.dart"
```

**Reportar antes do GATE 1:**
- [ ] Arquivo exato da tela de Relatórios
- [ ] Como as tabs são declaradas (lista de `Tab`, `TabBar`, etc.)
- [ ] Linha exata onde a aba Mídia está na lista
- [ ] Se existe deep link ou navegação programática para essa aba

---

## GATE 1 — Aprovação do mapeamento
> PARE. Reporte e aguarde aprovação explícita.

---

## PASSO 1 — Ocultar a aba com comentário de preservação

A estratégia correta é **comentar a entrada da aba na lista de tabs**,
não deletá-la. O agente deve adicionar um comentário explicativo
imediatamente acima da linha comentada:

```
// OCULTO — 17/08/2026
// Aba Mídia suspensa temporariamente. Fotos agora pertencem a cases
// de marketing. Reativar quando o relatório HTML de marketing estiver pronto.
// [linha da aba aqui, comentada]
```

O mesmo padrão se aplica ao `TabBarView`: comentar o widget da aba Mídia
com o mesmo bloco de comentário.

**Regras:**
- NÃO deletar nenhuma linha — apenas comentar
- NÃO alterar as demais abas
- NÃO alterar providers ou repositórios da aba Mídia
- Se o `TabController` usa `length` fixo, ajustar o número — isso é
  necessário para não quebrar o Flutter (TabController length deve bater
  com o número de tabs visíveis)

O agente mostra o diff completo antes de aplicar.

---

## GATE 2 — Aprovação do diff
> PARE. Mostre o diff e aguarde confirmação.

---

## PASSO 2 — Validar

```bash
bash tool/arch_check.sh
flutter analyze
flutter test --no-pub
```

Verificar especialmente que o `TabController` não lança
`FlutterError: The length of TabBar.tabs must equal the length of TabBarView.children`.

---

## GATE 3 — Checklist de encerramento

| Verificação | Resposta |
|---|---|
| `arch_check.sh` exit 0? | |
| `flutter analyze` zero issues? | |
| Testes passando? | |
| `TabController.length` consistente com tabs visíveis? | |
| Código da aba Mídia preservado (apenas comentado)? | |
| Outras abas inalteradas? | |
| Providers/repositórios da Mídia intocados? | |

---

## RELATÓRIO FINAL

| Item | Detalhe |
|---|---|
| Arquivo alterado | (preencher) |
| Estratégia aplicada | comentário de preservação |
| `TabController.length` antes/depois | N/A — não há TabController |
| arch_check.sh | exit 0 |
| Próximo prompt | 3/3 — Bugfix fotos órfãs (visit_session_id) |
