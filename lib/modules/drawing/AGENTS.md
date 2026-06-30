# AGENTS.md — drawing

## Bounded context

`drawing/` e o dominio geometrico: desenho, edicao, importacao KML/KMZ e persistencia de geometrias.

## Contratos e dependencias

- Pode consumir `core/contracts/IFarmLookup`, `IFieldLookup` e contratos de escrita de talhao quando documentados.
- A ponte autorizada para clientes fica em `drawing/infra/` via adapter, sem acoplamento de presentation.

## Proibido

- Importar `modules/consultoria` diretamente fora das excecoes documentadas.
- Misturar estado de desenho com estado global do mapa sem contrato claro.
- Persistir geometria com dados ficticios ou sem usuario.

## Qualidade obrigatoria

- Estado de desenho deve ser previsivel e testavel.
- I/O de arquivo deve passar por abstracoes/adapters.
- Testes esperados: `test/modules/drawing/`.
- Rodar `flutter analyze lib/modules/drawing/` e `./tool/arch_check.sh`.

