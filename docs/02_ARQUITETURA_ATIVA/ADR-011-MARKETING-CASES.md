# ADR-011 — Bounded Context: `marketing/` — Revisado
**Status:** APROVADO — versão corrigida pós-implementação
**Data:** 28/02/2026
**Substitui:** ADR-011-MARKETING-PINS.md (desatualizado)
**Módulos afetados:** marketing/ (EXISTENTE), map/ (integração concluída)

---

## CONTEXTO

O módulo marketing/ foi implementado com estrutura mais rica que o ADR-011
original descreve. A entidade central é MarketingCase (não MarketingPin).
NovoCaseSheet já recebe lat/lng como parâmetros obrigatórios.

O gatilho no mapa (long-press → PublicationActionsBottomSheet → NovoCaseModalLauncher)
e a renderização dos pins (IsolatedMarketingMarkersLayer) estão implementados.

---

## INTEGRAÇÃO MAPA — CONCLUÍDA (PASSO 6 e 7)

### PASSO 6 — Integração mapa: captura de coordenada + abertura do sheet ✅

Implementado em:
- `lib/ui/screens/private_map_screen.dart` — `_handleMapLongPress`
- `lib/ui/screens/map/handlers/novo_case_modal_launcher.dart` — `launch` + `submitCaseFromMap`
- `lib/ui/components/map/widgets/publication_actions_bottom_sheet.dart`

Fluxo:
```
Usuário long-press em área vazia do mapa
  → private_map_screen captura LatLng do evento
  → PublicationActionsBottomSheet (Resultado / AntesDepois / Avaliação)
  → NovoCaseModalLauncher.launch(position: latLng)
  → verifica planoAtivoProvider (ADR-012) via _resolvePlanoAtivo
  → limite atingido → saveAsDraft + DraftSavedSheet → /planos
  → dentro do limite → promove status=published → publishCaseDetailed
  → sheet fecha → snackbar com causa real (sucesso / offline / sessão / genérico)
```

### PASSO 7 — Renderização dos pins no mapa ✅

Implementado em:
- `lib/ui/components/map/widgets/isolated_marker_layers.dart` — `IsolatedMarketingMarkersLayer`
- `lib/ui/screens/map/widgets/map_build_orchestrator.dart` — monta a layer

MarketingCaseMarker em:
`lib/modules/marketing/presentation/widgets/marketing_case_marker.dart`

Filtra cases com `status=published`, `ativo=true`, `deletadoEm=null`.

---

## ESTADO REAL DO CÓDIGO

### Entidade central: `MarketingCase`
Campos obrigatórios: id, tipo, visibilidade (PlanoMarketing), lat, lng,
localizacaoTexto, produtorFazenda, produtoUtilizado, criadoEm, atualizadoEm

Campos opcionais: produtividade, fotos, avaliações, ROI, conclusao,
nomeVendedor, telefoneVendedor, nomeTalhao, tamanhoHa

### Provider: `marketingCasesProvider`
StateNotifierProvider com keepAlive.
Métodos: load(), publishCase(), publishCaseDetailed(), retryPendingCases()
Offline-first com optimistic update e rollback para pending_sync.

### NovoCaseSheet
Recebe: lat (double), lng (double), onClose (VoidCallback),
onPublicar (void Function(MarketingCase))
Já implementado. Não alterar.

---

## HIERARQUIA VISUAL (mantida do ADR original)

PlanoMarketing.ouro   → tamanho 80x80, zIndex 3
PlanoMarketing.prata  → tamanho 64x64, zIndex 2
PlanoMarketing.bronze → tamanho 48x48, zIndex 1

---

## FRONTEIRAS (atualizadas)

```
marketing/ → NÃO depende de: consultoria/, operacao/, agenda/, drawing/
marketing/ → PODE depender de: planos/ (verificação de plano — ADR-012)
map/       → PODE depender de: marketing/ (lê providers, renderiza markers)
```

---

## ARQUIVOS DA INTEGRAÇÃO MAPA (concluída)

Alterados:
- `lib/ui/screens/private_map_screen.dart` — long-press handler
- `lib/ui/screens/map/handlers/novo_case_modal_launcher.dart` — launch + submitCaseFromMap
- `lib/ui/components/map/widgets/isolated_marker_layers.dart` — pins no mapa
- `lib/ui/components/map/widgets/publication_actions_bottom_sheet.dart` — menu de ações

NÃO alterar:
- NovoCaseSheet (contrato pronto)
- MarketingCaseMarker (widget pronto)
- marketing_case.dart (entidade pronta)
