# DT-028 — showRadarProvider como proxy de MapContext.clima

**Data:** 22/04/2026
**Status:** ENCERRADO DEFINITIVAMENTE — ADR-043 (Jun/2026)
**Originado em:** ADR-028 (RainViewer Radar Overlay)
**Encerrado em:** Jun/2026 via migração para `clima/` + `IRadarOverlayController`

---

## Resolução final (ADR-043)

- Radar vive em `lib/modules/clima/` (`radar_providers.dart`, `ClimaRadarLayerWidget`)
- Toggle: `climaRadarEnabledProvider` (nao `ArmedMode`, nao `showRadarProvider`)
- Fronteira mapa ↔ clima: `IRadarOverlayController` em `core/contracts/`
- `ArmedMode.clima` **nunca existiu** no codebase — docs corrigidos

Ver: `docs/02_ARQUITETURA_ATIVA/ADR-043-RADAR-OVERLAY-CONTRACT.md`

---

## Contexto Histórico (arquivo)

Durante a execução do ADR-028, o agente verificou que `MapContext.clima`
não existe como valor no enum `MapContext` do codebase atual.

O contrato arquitetural em `arquitetura-navegacao.md` define:

```dart
enum MapContext {
  tecnico,
  clima,       // ← não existe no codebase real
  ocorrencias,
  publicacoes,
  ndvi,
}
```

Para não bloquear a entrega do radar de precipitação, o agente adotou
`showRadarProvider` (`StateProvider.autoDispose<bool>`) como mecanismo
de toggle, isolado ao contexto do mapa.

---

## Impacto

| Aspecto | Estado |
|---|---|
| Funcionalidade de radar | ✅ Funcional |
| Testes | ✅ 649/649 passando |
| arch_check.sh | ✅ Exit 0 |
| flutter analyze | ✅ 0 erros |
| Contrato MapContext | ✅ Resolvido via `ArmedMode.clima` |

O impacto foi **arquitetural, não funcional**. O radar funcionava corretamente.
A divergência foi removida substituindo o toggle booleano por estado de contexto
do mapa em `ArmedMode.clima`.

---

## Condição de Remoção

Esta dívida foi encerrada porque as condições aplicáveis ao codebase real foram
atendidas:

1. `private_map_screen.dart` foi decomposto e está com 373 linhas
2. O enum real do mapa (`ArmedMode`) recebeu `clima`
3. `showRadarProvider` foi substituído por leitura de `armedModeProvider`
4. `RadarLayerWidget` foi atualizado para consumir `ArmedMode.clima`
5. Não há provider ativo chamado `showRadarProvider`

---

## Arquivos Relevantes

| Arquivo | Linha |
|---|---|
| `lib/ui/screens/map/providers/map_armed_mode_provider.dart` | `enum ArmedMode { none, occurrences, marketing, clima }` |
| `lib/ui/components/map/widgets/radar_layer_widget.dart` | consome `armedModeProvider == ArmedMode.clima` |
| `lib/ui/components/map/map_sheets.dart` | toggle de chuva alterna `ArmedMode.none`/`ArmedMode.clima` |

---

## Achados da Auditoria (22/04/2026)

### A — Arquivos criados

| # | Verificação | Esperado | Resultado |
|---|---|---|---|
| A1 | `rainviewer_provider.dart` existe? | SIM | ✅ `lib/ui/components/map/providers/` |
| A2 | Usa `@riverpod` com autoDispose? | SIM | ✅ `FutureProvider.autoDispose` |
| A3 | Retorna `String?` (null em erro)? | SIM | ✅ |
| A4 | Usa `dio` (não `http` package)? | SIM | ⚠️ Usa `http` (dio ausente no projeto) — ver abaixo |
| A5 | Trata exceção de rede sem throw? | SIM | ✅ `catch (_) → return null` |
| A6 | `radar_layer_widget.dart` existe? | SIM | ✅ `lib/ui/components/map/widgets/` |
| A7 | É `ConsumerWidget`? | SIM | ✅ |
| A8 | Retorna `SizedBox.shrink()` quando inactive/null? | SIM | ✅ |
| A9 | Opacidade = 0.6 (ou constante de MapConfig)? | SIM | ✅ `MapConfig.radarOverlayOpacity` |
| A10 | `rainviewer_provider_test.dart` existe? | SIM | ✅ `test/ui/components/map/` |
| A11 | 5 testes presentes? | SIM | ✅ 5 testes passando |

### B — Arquivos modificados

| # | Verificação | Esperado | Resultado |
|---|---|---|---|
| B1 | `map_config.dart` tem `rainViewerApiUrl`? | SIM | ✅ |
| B2 | `map_config.dart` tem `rainViewerTileBase`? | SIM | ✅ |
| B3 | `map_config.dart` tem `radarOverlayOpacity`? | SIM | ✅ |
| B4 | `showRadarProvider` removido como provider ativo? | SIM | ✅ |
| B5 | `armedModeProvider` tem `ArmedMode.clima`? | SIM | ✅ |
| B6 | `map_controls_overlay.dart` tem botão de radar? | SIM | ✅ |
| B7 | Botão usa `Icons.water_drop_outlined`? | SIM | ✅ |
| B8 | `private_map_screen.dart` importa `RadarLayerWidget`? | SIM | ✅ |
| B9 | `RadarLayerWidget` posicionado após camadas base, antes de markers? | SIM | ✅ linha 720 (MapLayersWidget=717, PolygonLayer=724) |
| B10 | `private_map_screen.dart` abaixo de 900 linhas? | SIM | ✅ 373 linhas |

### C — Isolamento de módulos

| # | Verificação | Esperado | Resultado |
|---|---|---|---|
| C1 | Nenhum arquivo em `lib/modules/` tocado? | SIM | ✅ grep retornou vazio |
| C2 | Nenhuma importação de módulo externo nos novos arquivos? | SIM | ✅ |
| C3 | `arch_check.sh` Exit 0 confirmado? | SIM | ✅ |
| C4 | `flutter analyze` = 0 erros? | SIM | ✅ |
| C5 | 645/645 testes passando? | SIM | ✅ |

### D — Desvio arquitetural

| # | Verificação | Estado |
|---|---|---|
| D1 | `MapContext` enum existe no codebase? | ❌ NÃO EXISTE |
| D2 | `ArmedMode.clima` existe? | ✅ SIM |
| D3 | `showRadarProvider` é divergência ativa? | ❌ NÃO — encerrado |
| D4 | Impacto funcional do desvio? | ✅ NENHUM — funciona corretamente |
| D5 | TODO(DT-028) ativo? | ❌ NÃO |

---

## Achados Não-Bloqueantes

### ACHADO-001 — `http` em vez de `dio`
**Severidade:** 🟡 MÉDIO
**Arquivo:** `lib/ui/components/map/providers/rainviewer_provider.dart`
**Descrição:** O ADR-028 especificava uso de `dio`, mas o projeto não tem `dio` — apenas `http: ^1.6.0`. O agente usou `http` corretamente.
**Ação:** Nenhuma. Consistente com o projeto.

### ACHADO-002 — `private_map_screen.dart` decomposto
**Severidade:** ✅ RESOLVIDO
**Arquivo:** `lib/ui/screens/private_map_screen.dart`
**Descrição:** Arquivo está com 373 linhas em Mai/2026.
**Ação:** Nenhuma.

---

## Rastreabilidade

| Campo | Valor |
|---|---|
| ADR de origem | ADR-028 |
| ADR de remoção | ADR-030/ADR-031 |
| Identificado em | Auditoria ADR-028 — 22/04/2026 |
| Encerrado em | Mai/2026 |
