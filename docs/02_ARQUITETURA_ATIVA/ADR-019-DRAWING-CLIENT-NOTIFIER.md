# ADR-019 — Extração DrawingClientNotifier

**Data:** 03/03/2026  
**Branch:** `release/v1.1`  
**Status:** APROVADO  
**Contexto:** Fase 2 da Auditoria DrawingState (`docs/AUDITORIA_DRAWING_STATE.md`)

---

## Contexto

`DrawingController` acumulava duas responsabilidades ortogonais:

1. **Estado de desenho** — máquina de estados, pontos, geometria, GPS
2. **Estado de clientes/fazendas** — carregamento, pré-seleção via query param

Essa mistura de responsabilidades em um `ChangeNotifier` de 1500+ linhas viola SRP
e gera rebuild desnecessário da UI de mapa ao carregar listas de clientes.

---

## Decisão

Extrair a lógica de clientes/fazendas para `DrawingClientNotifier`, um
`NotifierProvider` dedicado dentro do módulo drawing.

```
lib/modules/drawing/presentation/providers/drawing_client_provider.dart
```

### Padrão utilizado: `NotifierProvider` (manual)

Exceção ao padrão `@riverpod` codegen (ADR-008) por coerência com o padrão
existente no módulo drawing (`DrawingExportNotifier` usa `NotifierProvider`
manual). Migração futura para codegen será feita quando o módulo for
decomposto estruturalmente.

### Contratos mantidos

- `IClientsRepository` (ADR-015) continua sendo a única ponte autorizada entre
  drawing e consultoria.
- `drawingClientsRepositoryProvider` e `drawingClientsListProvider` permanecem
  sem alteração.
- `DrawingController` continua sendo `ChangeNotifier` (ADR-008).
- `DrawingSheet` já é `ConsumerStatefulWidget` — sem mudança de tipo.

---

## Responsabilidades do DrawingClientNotifier

| Responsabilidade | Antes | Depois |
|---|---|---|
| Lista de clientes | `DrawingController._clients` | `DrawingClientNotifier.state.clients` |
| Lista de fazendas | `DrawingController._farms` | `DrawingClientNotifier.state.farms` |
| Pré-seleção Map-First | `DrawingController._preSelectedClientId` | `DrawingClientNotifier.state.preSelectedClientId` |
| `loadClients()` | método do controller | método do notifier |
| `loadFarms(id)` | método do controller | método do notifier |
| `createFarm(...)` | método do controller | método do notifier |
| `setClienteAtivo(id)` | método do controller | método do notifier |

---

## Impacto

### Redução do DrawingController

Remoção de ~70 linhas de código não relacionado ao estado de desenho.

### Isolamento de rebuild

Widgets que só precisam de clientes/fazendas (ex: dropdowns do `DrawingSheet`)
não mais causam rebuild por mudanças de estado de desenho (pontos, GPS, etc.).

---

## Checklist de enforcement

- [x] `arch_check.sh` continua passando (Exit 0)
- [x] drawing/ não importa consultoria/ diretamente
- [x] IClientsRepository como única ponte (ADR-015 mantido)
- [x] DrawingController permanece ChangeNotifier (ADR-008 mantido)
- [x] Nenhum arquivo novo ultrapassa 900 linhas
