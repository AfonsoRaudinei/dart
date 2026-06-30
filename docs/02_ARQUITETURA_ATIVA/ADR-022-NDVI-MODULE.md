# ADR 022: Módulo NDVI Restruturado com DIP e Migration V27

## Contexto
O módulo NDVI existia mas com dependências restritivas e forte acoplamento (lendo geometrias diretamente de `consultoria_module` via repository no provider). Precisávamos que o contrato expusesse de forma transparente o uso offline + dependências mais robustas sem corromper a modularidade.

## Decisão
1. Adicionado o contrato Dependency Inversion Principle `IFieldLookup` em `core/contracts/`.
2. O cache SQLite foi dropado e reconstruído via V27 para um esquema idempotente onde a entidade realoca a dependência isoladamente.
3. Repositório simplificado — datasource remoto mantém chamadas em `bbox` como detalhe de payload interno, não como exposição de interface.
4. `NdviPanelWidget` removido temporariamente em favorecimento do `NdviTalhaoSheet` na próxima release (Fase 2a).

## Consequências
- A compilação é restaurada momentaneamente com um placeholder do PanelWidget.
- Zero dependência inter-módulos `ndvi` importando `consultoria`.
