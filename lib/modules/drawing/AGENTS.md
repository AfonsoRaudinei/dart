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

## Markers de vertice no mapa (flutter_map 7)

Handles de vertice (sketch + edicao) em `presentation/widgets/drawing_edit_layer.dart`:

- Gota tip-up 56x78: `Marker.alignment = Alignment.bottomCenter` — o LatLng fica no **topo** do widget (ponta da gota / topo do hitbox).
- Ponto idle (`_VertexIdleDot`): centro do circulo no vertice (`Transform.translate` com `-size/2 + 0.5`).
- Label de segmento na edicao: `bottomCenter` + `padding top 4` — texto abaixo do midpoint.
- `Alignment.topCenter` desloca o vertice ~altura do marker acima do contorno (bug IPA poligono).
- Pins tip-down (marketing): `Alignment.topCenter` + `MarkerLayer(rotate: true)` — ver `lib/ui/components/map/widgets/isolated_marker_layers.dart`.
- Teste de ancoragem: `test/modules/drawing/drawing_edit_layer_test.dart` (`expectMarkerTopAnchorsLatLng`).

