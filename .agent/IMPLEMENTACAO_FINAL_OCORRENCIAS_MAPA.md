# Implementação final — Ocorrências geoespaciais no mapa

**Status:** CONTRATO DE IMPLEMENTAÇÃO · **Versão:** 2.0 · **Data:** Ago/2026

Substitui a versão Fev/2026 (dialog + setState). Alinhado a `arquitetura-ocorrencias.md` e código em `lib/modules/consultoria/occurrences/`.

---

## 1. Arquitetura

| Camada | Local |
|---|---|
| Domínio | `lib/modules/consultoria/occurrences/domain/occurrence.dart` |
| Persistência | `occurrence_repository.dart` · schema SQLite |
| UI criação | `occurrence_creation_sheet.dart` |
| UI lista | `occurrence_list_sheet.dart` |
| Pins | `lib/ui/components/map/occurrence_pins.dart` |
| Orquestração mapa | `map_build_orchestrator.dart` + `private_map_screen.dart` |

**Rota:** sempre `/map` — contexto via `ArmedMode` / `MapSheetType`, nunca sub-rota.

---

## 2. Fluxo de criação (campo)

```
PublicationActionsBottomSheet
  └─ Ocorrência → ArmedMode.occurrences
Map tap
  └─ _openOccurrenceSheet(lat, lng)
       ├─ MapSheetState.occurrencePin (primário)
       └─ pendingOccurrenceLocationProvider (rascunho)
  └─ OccurrenceCreationSheet → createOccurrence → SQLite local_only
```

**Requisitos:**
- Tap simples (não exige long press)
- Sem sheet intermediário de “marque o ponto”
- `visit_session_id` herdado se sessão ativa (não bloqueia sem sessão)

---

## 3. Modelo mínimo (congelado)

| Campo | Obrigatório |
|---|---|
| `id`, `geometry`, `type`, `created_by`, `created_at`, `updated_at`, `sync_status` | Sim |
| `description`, `severity`, `photo_paths`, `visit_session_id` | Não |

---

## 4. Componentes visuais

### Pins
- 32×32, cor por categoria, ícone em zoom ≥ 13
- Draft com opacidade reduzida

### Lista
- Filtrada por viewport + filtros chips
- Ordenação: visita ativa → mais recentes

### Sheet
- `MapBottomSheet` com detent expandido na criação
- `OccurrenceCloseCoordinator` no dismiss com rascunho dirty

---

## 5. Testes obrigatórios

```bash
flutter test test/regression/map/
flutter test test/ui/components/map/map_bottom_sheet_occurrence_host_test.dart
./tool/arch_check.sh
```

---

## 6. Anti-padrões proibidos

- Abrir criação sem `LatLng` válido
- `StateProvider.autoDispose` para pin de criação
- Dialog legado em vez de `OccurrenceCreationSheet`
- Hard delete de ocorrência sincronizada
- Navegar para tela cheia fora do mapa para criar

---

## 7. Histórico de correções

| Data | Issue | Fix |
|---|---|---|
| Fev/2026 | Modo armado com dialog | Migração para sheet |
| Ago/2026 | Gesture marketing vs ocorrência | Prioridade `ArmedMode` no orchestrator |
| Ago/2026 | IPA 206 placeholder sem form | Pin atômico em `MapSheetState` + sem autoDispose |
