# ADR-011 — Bounded Context: `marketing/` — Revisado
**Status:** APROVADO — versão corrigida pós-implementação
**Data:** 28/02/2026
**Substitui:** ADR-011-MARKETING-PINS.md (desatualizado)
**Módulos afetados:** marketing/ (EXISTENTE), map/ (integração pendente)

---

## CONTEXTO

O módulo marketing/ foi implementado com estrutura mais rica que o ADR-011
original descreve. A entidade central é MarketingCase (não MarketingPin).
NovoCaseSheet já recebe lat/lng como parâmetros obrigatórios.

O que falta: o gatilho no mapa que captura a coordenada e abre o sheet,
e a renderização dos pins do MarketingCase sobre o mapa.

---

## ESTADO REAL DO CÓDIGO

### Entidade central: `MarketingCase`
Campos obrigatórios: id, tipo, visibilidade (PlanoMarketing), lat, lng,
localizacaoTexto, produtorFazenda, produtoUtilizado, criadoEm, atualizadoEm

Campos opcionais: produtividade, fotos, avaliações, ROI, conclusao,
nomeVendedor, telefoneVendedor, nomeTalhao, tamanhoHa

### Provider: `marketingCasesProvider`
StateNotifierProvider com keepAlive.
Métodos: load(), publishCase(), retryPendingCases()
Offline-first com optimistic update e rollback para pending_sync.

### NovoCaseSheet
Recebe: lat (double), lng (double), onClose (VoidCallback),
onPublicar (void Function(MarketingCase))
Já implementado. Não alterar.

---

## O QUE FALTA IMPLEMENTAR (PASSO 6 e 7 do ADR original)

### PASSO 6 — Integração mapa: captura de coordenada + abertura do sheet

Fluxo:
```
Usuário toca no mapa (long press ou tap em modo "publicar case")
  → private_map_screen captura LatLng do evento
  → verifica planoAtivoProvider (ADR-012)
  → sem plano → bottom sheet de bloqueio → /planos
  → com plano e dentro do limite → showModalBottomSheet(NovoCaseSheet)
  → usuário preenche e confirma
  → onPublicar chama marketingCasesNotifier.publishCase(case)
  → sheet fecha
  → pin aparece no mapa via rebuild do provider
```

### PASSO 7 — Renderização dos pins no mapa

MarketingCaseMarker já existe em:
lib/modules/marketing/presentation/widgets/marketing_case_marker.dart

Falta: integrar no mapa em private_map_screen — assistir
marketingCasesProvider e renderizar os markers sobre o mapa.

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

## ARQUIVOS A CRIAR/ALTERAR NESTA INTEGRAÇÃO

Alterar: lib/ui/screens/private_map_screen.dart
  → adicionar long press handler para captura de coordenada
  → assistir marketingCasesProvider para renderizar pins
  → chamar NovoCaseSheet com lat/lng capturados
  → verificar plano antes de abrir sheet (planoAtivoProvider)

NÃO alterar:
  → NovoCaseSheet (contrato pronto)
  → MarketingCaseMarker (widget pronto)
  → marketing_providers.dart (provider pronto)
  → marketing_case.dart (entidade pronta)
