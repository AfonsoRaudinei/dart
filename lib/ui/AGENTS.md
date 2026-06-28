# AGENTS.md — ui

## Bounded context

`ui/` contem shell, telas globais, componentes reutilizaveis, mapa privado/publico, tema e helpers visuais.

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

## Qualidade obrigatoria

- Navegacao sempre via `context.go()` ou `context.push()` com rotas explicitas.
- Componentes globais devem decidir comportamento por namespace, nao por tela visivel.
- Rodar testes de UI afetados e `./tool/arch_check.sh`.

