# AGENTS.md — map

## Bounded context

`map/` e a projecao agregadora espacial. Ele orquestra visualmente dados de agenda, operacao, drawing, consultoria, visitas, planos e contexto agricola.

## Contratos e dependencias

- Pode depender de outros modulos quando a ADR permitir.
- Deve preferir contratos em `core/contracts/` para fronteiras sensiveis.
- Ninguem deve depender de `map/`.

## Proibido

- Criar sub-rotas sob `/map`; `/map` e singleton.
- Usar `google_maps_flutter`; o mapa oficial e `flutter_map`.
- Criar FAB local ou alterar o SmartButton.
- Fazer outro modulo importar `modules/map`.
- Criar bottom sheet fora do padrão global.

## Padrão de bottom sheets

- Usar `showSoloForteSheet` de `lib/core/ui/sheets/soloforte_sheet.dart`.
- Usar `SoloForteSheetTokens` de `lib/core/ui/sheets/sheet_tokens.dart` para fundo, texto, inputs e divisores.
- Não duplicar handle, título, botão de fechar ou criar controles claros/brancos dentro de sheets escuros.

## Qualidade obrigatoria

- Contextos do mapa sao estado interno, nao rotas.
- Camadas devem ser isoladas, previsiveis e sem recomposicao desnecessaria.
- Testes esperados: testes de mapa em `test/ui/components/map/` e modulo afetado.
- Rodar `flutter analyze lib/modules/map/` e `./tool/arch_check.sh`.
