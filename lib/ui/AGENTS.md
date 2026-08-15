# AGENTS.md — ui

## Bounded context

`ui/` contem shell, telas globais, componentes reutilizaveis, **host Map-First**, tema e helpers visuais.

## Fronteira Map-First (política 4A)

O mapa visual do produto vive aqui — **não** em `lib/modules/map/` (que é domínio/adapters leves).

| Pasta | Responsabilidade |
|---|---|
| `lib/ui/screens/private_map_screen.dart` | Tela principal Map-First |
| `lib/ui/screens/map/` | Controllers, handlers, layers, orchestrator |
| `lib/ui/components/map/` | MapBottomSheet, coluna direita, layers/tools sheets |

- Correções de chrome / overlay / sheet do mapa → **este bounded context (`ui/`)**.
- `modules/map/` não é o lugar certo para editar posição da coluna direita ou chrome.
- Migrar `ui/ → modules/map/` = política **4B** (proibida sem ADR + aprovação explícita).

Ver tabela completa em `AGENTS.md` (raiz) → “Fronteira Map-First (política 4A)”.

## Regra principal

`ui/` deve preservar o contrato Map-First e o Design System existente. O FAB global e unico.

## Permitido

- Evoluir componentes reutilizaveis sem criar dependencia circular com modulos.
- Ajustar telas globais quando o fluxo for realmente transversal.
- Usar `kFabSafeArea = 100dp` em layouts com scroll ou acoes proximas ao FAB.

## Proibido

- Alterar `lib/ui/components/smart_button.dart`.
- Criar FAB local em qualquer tela ou modulo.
- Alterar tema, tokens visuais ou Design System sem aprovacao explicita.
- Criar sub-rotas sob `/map`; estados do mapa sao internos, nao rotas.
- Usar `context.pop()`, `context.canPop()` ou `Navigator.pop()` para navegacao entre telas (rotas GoRouter).
- `Navigator.pop()` em dialogs/sheets modais e permitido.
- Criar bottom sheet fora do padrão global.

## Padrão de bottom sheets

- Usar `showSoloForteSheet` de `lib/core/ui/sheets/soloforte_sheet.dart`.
- Usar `SoloForteSheetTokens` de `lib/core/ui/sheets/sheet_tokens.dart` para fundo, texto, inputs, chips e divisores.
- Não duplicar handle, título, botão de fechar ou criar componentes brancos/Material padrão dentro de sheets escuros.

## Qualidade obrigatoria

- Navegacao sempre via `context.go()` ou `context.push()` com rotas explicitas.
- Componentes globais devem decidir comportamento por namespace, nao por tela visivel.
- Rodar testes de UI afetados e `./tool/arch_check.sh`.

## Map chrome — REGRA-MAP-CHROME-1

Coluna direita em `lib/ui/components/map/widgets/map_controls_overlay.dart`:

- `kMapActionColumnBottomInset` — nunca `mapSheetChromeInsetProvider`
- Teste: `test/regression/map/controls_overlay_regression_test.dart`

## Sheets — REGRA-SHEET-BLAST-1

Componentes de mapa e shell usam `showSoloForteSheet`. Mudanca em `core/ui/sheets/` afeta todos os modulos — ver `.agent/AUDITORIA_REGRESSAO_IPA210.md`.
