# DIAGNÓSTICO GNSS — SoloForte (Multi-Constelação)

**Tipo:** Auditoria somente leitura — Julho/2026  
**Status:** Concluído — nenhum código alterado  
**Agente:** Engenheiro Sênior Flutter/Dart

---

## PASSO 0 — Saída dos comandos

### Arquivos localizados (`find`)

| Padrão | Arquivos relevantes |
|---|---|
| `*location*` | `location_service.dart`, `location_providers.dart`, `location_state.dart`, `map_location_handler.dart`, `location_permission_gate.dart`, `location_lookup_adapter.dart`, `map_controls_location_button.dart`, `public_location_provider.dart`, `map_location_mode_provider.dart`, `i_user_location_lookup.dart` |
| `*geofence*` | `geofence_controller.dart`, `geofence_state.dart`, `field_lookup_geofence_adapter.dart` |
| `*gps*` | `gps_tracking_service.dart`, `drawing_gps_orchestrator.dart`, `gps_walk_controller.dart`, overlays/widgets drawing |
| `*geolocator*` | Uso via import direto em ~8 arquivos (sem wrapper único além de `LocationService`) |

### `pubspec.yaml`

```
geolocator: ^13.0.2
```

### `pubspec.lock`

| Pacote | Versão |
|---|---|
| `geolocator` | **13.0.4** |
| `geolocator_android` | 4.6.2 |
| `geolocator_apple` | (transitive) |

### iOS `Info.plist`

- `NSLocationWhenInUseUsageDescription` — ✅ presente
- `NSLocationAlwaysAndWhenInUseUsageDescription` — ✅ presente
- `NSLocationAlwaysUsageDescription` — ❌ ausente (legado iOS <11, N/A)
- `UIBackgroundModes` → `location` — ❌ ausente

### Android `AndroidManifest.xml`

- `ACCESS_FINE_LOCATION` — ✅
- `ACCESS_COARSE_LOCATION` — ✅
- `ACCESS_BACKGROUND_LOCATION` — ❌ ausente
- `FOREGROUND_SERVICE` — ✅
- `FOREGROUND_SERVICE_LOCATION` — ✅

### Baseline CI

- `./tool/arch_check.sh` → Exit 0 (partida OK)

---

## Relatório consolidado

```
📍 RELATÓRIO GNSS — SoloForte
================================

1. PACOTE: geolocator v13.0.4 (constraint ^13.0.2)
2. WRAPPER: LocationService (dashboard/services/location_service.dart)
           + uso direto Geolocator em drawing/clima/public/agenda

3. ACURÁCIA CONFIGURADA (valores REAIS por contexto):
   - Mapa principal (stream): LocationAccuracy.high, distanceFilter: 5m
   - getCurrentPosition (mapa): LocationAccuracy.high
   - Desenho GPS polígono: LocationAccuracy.best, distanceFilter: 2m
   - GPS walk drawing: LocationAccuracy.high
   - Mapa público: LocationAccuracy.high, distanceFilter: 10m
   - Clima: LocationAccuracy.medium
   - Agenda (visit form): LocationAccuracy.high

4. FORCE ANDROID LOCATION MANAGER: false (não configurado — default geolocator)

5. PERMISSÕES iOS:
   - WhenInUse: ✅
   - AlwaysAndWhenInUse: ✅
   - Always (legado): N/A
   - Background Mode (location): ❌ (geofence roda foreground no mapa)

6. PERMISSÕES ANDROID:
   - FINE_LOCATION: ✅
   - COARSE_LOCATION: ✅
   - BACKGROUND_LOCATION: N/A (não declarada)
   - FOREGROUND_SERVICE + LOCATION: ✅

7. MULTI-CONSTELAÇÃO:
   - Restrição artificial encontrada: NÃO
   - forceAndroidLocationManager / LocationManager legado: NÃO
   - GnssStatus / GpsStatus / provider manual: NÃO
   - FusedLocation ativo: SIM (default geolocator_android ≥4.x)
   - Conclusão: ✅ Suporte implícito OK via OS + chipset
     (GPS+GLONASS+BeiDou+Galileo agregados pelo OS quando FINE + GNSS ativo)

8. CONSUMIDORES: ~22 arquivos utilizam posição/GPS

9. UX GNSS:
   - Indicador precisão real (metros): ⚠️ PARCIAL
     • Drawing GPS: badge ±Xm + qualidade (excelente/aceitável/ruim)
     • Medição talhão: "GPS: ±X m" no overlay
     • Pin do usuário no mapa: anel fixo 12m (NÃO usa position.accuracy)
   - Cor ícone GPS (disponível/indisponível): ✅ (_LocationButton verde/cinza)
   - Satélites / constelação: ❌ ausente (OK — não necessário)

10. GAPS IDENTIFICADOS:
    - LocationService descarta position.accuracy — stream só emite LatLng
    - Mapa principal usa LocationAccuracy.high (não best/bestForNavigation)
    - Anel de precisão do pin fixo em 12m (visual, não GNSS real)
    - Sem background location (intencional — geofence foreground)

11. AÇÕES SUGERIDAS (aguardam aprovação):
    - [Opcional P1] Elevar stream principal para LocationAccuracy.best
      em LocationService (check-in/geofence/mapa)
    - [Opcional P2] Propagar position.accuracy no stream ou provider
      paralelo para UX real no pin do mapa
    - [Opcional P3] Unificar política de acurácia (tabela por contexto)
    - NÃO necessário: SDK por constelação, GnssStatus API, nova permissão
      background (a menos que geofence passe a rodar em background)
```

