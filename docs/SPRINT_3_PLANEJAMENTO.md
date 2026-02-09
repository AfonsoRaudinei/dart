# Planejamento Sprint 3: Documentação & Polish

## Visão Geral
**Objetivo**: Consolidar a arquitetura através de contratos explícitos, refatorar a camada de apresentação do mapa para maior coesão (FieldMapEntity) e implementar mecanismos robustos de sincronização e resolução de conflitos.

**Duração**: 2 semanas

## Entregas Principais

### 1. Documentação de Contratos
Formalizar as fronteiras entre os módulos para garantir desacoplamento e testabilidade.
- [ ] **Mapa <-> Desenho**: Documentar como o mapa consome e interage com ferramentas de desenho (`docs/contratos/mapa_drawing_contract.md`).
- [ ] **Dashboard <-> Consultoria**: Definir como o dashboard exibe dados de consultoria (`docs/contratos/dashboard_consultoria_contract.md`).
- [ ] **Glossário Técnico**: Unificar a terminologia do projeto (`docs/GLOSSARIO_TECNICO.md`).

### 2. Refatoração de Providers (FieldMapEntity)
Criar uma abstração unificada para entidades renderizáveis no mapa, facilitando a composição de dados de diferentes fontes (Consultoria, Desenho, Importação).
- [ ] **FieldMapEntity**: Classe de domínio/visual que representa qualquer polígono no mapa com estado (cor, seleção, sync).
- [ ] **Refatoração de Providers**: Migrar `field_providers.dart` e `drawing_provider.dart` para emitir `FieldMapEntity`.

### 3. Sincronização e UX (SyncOrchestrator)
Implementar um gerenciador centralizado para operações de rede e resolução de conflitos.
- [ ] **SyncOrchestrator**: Classe responsável por priorizar e enfileirar requisições de sync.
- [ ] **ConflictResolutionDialog**: Interface de usuário para resolver conflitos de dados (local vs remoto).
- [ ] **Feedback Visual**: Indicadores de sync nas entidades do mapa (usando `FieldMapEntity`).

## Execução - Semana 1

### Tarefa 1.1: Contrato Mapa-Desenho (Imediato)
- Definir `DrawingStateMachine` e suas transições permitidas.
- Documentar a interface `DrawingController` exposta para o mapa.

### Tarefa 1.2: FieldMapEntity
- Implementar a classe `FieldMapEntity`.
- Atualizar `DrawingLayerWidget` e `TalhaoLayer` para consumir `FieldMapEntity` (ou manter adaptadores).

## Métricas de Sucesso
- Zero acoplamento direto entre `PrivateMapScreen` e lógicas internas de `DrawingRepository`.
- Todas as entidades no mapa renderizadas através de uma interface comum.
- Sincronização resiliente com feedback claro ao usuário.
