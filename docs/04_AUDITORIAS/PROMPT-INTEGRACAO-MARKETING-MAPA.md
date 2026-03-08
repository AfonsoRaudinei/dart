# PROMPT — Integração Marketing Cases + Mapa

**PROMPT BASE ATIVO**
**@MÓDULO: NAVEGACAO_MAP_FIRST**
**@MÓDULO: ESTADO_RIVERPOD**

Projeto: SoloForte App
Baseline: v1.2
ADR de referência: ADR-011 (revisado), ADR-012 (planos/)
Tipo: FEATURE — RISCO MÉDIO

---

## MÓDULO AFETADO

`map/` — arquivo: `lib/ui/screens/private_map_screen.dart`

---

## OBJETIVO

Integrar o módulo marketing/ ao mapa: capturar coordenada via long press,
verificar plano ativo, abrir NovoCaseSheet com lat/lng capturados,
e renderizar os MarketingCaseMarkers dos cases existentes sobre o mapa.

---

## DECLARAÇÕES OBRIGATÓRIAS

- Altera contrato de interface? NÃO
- Altera fronteira entre módulos? NÃO (map/ já pode depender de marketing/)
- Cria novo bounded context? NÃO
- Altera NovoCaseSheet? NÃO — contrato já está pronto
- Altera marketing_providers.dart? NÃO

---

## O QUE JÁ EXISTE — NÃO REESCREVER

```dart
// lib/modules/marketing/presentation/screens/novo_case_sheet.dart
class NovoCaseSheet extends StatefulWidget {
  final double lat;        // já existe
  final double lng;        // já existe
  final VoidCallback onClose;
  final void Function(MarketingCase) onPublicar;
}

// lib/modules/marketing/presentation/widgets/marketing_case_marker.dart
// Widget do pin — já existe, usar diretamente

// lib/modules/marketing/presentation/providers/marketing_providers.dart
final marketingCasesProvider = StateNotifierProvider<...>
// publishCase(), load(), retryPendingCases() — já implementados

// lib/modules/planos/presentation/providers/plano_providers.dart
final planoAtivoProvider  // keepAlive: true — ADR-012
```

---

## PASSO 1 — Renderizar pins no mapa

Em `private_map_screen.dart`, assistir `marketingCasesProvider` e
renderizar `MarketingCaseMarker` para cada case ativo:

```dart
// Dentro do build() de private_map_screen
final casesAsync = ref.watch(marketingCasesProvider);

// Na camada de markers do mapa:
casesAsync.whenData((cases) {
  for (final c in cases.where((c) => c.ativo && c.deletadoEm == null)) {
    // adicionar MarketingCaseMarker ao mapa com c.lat, c.lng, c.visibilidade
  }
});
```

Pins ouro renderizam acima dos demais (zIndex 3 > 2 > 1).
Toque em pin existente → showModalBottomSheet com MarketingCaseSheet
(widget já existente em marketing/presentation/widgets/marketing_case_sheet.dart).

---

## PASSO 2 — Captura de coordenada via long press

Adicionar handler de long press no widget do mapa:

```dart
onLongPress: (LatLng latLng) {
  _handleMapLongPress(latLng);
}
```

Implementar `_handleMapLongPress`:

```dart
void _handleMapLongPress(LatLng latLng) {
  final plano = ref.read(planoAtivoProvider).valueOrNull;

  // Sem plano → bottom sheet de bloqueio
  if (plano == null || !plano.ativo) {
    _showPlanoBlockSheet();
    return;
  }

  // Verificar limite de cases por plano
  final cases = ref.read(marketingCasesProvider).valueOrNull ?? [];
  final casesAtivos = cases.where((c) => c.ativo && c.deletadoEm == null).length;
  final limite = plano.limiteCases; // bronze=1, prata=2, ouro=3

  if (casesAtivos >= limite) {
    _showLimiteAtingidoSheet(plano);
    return;
  }

  // Abre NovoCaseSheet com a coordenada capturada
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => NovoCaseSheet(
      lat: latLng.latitude,
      lng: latLng.longitude,
      onClose: () => Navigator.of(context).pop(),
      onPublicar: (newCase) {
        ref.read(marketingCasesProvider.notifier).publishCase(newCase);
        Navigator.of(context).pop();
      },
    ),
  );
}
```

---

## PASSO 3 — Bottom sheets de bloqueio (já existem — reutilizar)

Os métodos `_showPlanoBlockSheet()` e `_showLimiteAtingidoSheet()` foram
extraídos para `lib/ui/screens/widgets/plano_block_sheet.dart` na sprint
anterior. Importar e reutilizar — NÃO recriar.

---

## REGRAS MAP-FIRST — OBRIGATÓRIAS

- Long press NÃO navega para outra rota
- NovoCaseSheet abre como bottom sheet SOBRE o mapa — mapa não some
- URL permanece /map durante todo o fluxo
- SmartButton NÃO muda (continua ☰ no /map)
- Fechar o sheet: Navigator.of(context).pop() é permitido aqui
  porque não estamos navegando entre rotas — apenas fechando modal
- NÃO usar context.go() para fechar modal
- NÃO criar sub-rota de /map

---

## ESTADO RIVERPOD

- marketingCasesProvider: StateNotifier existente — usar ref.watch() para
  rebuild ao adicionar novo case
- planoAtivoProvider: usar ref.read() no handler (leitura pontual,
  não precisa de rebuild)

---

## ARQUIVOS TOCADOS

```
lib/ui/screens/private_map_screen.dart   → adicionar long press + render pins
```

NÃO tocar:
```
lib/modules/marketing/                   → tudo intacto
lib/modules/planos/                      → tudo intacto
lib/core/                                → nada
app_router.dart                          → nada
```

---

## MAP-FIRST CHECK

- Move raiz funcional? NÃO
- Altera nível de navegação? NÃO
- Cria sub-rota de /map? NÃO
- URL muda durante o fluxo? NÃO — permanece /map
- SmartButton alterado? NÃO
- Usa context.go()? NÃO — não há navegação de rota

---

## RISCO

Classificação: MÉDIO
Motivo: Altera private_map_screen.dart que é arquivo central.
Mitgação: arquivo está em 870 linhas (abaixo de 900). Adição é localizada.

---

## VALIDAÇÃO FINAL

- [ ] Pins renderizam sobre o mapa ao carregar
- [ ] Long press captura coordenada corretamente
- [ ] Sem plano → abre bottom sheet de bloqueio
- [ ] Com plano no limite → abre bottom sheet de limite
- [ ] Com plano disponível → abre NovoCaseSheet com lat/lng corretos
- [ ] Após publicar → pin aparece no mapa sem reload manual
- [ ] URL permanece /map durante todo o fluxo
- [ ] SmartButton inalterado
- [ ] private_map_screen.dart abaixo de 900 linhas após alteração
- [ ] flutter analyze → 0 erros
- [ ] arch_check.sh → Exit 0

---

## ENCERRAMENTO PADRÃO

O módulo map/ foi integrado ao marketing/ conforme ADR-011 revisado.
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.
