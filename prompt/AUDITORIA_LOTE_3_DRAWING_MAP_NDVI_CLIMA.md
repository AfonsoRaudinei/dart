# SOLOFORTE — AUDITORIA LOTE 3 — DRAWING, MAP, NDVI E CLIMA

**Modo:** READ-ONLY. Nenhum código de app foi alterado.  
**Bounded contexts:** `drawing`, `map`, `ndvi`, `clima`, `ui`  
**Prioridade:** P0/P1  
**Data:** 2026-08-10  

## Arquivos Avaliados

- `lib/modules/drawing/AGENTS.md`
- `lib/modules/map/AGENTS.md`
- `lib/modules/ndvi/AGENTS.md`
- `lib/modules/clima/AGENTS.md`
- `lib/ui/AGENTS.md`
- `lib/modules/drawing/presentation/controllers/drawing_controller.dart`
- `lib/modules/drawing/domain/services/gps_tracking_service.dart`
- `lib/modules/drawing/presentation/providers/drawing_provider.dart`
- `lib/modules/ndvi/presentation/providers/ndvi_providers.dart`
- `lib/modules/clima/presentation/providers/clima_providers.dart`
- `lib/modules/clima/presentation/widgets/radar_layer_widget.dart`
- `lib/ui/screens/map/widgets/map_performance_hosts.dart`
- `lib/ui/components/map/widgets/isolated_marker_layers.dart`
- `lib/ui/screens/map/widgets/map_build_orchestrator.dart`

## Limites

- Nao valida mapa em device, permissão GPS real, tile providers, radar real ou NDVI remoto.
- Nao valida performance por perfilamento; apenas sinais estáticos e testes existentes.

## Achados

```yaml
🟡 [Severidade: Média]
Categoria: E
Localização: lib/ui/screens/map/widgets/map_performance_hosts.dart:8-19
Problema: O arquivo importa `map_ui_providers.dart` duas vezes.
Risco: Mantém analyzer global falhando e indica baixa higiene justamente em arquivo de performance do mapa.
Direção da correção (conceitual, sem código): Remover duplicidade e manter imports agrupados por origem sem alterar comportamento.
Evidência: o mesmo import aparece nas linhas 8 e 19.
Validação necessária: flutter analyze lib/ui/screens/map/widgets/map_performance_hosts.dart.
```

```yaml
🟡 [Severidade: Média]
Categoria: A
Localização: lib/ui/screens/map/widgets/map_performance_hosts.dart:83-93
Problema: Sincronização entre `DrawingController` e `gpsWalkProvider` é disparada por `addPostFrameCallback` dentro de um `ListenableBuilder`.
Risco: Pode criar ciclo sutil entre ChangeNotifier, frame callbacks e provider Riverpod, causando rebuilds repetidos ou estado GPS divergente em caminhada.
Direção da correção (conceitual, sem código): Mover a sincronização para um listener/controlador dedicado com guarda de igualdade e lifecycle explícito, fora do build visual.
Evidência: `WidgetsBinding.instance.addPostFrameCallback((_) { ... syncFromController(points); });`
Validação necessária: teste de GPS walk com múltiplos pontos e inspeção de rebuild/performance.
```

```yaml
🟡 [Severidade: Média]
Categoria: D
Localização: lib/modules/clima/presentation/providers/clima_providers.dart:219-221
Problema: Coordenadas precisas de GPS são enviadas para log de debug.
Risco: Mesmo suprimido em release, debug/profile de QA pode capturar localização precisa do usuário ou propriedade.
Direção da correção (conceitual, sem código): Registrar apenas estado da fonte de localização ou coordenada grosseiramente arredondada/sanitizada, sem lat/lon exata.
Evidência: `AppLogger.debug('[CLIMA] GPS direto obtido: ${pos.latitude}, ${pos.longitude}', ...)`
Validação necessária: revisão de logs em debug/profile.
```

```yaml
🟡 [Severidade: Média]
Categoria: C
Localização: lib/modules/drawing/presentation/controllers/drawing_controller.dart:41 e tamanho total
Problema: `DrawingController` permanece como `ChangeNotifier` de 1736 linhas, ainda que com services extraídos.
Risco: Superfície grande para inconsistência entre estado de desenho, revisão, GPS, importação e seleção; mudanças pequenas podem afetar fluxos distantes.
Direção da correção (conceitual, sem código): Manter como exceção legada documentada enquanto reduz responsabilidades por extrações testadas, sem introduzir novo ChangeNotifier.
Evidência: `class DrawingController extends ChangeNotifier` e `wc -l` retornou 1736 linhas.
Validação necessária: arch_check.sh + testes de drawing.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: B
Localização: lib/modules/ndvi/presentation/providers/ndvi_providers.dart:27-30
Problema: NDVI consome `iFieldLookupProvider` em vez de importar drawing/consultoria diretamente.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Manter contrato ADR-042 e testes de lookup chain.
Evidência: provider do repositório recebe `fieldLookup = ref.watch(iFieldLookupProvider)`.
Validação necessária: testes NDVI existentes.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: D
Localização: lib/modules/clima/presentation/providers/clima_providers.dart:36-44
Problema: Ausência de chaves climáticas não tenta fallback secreto hardcoded.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Manter validação de injection secret-safe no release.
Evidência: quando `ClimaConfig` não tem chaves, lança `ClimaForecastUnavailableException`.
Validação necessária: teste de configuração sem chaves.
```

## RESUMO

Lote auditado: 3 — Drawing, Map, NDVI e Clima  
Bounded contexts: drawing, map, ndvi, clima, ui  
Arquivos avaliados: 14  
Total de achados: 6  
Alta severidade: 0  
Média severidade: 4  
Baixa severidade: 2  
Achados que exigem ADR novo: 0  
Achados que dependem de backend/RLS/device/build real: 2  
Nenhuma alteração de código foi feita — apenas diagnóstico.