---

## PASSO 1 — Inventário do pacote

| Pergunta | Resposta |
|---|---|
| Pacote exato | `geolocator` |
| Versão lock | **13.0.4** |
| Wrapper próprio? | **Sim** — `LocationService` (singleton stream) + chamadas diretas em módulos específicos |

Suporte multi-constelação: **delegado ao OS** via `geolocator` ≥9.x — confirmado.

---

## PASSO 2 — Configuração de acurácia

| Contexto | Arquivo | desiredAccuracy | distanceFilter | timeInterval |
|---|---|---|---|---|
| Mapa (stream) | `location_service.dart` | `high` | **5m** | não definido |
| Mapa (one-shot) | `location_service.dart` | `high` | — | timeout 10s |
| Desenho polígono | `drawing_gps_orchestrator.dart` | **`best`** | **2m** | — |
| GPS walk | `gps_walk_controller.dart` | `high` | — | — |
| Mapa público | `public_location_provider.dart` | `high` | **10m** | — |
| Clima | `clima_providers.dart` | `medium` | — | — |
| Agenda form | `visit_form_dialog.dart` | `high` | — | — |
| forceAndroidLocationManager | — | **não referenciado** | — | — |

**Observação:** `LocationAccuracy.high` ainda usa GNSS multi-constelação no Android (FINE + FusedLocation). Não bloqueia GLONASS/BeiDou/Galileo. Pode limitar agressividade de precisão vs `best`/`bestForNavigation`.

---

## PASSO 3 — Permissões nativas

### iOS

| Chave | Status |
|---|---|
| `NSLocationWhenInUseUsageDescription` | ✅ |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | ✅ |
| `NSLocationAlwaysUsageDescription` | N/A |
| `UIBackgroundModes` → `location` | ❌ N/A (sem tracking background) |

### Android

| Permissão | Status |
|---|---|
| `ACCESS_FINE_LOCATION` | ✅ **Crítico OK** |
| `ACCESS_COARSE_LOCATION` | ✅ |
| `ACCESS_BACKGROUND_LOCATION` | N/A |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` | ✅ |

---

## PASSO 4 — Multi-constelação no nível OS

| Verificação | Resultado |
|---|---|
| `forceAndroidLocationManager` | Não encontrado |
| `GnssStatus` / `GpsStatus` | Não encontrado |
| Limitação artificial de provider | **Não** |
| Mecanismo Android | FusedLocationProvider (default geolocator_android) |
| Mecanismo iOS | CLLocationManager via geolocator_apple |

**Conclusão técnica:** O app **não escolhe** constelação. Com `ACCESS_FINE_LOCATION` + `Geolocator.getPositionStream/getCurrentPosition`, o OS agrega todas as constelações suportadas pelo chipset.

---

## PASSO 5 — Consumidores de localização

| Consumidor | Arquivo | Uso | Acurácia necessária |
|---|---|---|---|
| Mapa principal | `private_map_screen.dart` → `LocationService` | Centralizar / pin usuário | Best (atual: high) |
| Geofence check-in | `geofence_controller.dart` | Proximidade talhão (buffer 300m) | Best (herda high do stream) |
| Ocorrências | `private_map_screen.dart` / `map_ui_providers` | Georreferenciar ponto | Best |
| Desenho talhão | `drawing_gps_orchestrator.dart` | Vértices polígono | **best** ✅ |
| Medição campo | `map_controls_measurement.dart` | Área/perímetro + ±GPS | best (via drawing) |
| Mapa público | `public_location_provider.dart` | Posição anônima | high |
| Clima | `clima_providers.dart` | Previsão local | medium (OK) |
| Agenda AI | `map_agenda_ai_button.dart` | Contexto launch GPS | high (via providers) |
| IUserLocationLookup | `location_lookup_adapter.dart` | Contrato settings/clima | high |

---

## PASSO 6 — UX GNSS

| Elemento | Recomendado | Implementado |
|---|---|---|
| Precisão em metros | ✅ | ⚠️ Drawing/sim — mapa usa valor fixo 12m |
| Cor ícone GPS | ✅ | ✅ `_LocationButton` (available/active) |
| Satélites conectados | Opcional | ❌ |
| Nome constelação | ❌ | ❌ (correto) |

---

## Encerramento

> A auditoria GNSS do SoloForte foi concluída.  
> Nenhum módulo, rota, estado ou contrato foi alterado.  
> Multi-constelação: **suporte implícito OK** — OS + FINE_LOCATION + geolocator.  
> Gaps são de **precisão configurada** e **UX de accuracy**, não de bloqueio GNSS.  
> Ações corretivas aguardam aprovação de Raudinei.
