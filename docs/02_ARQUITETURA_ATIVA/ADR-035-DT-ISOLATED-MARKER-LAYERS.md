# ADR-035 — Dívida Técnica: `ui/components/map` conhece política de visibilidade de marketing

**Status:** PROPOSTO  
**Data:** 2026-05-18  
**Origem:** Auditoria Arquitetural Parte 3  
**Tag:** `DT-035-isolated-marker-layers-marketing`

---

## Contexto

Durante a auditoria pré-release v1.1, foi identificado acoplamento direto de
`lib/ui/components/map/widgets/isolated_marker_layers.dart` com o domínio de
marketing para decidir a visibilidade de marcadores no mapa.

O arquivo já conhecia providers e widgets de marketing. A alteração auditada
adiciona também conhecimento semântico do enum `PlanoMarketing`:

```dart
import '../../../../modules/marketing/domain/enums/plano_marketing.dart';

final tier = (c.visibilidade as PlanoMarketing);
return switch (tier) {
  PlanoMarketing.ouro => currentZoom >= _zoomMinOuro,
  PlanoMarketing.prata => currentZoom >= _zoomMinPrata,
  PlanoMarketing.bronze => currentZoom >= _zoomMinBronze,
};
```

## Problema

1. `ui/components/map` passa a conhecer detalhes internos de `modules/marketing`.
2. A regra de visibilidade de marcador por tier e zoom fica implementada na camada de UI.
3. Mudanças futuras em `PlanoMarketing` podem quebrar o mapa.
4. O padrão cria precedente para novos acoplamentos diretos entre `ui/` e módulos de domínio.

## Decisão

Registrar como dívida técnica moderada e aceitar temporariamente para v1.1.

Esta dívida nao bloqueia o release porque:

- e acoplamento de leitura, sem escrita em estado de marketing;
- nao introduz dado ficticio;
- nao altera contrato publico de `MarketingCase`;
- o fluxo existente de mapa/marketing ja possuia acoplamentos diretos nesta area.

Esta ADR nao autoriza novos acoplamentos equivalentes. Novas regras de negocio de
marketing nao devem ser adicionadas em `ui/components/map`.

## Solução Futura

A solucao preferida e extrair a decisao de visibilidade para contrato neutro ou
DTO de fronteira.

### Opcao A: Politica neutra de visibilidade

```dart
abstract class IMarketingMarkerVisibilityPolicy {
  bool shouldShowAtZoom({
    required String visibilityTier,
    required double zoom,
  });
}
```

### Opcao B: DTO neutro para o mapa

```dart
class MarketingMarkerSummary {
  final String id;
  final double lat;
  final double lng;
  final String visibilityTier;
}
```

Neste modelo, `marketing` transforma seus cases em summaries neutros, e o mapa
nao importa `PlanoMarketing`, providers ou widgets internos do modulo.

## Impacto

**Atual:**

- Arquivo afetado: `lib/ui/components/map/widgets/isolated_marker_layers.dart`
- Acoplamento principal: `ui/components/map -> modules/marketing`
- Natureza: leitura e apresentacao

**Risco futuro se nao migrar:**

- dificuldade de testar `isolated_marker_layers.dart` isoladamente;
- mudancas em tiers de marketing exigirem alteracao direta no mapa;
- crescimento de regras de marketing em camada de UI;
- enfraquecimento das fronteiras declaradas em `bounded_contexts.md`.

## Timeline

- **v1.1:** aceitar e registrar a divida.
- **v1.2:** criar contrato ou DTO neutro de marker summary/visibility policy.
- **v1.3:** migrar `isolated_marker_layers.dart` para consumir somente contrato neutro.

## Relacionados

- ADR-025 — `map/` como bounded context agregador
- ADR-027 — Padrao visual unificado e bottom sheets
- DT-025-3 — `map -> visitas` direto
- Auditoria Arquitetural Parte 2 — acoplamentos laterais

## Checklist

- [ ] Aceitar divida para v1.1
- [ ] Criar issue para v1.2
- [ ] Atualizar `bounded_contexts.md` com violacao conhecida ou excecao temporaria
- [ ] Definir contrato neutro de visibilidade de marcador de marketing
