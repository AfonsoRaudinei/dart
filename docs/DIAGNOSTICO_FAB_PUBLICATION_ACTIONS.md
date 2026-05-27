# Diagnostico - FAB de publicacoes no mapa

## Escopo

Fase 1 executada sem alterar codigo funcional. O objetivo foi mapear onde estao o FAB "+", o menu expandido atual, as acoes de publicacao e os bottom sheets relacionados.

## Arquivos encontrados

- `lib/ui/components/map/widgets/map_action_fab_menu.dart`
  - Implementa o menu visual expandido atual do FAB de acoes.
  - Widget principal: `MapActionFabMenu`.
  - Widgets internos: `_MasterFab`, `_MenuActionButton`.

- `lib/ui/components/map/widgets/map_controls_overlay.dart`
  - Posiciona os controles sobre o mapa.
  - Instancia `MapActionFabMenu` dentro de `Positioned.fill`.
  - Recebe callbacks para resultado, antes/depois, avaliacao e ocorrencia.

- `lib/ui/screens/map/widgets/map_build_orchestrator.dart`
  - Injeta os callbacks reais em `MapControlsOverlay`.
  - Conecta as acoes de marketing a `armMarketingMode(CaseTipo...)`.
  - Conecta ocorrencia a `armOccurrenceMode()`.
  - Gerencia toque no mapa em modo armado para abrir o fluxo correto.

- `lib/ui/screens/private_map_screen.dart`
  - Mantem a logica de negocio de modo armado, pending case e abertura de sheets.
  - Metodos principais:
    - `_armMarketingMode(CaseTipo tipo)`
    - `_armOccurrenceMode()`
    - `_handleMapLongPress(...)`
    - `_openOccurrenceSheet(...)`
    - `_setSheetState(...)`

- `lib/ui/screens/map/handlers/novo_case_modal_launcher.dart`
  - Abre o bottom sheet atual de publicacao via `showSoloForteSheet`.
  - Preserva validacao de plano, limite de publicacoes e `marketingCasesProvider`.
  - Usa `NovoResultadoCaseSheet`, `NovoAntesDepoisCaseSheet`, `NovaAvaliacaoCaseSheet` ou `NovoCaseSheet`.

- `lib/modules/marketing/presentation/screens/novo_case_type_sheets.dart`
  - Wrappers dos fluxos especificos:
    - `NovoResultadoCaseSheet`
    - `NovoAntesDepoisCaseSheet`
    - `NovaAvaliacaoCaseSheet`

- `lib/modules/marketing/presentation/screens/novo_case_sheet.dart`
  - Sheet/formulario atual de publicacao.
  - Contem a logica de montagem e publicacao do case.

- `lib/ui/components/map/map_bottom_sheet.dart`
  - Bottom sheet em Stack para desenho e ocorrencias.
  - Para ocorrencia usa:
    - `OccurrenceListSheet`
    - `OccurrenceCreationSheet`

- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart`
  - Formulario atual de criacao de ocorrencia.

- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart`
  - Lista atual de ocorrencias.

- `lib/ui/screens/map/controllers/map_sheet_controller.dart`
  - Controla sheets modais para camadas e check-in.
  - Nao deve ser alterado para esta mudanca.

## Callbacks usados

- Resultado
  - `MapActionFabMenu.onResultado`
  - `MapControlsOverlay.onCreateResultadoCase`
  - `MapBuildOrchestrator`: `armMarketingMode(CaseTipo.resultado)`
  - `PrivateMapScreen._armMarketingMode`
  - Toque no mapa chama `NovoCaseModalLauncher.launch(initialTipo: CaseTipo.resultado)`

- Antes/Depois
  - `MapActionFabMenu.onAntesDepois`
  - `MapControlsOverlay.onCreateAntesDepoisCase`
  - `MapBuildOrchestrator`: `armMarketingMode(CaseTipo.antesDepois)`
  - Toque no mapa chama `NovoCaseModalLauncher.launch(initialTipo: CaseTipo.antesDepois)`

- Avaliacao
  - `MapActionFabMenu.onAvaliacao`
  - `MapControlsOverlay.onCreateAvaliacaoCase`
  - `MapBuildOrchestrator`: `armMarketingMode(CaseTipo.avaliacao)`
  - Toque no mapa chama `NovoCaseModalLauncher.launch(initialTipo: CaseTipo.avaliacao)`

- Ocorrencia
  - `MapActionFabMenu.onOcorrencia`
  - `MapControlsOverlay.onToggleOccurrenceMode`
  - `MapBuildOrchestrator`: `armOccurrenceMode()`
  - Toque no mapa chama `_openOccurrenceSheet(lat, lng)`
  - `MapBottomSheet` abre `OccurrenceCreationSheet`

## Providers envolvidos

- `armedModeProvider`
  - Controla modo armado de marketing, ocorrencias e clima.

- `mapSheetStateProvider`
  - Controla abertura do `MapBottomSheet` para desenho/ocorrencias e sheets modais.

- `pendingOccurrenceLocationProvider`
  - Armazena coordenada capturada para criacao de ocorrencia.

- `isModalOpenProvider` e `modalGenerationProvider`
  - Protegem abertura/fechamento de sheets modais.

- `marketingCasesProvider`
  - Publica cases no fluxo de marketing.

- `planoAtivoProvider`
  - Verifica limite/plano antes de publicar case.

- `occurrenceControllerProvider`
  - Cria ocorrencias no fluxo atual.

- `drawingControllerProvider`
  - Usado por controles de desenho e pelo `MapBottomSheet`.

- `visitControllerProvider`
  - Usado para status de check-in e visita ativa.

## Riscos de alteracao

- Se os callbacks dos quatro itens forem reimplementados em vez de reaproveitados, ha risco de quebrar os fluxos existentes de publicacao e ocorrencia.
- O fluxo de publicacao depende de modo armado: primeiro seleciona tipo, depois o usuario toca no mapa para abrir o sheet com coordenada.
- O fluxo de ocorrencia tambem depende de modo armado e coordenada capturada no mapa.
- `MapActionFabMenu` esta visualmente acoplado ao FAB mestre; remover o widget inteiro sem substituir o FAB pode remover o botao azul.
- `MapControlsOverlay` tambem contem controles laterais de desenho, camadas e check-in; a alteracao deve ficar restrita ao FAB de acoes.
- `MapSheetController` e o sheet de camadas nao precisam mudar e devem ser preservados.
- O workspace ja tinha alteracoes nao relacionadas em arquivos de ocorrencia, router, main e pubspec; elas nao devem ser revertidas.
