# DT-028 — showRadarProvider como proxy de MapContext.clima

**Data:** 22/04/2026
**Status:** ATIVO — DÍVIDA TÉCNICA CONTROLADA
**Originado em:** ADR-028 (RainViewer Radar Overlay)
**Tipo:** Desvio de contrato arquitetural (não-bloqueante)
**Bloqueante?** NÃO
**Prioridade:** BAIXA

---

## Contexto

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
| Testes | ✅ 645/645 passando |
| arch_check.sh | ✅ Exit 0 |
| flutter analyze | ✅ 0 erros |
| Contrato MapContext | ⚠️ Divergente — enum incompleto |

O impacto é **arquitetural, não funcional**. O radar funciona corretamente.
A divergência é que o mecanismo de ativação (bool toggle) não segue o
padrão enum de contexto do mapa.

---

## Condição de Remoção

Esta dívida é encerrada quando **todas** as condições forem atendidas:

1. `private_map_screen.dart` for decomposto (ADR futuro — arquivo ~955 linhas)
2. `MapContext.clima` for adicionado ao enum `MapContext` real
3. `showRadarProvider` for substituído por leitura de `mapContextProvider`
4. `RadarLayerWidget` for atualizado para consumir `MapContext.clima`
5. `TODO(DT-028)` removido dos arquivos marcados abaixo

---

## Arquivos com TODO(DT-028)

| Arquivo | Linha |
|---|---|
| `lib/core/state/map_ui_providers.dart` | bloco antes de `showRadarProvider` |
| `lib/ui/components/map/widgets/radar_layer_widget.dart` | topo do arquivo |

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
| B4 | `map_ui_providers.dart` tem `showRadarProvider`? | SIM | ✅ |
| B5 | `showRadarProvider` é `StateProvider<bool>.autoDispose`? | SIM | ✅ |
| B6 | `map_controls_overlay.dart` tem botão de radar? | SIM | ✅ |
| B7 | Botão usa `Icons.water_drop_outlined`? | SIM | ✅ |
| B8 | `private_map_screen.dart` importa `RadarLayerWidget`? | SIM | ✅ |
| B9 | `RadarLayerWidget` posicionado após camadas base, antes de markers? | SIM | ✅ linha 720 (MapLayersWidget=717, PolygonLayer=724) |
| B10 | `private_map_screen.dart` abaixo de 900 linhas? | SIM | ⚠️ 955 linhas — ver ACHADO-001 |

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
| D2 | `MapContext.clima` existe? | ❌ NÃO EXISTE |
| D3 | `showRadarProvider` é divergência do contrato arquitetural? | ✅ SIM — registrado como DT-028 |
| D4 | Impacto funcional do desvio? | ✅ NENHUM — funciona corretamente |
| D5 | TODO(DT-028) inserido nos arquivos relevantes? | ✅ SIM |

---

## Achados Não-Bloqueantes

### ACHADO-001 — `http` em vez de `dio`
**Severidade:** 🟡 MÉDIO
**Arquivo:** `lib/ui/components/map/providers/rainviewer_provider.dart`
**Descrição:** O ADR-028 especificava uso de `dio`, mas o projeto não tem `dio` — apenas `http: ^1.6.0`. O agente usou `http` corretamente.
**Ação:** Nenhuma. Consistente com o projeto.

### ACHADO-002 — `private_map_screen.dart` com 955 linhas
**Severidade:** 🟡 MÉDIO (limite arquitetural = 900)
**Arquivo:** `lib/ui/screens/private_map_screen.dart`
**Descrição:** Arquivo está 55 linhas acima do limite de 900. Condição pré-existente ao ADR-028 (estava em 950 antes, passou para 955 com o wiring do radar).
**Ação:** Registrar. Endereçar no ADR de decomposição de `private_map_screen.dart` (vinculado à condição de remoção desta DT).

---

## Rastreabilidade

| Campo | Valor |
|---|---|
| ADR de origem | ADR-028 |
| ADR de remoção | A definir (decomposição private_map_screen) |
| Identificado em | Auditoria ADR-028 — 22/04/2026 |
| Prioridade de remoção | Sprint com decomposição de `private_map_screen.dart` |
