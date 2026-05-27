# Auditoria Final - FAB Unificado de Ferramentas do Mapa

## Escopo

Unificacao visual dos controles de Desenho e Camadas em um unico FAB principal no mapa, com abertura de um bottom sheet segmentado por abas.

## Arquivos alterados

- `lib/ui/components/map/widgets/map_tools_bottom_sheet.dart`
- `lib/ui/components/map/widgets/map_controls_overlay.dart`
- `lib/ui/screens/map/widgets/map_build_orchestrator.dart`

## O que mudou

- Criado `MapToolsBottomSheet` como componente isolado.
- O sheet abre com a aba `Desenho` ativa por padrao.
- A navegacao superior usa duas secoes:
  - `Desenho`
  - `Visualizacao`
- A aba `Desenho` reutiliza `DrawingSheet`, preservando ferramentas, estado local, importacao KML e GPS.
- A aba `Visualizacao` reutiliza `LayersSheet`, preservando camada satelite, relevo, pinos e chuva.
- Os botoes flutuantes visuais separados de `Desenhar` e `Camadas` foram removidos do overlay.
- Criado um unico FAB circular azul no canto inferior direito para abrir as ferramentas do mapa.

## O que foi preservado

- Providers de desenho: preservados.
- Providers de camadas: preservados.
- `DrawingController`: preservado.
- `DrawingSheet`: preservado.
- `LayersSheet`: preservado.
- Fluxo de Poligono: preservado.
- Fluxo Livre: preservado.
- Fluxo Pivo: preservado.
- Fluxo Importar KML/KMZ: preservado.
- Fluxo GPS caminhar: preservado.
- Fluxo Satelite: preservado.
- Fluxo Relevo: preservado.
- Toggle de Pinos: preservado.
- Toggle de Chuva: preservado.
- Check-in: preservado.
- FAB de publicacoes: preservado.
- Mapa, markers, gestos e layers: preservados.

## Auditoria de callbacks

- `MapControlsOverlay` recebe `onOpenMapTools`.
- `MapBuildOrchestrator` abre `MapToolsBottomSheet.show(...)`.
- `MapToolsBottomSheet` recebe o mesmo `drawingControllerProvider` ja usado no mapa.
- `DrawingSheet` continua executando os mesmos handlers internos para Poligono, Livre, Pivo, Importar e GPS.
- `LayersSheet` continua executando os mesmos providers e toggles de visualizacao.
- Nenhum provider novo foi criado.
- Nenhuma regra de negocio foi alterada.

## Riscos e observacoes

- A validacao automatica confirma compilacao/analyzer dos arquivos alterados e testes gerais, mas a verificacao visual real em iPhone pequeno e Android ainda deve ser feita em runtime.
- `flutter analyze --no-pub` continua retornando 49 infos preexistentes fora do escopo, sem apontar para os arquivos desta mudanca.
- O workspace ja possuia alteracoes nao relacionadas em arquivos de ocorrencia, router, main, pubspec e `.flutter-plugins-dependencies`; elas foram preservadas.

## Validacao executada

- `dart format lib/ui/components/map/widgets/map_tools_bottom_sheet.dart lib/ui/components/map/widgets/map_controls_overlay.dart lib/ui/screens/map/widgets/map_build_orchestrator.dart`
  - Resultado: OK.

- `dart analyze lib/ui/components/map/widgets/map_tools_bottom_sheet.dart lib/ui/components/map/widgets/map_controls_overlay.dart lib/ui/screens/map/widgets/map_build_orchestrator.dart`
  - Resultado: OK, sem issues.

- `flutter analyze --no-pub`
  - Resultado: retornou 49 infos preexistentes fora do escopo.

- `flutter test --reporter compact`
  - Resultado: OK. 649 testes passaram, 1 teste pulado.

## Checklist final

- Apenas um FAB visual para Desenho/Camadas: SIM
- BottomSheet abre com aba Desenho por padrao: SIM
- Aba Visualizacao disponivel: SIM
- Poligono preservado: SIM
- Livre preservado: SIM
- Pivo preservado: SIM
- Importar KML preservado: SIM
- GPS preservado: SIM
- Satelite preservado: SIM
- Relevo preservado: SIM
- Pinos preservado: SIM
- Chuva preservada: SIM
- Providers preservados: SIM
- Regras de negocio preservadas: SIM
- Ajuste pronto para QA visual em dispositivo: SIM
