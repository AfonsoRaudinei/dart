# Política de Overlays e Diálogos

Este documento define as regras de convivência entre elementos Flutuantes (Sheets, Dialogs, Snacks) e o Mapa no SoloForte.

## Princípios Gerais

1.  **Visibilidade do Mapa**: O mapa deve ser obstruído o mínimo possível. Prefira Sheets modais apenas quando a ação do usuário for o foco atual.
2.  **Não-Empilhamento Vertical**: Evite abrir um Dialog sobre um BottomSheet. Se uma ação no Sheet exige confirmação, tente resolvê-la dentro do próprio Sheet ou feche o Sheet antes de abrir o Dialog.
3.  **Hierarquia de Foco**: 
    - **Snackbars**: Feedback não bloqueante.
    - **BottomSheets**: Contexto de ação (ex: Ferramentas, Detalhes do Talhão).
    - **Dialogs**: Decisões críticas ou resolução de erros (ex: Conflito de Sync).

## Camadas Específicas

### 1. DrawingSheet (Persistent/Modal)
- Usada para ferramentas de desenho e edição.
- Quando aberta, interações de clique no mapa para seleção de talhões (consultoria) devem ser desativadas.

### 2. ConflictResolutionDialog (Modal)
- Bloqueia a UI até uma decisão ser tomada.
- Utilizado apenas para dados marcados com `SyncStatus.conflict`.

### 3. Feedback Visual (State Indicators)
- Indicadores de estado de desenho (StatusBar customizada) devem ficar no topo, fora da área de gestos principais.

## Regras de Interação de Mapa

- **Toque em Área Livre**: Fecha qualquer Sheet aberto e desmarca seleções.
- **Toque em Componente**: Se um talhão for tocado, o Sheet de detalhes do talhão substitui qualquer outro Sheet aberto.
