# PROMPT CODEX — Resolver Merge Falho + Portar GNSS em `release/build-156`

**Perfil:** Engenheiro Sênior Flutter/Dart — Top 0,1%  
**Tipo:** IMPLEMENTAÇÃO CIRÚRGICA — não fazer merge cego de `main`  
**Data:** Jul/2026  
**Ambiente:** MacBook — pasta `appdart`  
**Branch alvo:** `release/build-156`  
**Destino:** executar no Codex / Cursor Desktop local  

---

## 0️⃣ CONTEXTO — O QUE ACONTECEU

O usuário tentou:

```bash
git merge origin/main
```

na branch `release/build-156` e obteve **30+ conflitos**.

### Causa raiz (NÃO é bug do Git)

| Branch | Arquitetura | Estado |
|---|---|---|
| `origin/main` | Legada — `LocationController`, estrutura antiga | GNSS P2/P3 implementado aqui |
| `release/build-156` | Refatorada — `LocationService`, `LocationStateNotifier`, módulo `drawing/` | **Mais avançada** — já tem stream GNSS + `UserLocationFix` |

**Conclusão:** `main` e `release/build-156` divergiram massivamente (~1330 arquivos).  
**NÃO fazer merge de `origin/main` inteiro.** Portar apenas o que falta.

---

## 1️⃣ REGRAS ABSOLUTAS

❌ Não completar o merge atual de `origin/main`  
❌ Não aceitar versão `main` em arquivos `deleted by us`  
❌ Não reescrever `LocationStateNotifier` (já existe em `release/build-156`)  
❌ Não mover módulo `drawing/`  
❌ Não usar `google_maps_flutter`  
❌ Não inventar dados  

✅ Abortar merge primeiro  
✅ Portar GNSS cirurgicamente na arquitetura `release/build-156`  
✅ Executar todos os comandos no terminal local  
✅ `flutter analyze` + testes afetados ao final  

---

## 2️⃣ PASSO 0 — RECUPERAR REPOSITÓRIO (OBRIGATÓRIO)

Executar no terminal, dentro de `appdart`:

```bash
cd ~/appdart   # ou caminho real do projeto

# Abortar merge quebrado
git merge --abort

# Confirmar estado limpo de merge
git status

# Restaurar WIP (se stash existir)
git stash list
git stash pop   # só se listar "WIP antes sync main"

# Confirmar branch
git branch --show-current
# Esperado: release/build-156
```

**Gate:** `git status` não pode mostrar `unmerged paths`.

---

## 3️⃣ INVENTÁRIO — O QUE JÁ EXISTE EM `release/build-156`

Verificar antes de implementar:

```bash
rg -l "LocationService|UserLocationFix|gpsAccuracyM" lib/
```

| Feature GNSS | `main` (cloud) | `release/build-156` (Mac) |
|---|---|---|
| Stream GNSS | `LocationController` | ✅ `LocationService` + `locationStreamProvider` |
| Precisão em metros | `locationAccuracyProvider` | ✅ `UserLocationFix.accuracyM` |
| UI ±Xm no mapa | `private_map_screen.dart` | ✅ `MapControlsOverlay.gpsAccuracyM` |
| `LocationStateNotifier` | ❌ (usa StateProvider) | ✅ Já existe |
| Módulo drawing refatorado | ❌ | ✅ `lib/modules/drawing/` |
| `location_settings.dart` unificado | ✅ | ❌ **FALTA portar** |
| `bestForNavigation` | ✅ | ⚠️ Usa `best` + `distanceFilter: 5` |
| Bloqueio check-in >30m | ✅ | ❌ **FALTA portar** |
| Geofence settings unificados | ✅ | ⚠️ Verificar e alinhar |
| Docs agente `prompt/` | ✅ | ❌ **FALTA copiar** (arquivos novos, sem conflito) |

---

## 4️⃣ ESCOPO DE IMPLEMENTAÇÃO (CIRÚRGICO)

### 4.1 Criar `lib/modules/dashboard/domain/location_settings.dart`

Portar de `origin/main` adaptando para a arquitetura release:

```dart
import 'package:geolocator/geolocator.dart';

const LocationAccuracy soloforteGnssAccuracy = LocationAccuracy.bestForNavigation;
const int soloforteGnssDistanceFilter = 5; // release usa 5m — MANTER 5, não 10

const LocationSettings soloforteGnssLocationSettings = LocationSettings(
  accuracy: soloforteGnssAccuracy,
  distanceFilter: soloforteGnssDistanceFilter,
);

const double soloforteGnssMaxCheckInAccuracyMeters = 30;

bool isGnssAccuracyAcceptableForCheckIn(double? accuracyMeters) {
  if (accuracyMeters == null) return false;
  return accuracyMeters <= soloforteGnssMaxCheckInAccuracyMeters;
}

LocationSettings soloforteGnssLocationSettingsWithTimeout(Duration timeLimit) {
  return LocationSettings(
    accuracy: soloforteGnssAccuracy,
    distanceFilter: soloforteGnssDistanceFilter,
    timeLimit: timeLimit,
  );
}
```

> **Nota:** `distanceFilter: 5` é intencional — release já otimizou para agro (campo parado = zero rebuild).

---

### 4.2 Atualizar `LocationService` para usar settings unificados

Arquivo: `lib/modules/dashboard/services/location_service.dart`

- Substituir `LocationSettings` inline por `soloforteGnssLocationSettings`
- Manter singleton e stream broadcast
- Não alterar assinatura pública

---

### 4.3 Bloqueio check-in >30m

Localizar onde o check-in inicia (provável fluxo):

