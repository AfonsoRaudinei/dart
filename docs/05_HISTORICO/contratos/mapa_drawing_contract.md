# Contrato de Interação: Mapa <-> Módulo de Desenho
**Versão:** 1.1 (Pós-Sprint 2)

## 1. Responsabilidades

### Mapa (PrivateMapScreen)
- **Renderização**: Exibe `DrawingLayerWidget` na pilha de camadas.
- **Input**: Captura toques (`onTap`) e delega para o `DrawingController` com base na prioridade.
- **Feedback**: Exibe `DrawingStateIndicator` e `DrawingSheet`.

### Módulo de Desenho (DrawingController)
- **Estado**: Gerencia a máquina de estados (`DrawingState`).
- **Geometria**: Mantém `features` (lista completa) e `liveGeometry` (desenho atual).
- **Lógica**: Executa algoritmos geométricos (pontos, validação, operações booleanas).

## 2. Interface de Código (DrawingController)

### Inputs (Comandos do Mapa para o Controller)
- `appendDrawingPoint(LatLng point)`: Adiciona vértice ao desenho atual (Estado: `drawing`/`armed`).
- `findFeatureAt(LatLng point)`: Retorna a feature sob o ponto (Ray Casting).
- `selectFeature(DrawingFeature? feature)`: Define a feature ativa para edição/contexto.
- `cancelOperation()`: Aborta a ação atual e retorna para `idle` ou `reviewing`.

### Outputs (Getters do Controller para o Mapa)
- `currentState`: `DrawingState` atual.
- `liveGeometry`: Geometria em construção ou edição (para feedback visual em tempo real).
- `features`: Lista de todas as features persistidas (para renderização passiva).
- `selectedFeature`: Feature atualmente selecionada.

## 3. Matriz de Transições de Estado (DrawingStateMachine)

| Origem            | Evento                | Destino           | Ação                                      |
|-------------------|-----------------------|-------------------|-------------------------------------------|
| **idle**          | `startDrawing`        | **armed**         | Define ferramenta, limpa seleção          |
| **idle**          | `selectFeature`       | **idle**          | Define `selectedFeature`                  |
| **armed**         | `addPoint` (1º)       | **drawing**       | Cria geometria inicial                    |
| **drawing**       | `addPoint` (n)        | **drawing**       | Adiciona vértice                          |
| **drawing**       | `finishDrawing`       | **reviewing**     | Valida geometria, cria feature temporária |
| **reviewing**     | `confirm`             | **idle**          | Persiste feature, limpa temp              |
| **reviewing**     | `cancel`              | **idle**          | Descarta temp                             |
| **reviewing**     | `edit`                | **editing**       | Inicia modo de edição de vértices         |
| **editing**       | `save`                | **reviewing**     | Aplica alterações (nova versão)           |
| **editing**       | `cancel`              | **reviewing**     | Descarta alterações                       |
| **idle**          | `startUnion`          | **booleanOp**     | Inicia seleção para união                 |

## 4. Política de Overlay (DrawingSheet)
- O `DrawingSheet` é exibido via `showModalBottomSheet` quando uma feature é selecionada ou quando o usuário inicia uma ferramenta que requer configuração.
- O Sheet deve observar `DrawingController` e reagir a mudanças de estado (ex: mudar de "Ferramentas" para "Confirmar Importação").
