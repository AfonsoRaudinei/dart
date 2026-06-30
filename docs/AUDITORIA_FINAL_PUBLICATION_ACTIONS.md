# Auditoria Final - FAB para BottomSheet de Acoes

## 1. Arquivos alterados

- `docs/DIAGNOSTICO_FAB_PUBLICATION_ACTIONS.md`
- `lib/ui/components/map/widgets/publication_actions_bottom_sheet.dart`
- `lib/ui/components/map/widgets/map_action_fab_menu.dart`
- `lib/ui/components/map/widgets/map_controls_overlay.dart`
- `lib/modules/consultoria/quick_photo/domain/quick_photo_record.dart`

Observacao: o workspace ja continha alteracoes nao relacionadas em arquivos de ocorrencia, router, main, pubspec e `.flutter-plugins-dependencies`. Elas foram preservadas.

## 2. O que mudou

Antes:
- O FAB de acoes abria um menu expandido com icones sobre o mapa.
- As acoes Resultado, Antes/Depois, Avaliacao e Ocorrencia eram disparadas pelos botoes desse menu expandido.

Depois:
- O FAB azul permanece no mesmo local, agora com icone de "+".
- O toque no FAB abre `PublicationActionsBottomSheet`.
- O bottom sheet exibe Resultado, Antes/Depois, Avaliacao, Ocorrencia e Foto rapida.
- O menu expandido antigo ficou preservado atras da flag `useLegacyExpandedMenu`, desativada por padrao.

Motivo:
- Limpar visualmente o mapa e concentrar as acoes de publicacao em um bottom sheet compacto, sem mudar a logica existente.

## 3. O que foi preservado

- Resultado: preservado. Chama o mesmo callback `onCreateResultadoCase`, que arma `CaseTipo.resultado`.
- Antes/Depois: preservado. Chama o mesmo callback `onCreateAntesDepoisCase`, que arma `CaseTipo.antesDepois`.
- Avaliacao: preservado. Chama o mesmo callback `onCreateAvaliacaoCase`, que arma `CaseTipo.avaliacao`.
- Ocorrencia: preservada. Chama o mesmo fluxo `onToggleOccurrenceMode`, que arma ocorrencia e abre `OccurrenceCreationSheet` apos toque no mapa.
- Mapa: preservado. Nao houve alteracao em canvas, layers, markers ou gestos do mapa.
- Camadas: preservadas. `MapSheetController` e `LayersSheet` nao foram alterados.
- Publicacao: preservada. `NovoCaseModalLauncher`, providers e sheets de publicacao nao foram alterados.
- Relatorio: preservado. Nenhum fluxo de relatorio foi alterado.

## 4. Riscos encontrados

- O fluxo de Resultado/Antes/Depois/Avaliacao continua exigindo toque no mapa apos selecionar a acao, pois essa era a regra atual de captura da coordenada.
- `flutter analyze --no-pub` falha por infos preexistentes fora do escopo, principalmente deprecations `withOpacity`, nomes de constantes e um `depend_on_referenced_packages` em teste.
- Existem alteracoes nao relacionadas ja presentes no workspace; esta implementacao nao as reverteu.

## 5. Testes executados

- `dart format lib/ui/components/map/widgets/map_action_fab_menu.dart lib/ui/components/map/widgets/map_controls_overlay.dart lib/ui/components/map/widgets/publication_actions_bottom_sheet.dart lib/modules/consultoria/quick_photo/domain/quick_photo_record.dart`
  - Resultado: OK.

- `dart analyze lib/ui/components/map/widgets/map_action_fab_menu.dart lib/ui/components/map/widgets/map_controls_overlay.dart lib/ui/components/map/widgets/publication_actions_bottom_sheet.dart lib/modules/consultoria/quick_photo/domain/quick_photo_record.dart`
  - Resultado: OK, sem issues nos arquivos alterados.

- `flutter analyze --no-pub`
  - Resultado: sem erros novos nos arquivos alterados; comando retornou 49 infos preexistentes fora do escopo.

- `flutter test --reporter compact`
  - Resultado: OK. 649 testes passaram, 1 teste pulado.

## 6. Confirmacao final

- Implementacao concluida: SIM
- Logica preservada: SIM
- Houve alteracao de regra de negocio: NAO
- Pronto para proxima fase da camera: SIM