```
MapControlsOverlay → map_sheet_controller → visit_sheet → visit_controller.startSession
```

**Antes** de abrir `VisitSheet` ou chamar `startSession`:

1. Ler precisão atual de `locationStreamProvider` ou `UserLocationFix`
2. Se `!isGnssAccuracyAcceptableForCheckIn(accuracyM)`:
   - Exibir SnackBar vermelho:
     > "Precisão GPS insuficiente (±Xm). Aguarde sinal melhor ou vá para área aberta para fazer check-in."
   - **Não** abrir sheet de visita

**Encerrar visita ativa:** não bloquear.

Arquivos prováveis (auditar com `rg`):

```bash
rg -n "onShowStartSheet|handleCheckInTap|startSession|VisitSheet" lib/
```

---

### 4.4 Alinhar GeofenceController

Arquivo: `lib/modules/visitas/presentation/controllers/geofence_controller.dart`

- Release já usa `UserLocationFix` via stream — **não reverter**
- Se houver `getCurrentPosition` pontual, usar `soloforteGnssLocationSettingsWithTimeout(Duration(seconds: 10))`

---

### 4.5 Copiar docs do agente (sem conflito)

Trazer da `origin/main` apenas arquivos **novos**:

```bash
git checkout origin/main -- prompt/AGENT_MEMORIA.md
git checkout origin/main -- prompt/AGENT_REGRAS.md
git checkout origin/main -- prompt/FLUXO_OFICIAL_CURSOR_DESKTOP.md
git checkout origin/main -- docs/CURSOR_DESKTOP_SYNC.md
git checkout origin/main -- .cursor/rules/agent-terminal.mdc
git checkout origin/main -- .cursor/rules/cursor-desktop-sync.mdc
```

**Adaptar** `FLUXO_OFICIAL_CURSOR_DESKTOP.md`:
- Caminho Mac: `~/appdart` (não `~/Developer/SoloForte`)
- Branch de trabalho: `release/build-156` (não `main`)

---

## 5️⃣ COMANDOS DE AUDITORIA (OBRIGATÓRIOS)

```bash
# Localização
rg -n "LocationAccuracy|distanceFilter|accuracyM|gpsAccuracyM|check-in|CheckIn" lib/

# Confirmar que NÃO há LocationController legado
rg -n "LocationController" lib/ 

# Geofence
rg -n "geofence|GeofenceController" lib/modules/visitas/

# Testes
flutter analyze
flutter test test/modules/visitas/
flutter test test/modules/dashboard/ 2>/dev/null || true
```

---

## 6️⃣ CRITÉRIOS DE ACEITE

| # | Critério | Verificação |
|---|---|---|
| 1 | Merge abortado, repo limpo | `git status` sem conflitos |
| 2 | `location_settings.dart` criado | arquivo existe |
| 3 | `LocationService` usa settings unificados | `bestForNavigation` + filter 5m |
| 4 | Check-in bloqueado se >30m | SnackBar vermelho, sheet não abre |
| 5 | Encerrar visita não bloqueado | teste manual |
| 6 | UI GPS ±Xm continua funcionando | `MapControlsOverlay` intacto |
| 7 | `flutter analyze` sem erros novos | exit 0 |
| 8 | Docs `prompt/` copiados e adaptados | caminho `appdart` |

---

## 7️⃣ COMMIT E PUSH (OBRIGATÓRIO AO FINAL)

```bash
git add .
git commit -m "feat(gnss): portar settings unificados e bloqueio check-in >30m em release/build-156

- Adiciona location_settings.dart na arquitetura LocationService
- Eleva para bestForNavigation mantendo distanceFilter 5m
- Bloqueia check-in quando precisão > 30m
- Copia docs agente prompt/ adaptados para appdart
- NÃO mergeia origin/main (arquiteturas divergentes)"

git push origin release/build-156
```

---

## 8️⃣ FORMATO DO RELATÓRIO ESPERADO

```
📍 RELATÓRIO PORT GNSS — release/build-156
============================================

1. MERGE ABORTADO: [SIM/NÃO]
2. STASH RESTAURADO: [SIM/NÃO/N/A]
3. location_settings.dart: [criado/adaptado]
4. LocationService: [bestForNavigation + filter 5m]
5. CHECK-IN >30m: [bloqueado em arquivo X]
6. GEOFENCE: [alinhado / já OK]
7. DOCS prompt/: [copiados + adaptados]
8. flutter analyze: [OK/erros]
9. COMMIT: [SHA]
10. PUSH: [origin/release/build-156 OK]
```

---

## 9️⃣ SE ALGO DER ERRADO

```bash
# Voltar ao estado pré-merge
git merge --abort
git reset --hard HEAD
git stash pop   # se necessário
```

**Nunca** usar `git checkout --theirs` em massa para arquivos `deleted by us`.

---

## 🔟 CONTEXTO TÉCNICO

```
release/build-156 (CORRETO — manter)
 └─ LocationService (stream, singleton)
 └─ LocationStateNotifier (ADR legado estável)
 └─ UserLocationFix { position, accuracyM }
 └─ MapControlsOverlay.gpsAccuracyM
 └─ lib/modules/drawing/ (refatorado)

origin/main (NÃO mergear inteiro)
 └─ LocationController (legado — incompatível)
 └─ GNSS P2/P3 (portar cirurgicamente)
 └─ prompt/ docs (copiar como arquivos novos)
```

---

## ⚙️ ENCERRAMENTO

> O merge de `origin/main` foi abortado propositalmente.  
> GNSS foi portado cirurgicamente para `release/build-156`.  
> MacBook sincronizado via push em `origin/release/build-156`.
