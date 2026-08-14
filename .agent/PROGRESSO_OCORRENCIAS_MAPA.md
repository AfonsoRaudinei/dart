# Progresso — Ocorrências no mapa

**Última revisão:** Ago/2026 · **Status geral:** ✅ Integrado em produção

## Concluído

- [x] Modelo `Occurrence` com geometria GeoJSON + `sync_status`
- [x] `OccurrenceCreationSheet` no `MapBottomSheet`
- [x] Modo armado via `armedModeProvider` + `ArmedModeBanner`
- [x] Dispatcher de gestos em `map_build_orchestrator.dart`
- [x] Pins, lista viewport, filtros
- [x] Regression shields (gesture + sheet + createOccurrence)
- [x] Pin atômico em `MapSheetState` (fix IPA 206)

## Não pendente (docs antigos erravam)

- ~~Integrar pins no `private_map_screen`~~ — feito via `MapBuildOrchestrator`
- ~~Abrir dialog de criação~~ — substituído por `OccurrenceCreationSheet`
- ~~85% completo~~ — integração 100% no código atual

## Backlog opcional (fora do P0)

- Editor completo no segundo tap da lista
- Clustering de pins em zoom distante
- Indicador visual de `sync_status` no pin

## Validação manual (checklist)

1. FAB `+` → Ocorrência → banner aparece
2. Tap no mapa → `OccurrenceCreationSheet` expandido com coordenada
3. Salvar → pin no mapa + `sync_status: local_only`
4. Long press com modo marketing → ainda abre case (sem regressão)
