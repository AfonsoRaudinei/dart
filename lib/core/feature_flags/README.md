# 🚦 Feature Flags — Rollout Controlado

## 📋 Visão Geral

Sistema de Feature Flags para ativação progressiva e reversível de funcionalidades críticas.

### Características

✅ **Rollout Percentual**: Ativar gradualmente por % de usuários  
✅ **Filtragem por Papel**: Restringir a roles específicos (consultor/produtor)  
✅ **Kill Switch**: Desativação imediata sem rebuild  
✅ **Hash Determinístico**: Mesmo usuário sempre recebe mesma decisão  
✅ **Cache Local**: Reduz latência e funciona offline (fallback)  
✅ **Zero Impacto**: Sem alterar arquitetura existente

---

## 🏗️ Arquitetura

```
lib/core/feature_flags/
├── feature_flag_model.dart       # Entidade FeatureFlag
├── feature_flag_resolver.dart    # Lógica pura de decisão
└── feature_flag_service.dart     # Backend + cache
```

### Fluxo de Decisão

```
1. Flag global enabled? ────→ ❌ → Bloqueia
   ↓ ✅
2. Papel permitido? ────────→ ❌ → Bloqueia
   ↓ ✅
3. Hash dentro de rollout? ─→ ❌ → Bloqueia
   ↓ ✅
4. App version >= mínima? ──→ ❌ → Bloqueia
   ↓ ✅
   ✅ Feature Habilitada
```

---

## 📦 Modelo de Dados

### `FeatureFlag`

```dart
FeatureFlag {
  String key;                  // 'drawing_v1'
  bool enabled;                // Kill switch global
  int rolloutPercentage;       // 0-100
  List<String>? allowedRoles;  // ['consultor', 'produtor']
  int version;                 // Para invalidação de cache
  String? minAppVersion;       // Versão mínima do app
}
```

### `FeatureFlagUser`

```dart
FeatureFlagUser {
  String userId;        // ID único do usuário
  String? role;         // 'consultor' | 'produtor'
  String? appVersion;   // '1.2.3'
}
```

---

## 🎯 Uso — Drawing Module

### Integração no Ponto de Entrada

```dart
// lib/ui/screens/private_map_screen.dart

import 'package:soloforte_app/core/feature_flags/feature_flag_service.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_resolver.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_sheet.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_disabled_widget.dart';

void _openDrawingSheet() async {
  // 1. Buscar flag do backend/cache
  final flag = await featureFlagService.getDrawingFlag();
  
  // 2. Resolver se está ativo para este usuário
  final user = FeatureFlagUser(
    userId: currentUserId,
    role: currentUserRole,
    appVersion: '1.1.0',
  );
  
  final isEnabled = featureFlagResolver.isDrawingEnabled(flag, user);
  
  // 3. Renderizar condicionalmente
  showModalBottomSheet(
    context: context,
    builder: (_) => isEnabled
        ? DrawingSheet(controller: _drawingController)
        : const DrawingDisabledWidget(),
  );
}
```

---

## 🧪 Testagem

### Testes Implementados

| Arquivo | Cobertura |
|---|---|
| `feature_flag_resolver_test.dart` | 100% lógica de decisão |
| `rollout_hash_determinism_test.dart` | Hash distribuição uniforme |
| `drawing_flag_integration_test.dart` | Drawing + flags end-to-end |

### Executar Testes

```bash
# Todos os testes de feature flags
flutter test test/core/feature_flags/

# Com cobertura
flutter test --coverage test/core/feature_flags/
```

---

## 📊 Estratégia de Rollout

### Fase 1 — Interno (5%)

```json
{
  "key": "drawing_v1",
  "enabled": true,
  "rollout_percentage": 5,
  "allowed_roles": ["consultor"],
  "version": 1
}
```

**Objetivo**: Validar com equipe interna de consultores.

### Fase 2 — Beta Controlado (25%)

```json
{
  "key": "drawing_v1",
  "enabled": true,
  "rollout_percentage": 25,
  "allowed_roles": ["consultor", "produtor"],
  "version": 2
}
```

**Objetivo**: Expandir para early adopters.

### Fase 3 — Expansão (60%)

```json
{
  "key": "drawing_v1",
  "enabled": true,
  "rollout_percentage": 60,
  "allowed_roles": null,
  "version": 3
}
```

**Objetivo**: Rollout massivo.

### Fase 4 — Total (100%)

```json
{
  "key": "drawing_v1",
  "enabled": true,
  "rollout_percentage": 100,
  "version": 4
}
```

**Objetivo**: Disponível para todos.

---

## 🚨 Kill Switch

### Ativação Imediata

```json
{
  "key": "drawing_v1",
  "enabled": false,  ← 🔴 Kill switch
  "rollout_percentage": 0,
  "version": 5
}
```

**Resultado**:
- ✅ Desativa imediatamente para todos os usuários
- ✅ Sem necessidade de publicar nova versão do app
- ✅ Cache local expirado em < 15 min (TTL)
- ✅ Background update propaga mudança em < 30 min

---

## 🔐 Segurança

### Backend Validation

⚠️ **CRÍTICO**: Nunca confiar apenas no client.

```dart
// Backend deve validar:
if (!isFeatureEnabled(userId, 'drawing_v1')) {
  throw UnauthorizedException('Feature not available');
}
```

### Backend Endpoint Example

```dart
// POST /api/drawing/sync
Future<Response> syncDrawing(Request request) async {
  final userId = request.userId;
  final flag = await getFeatureFlag('drawing_v1');
  final user = FeatureFlagUser(userId: userId, role: request.userRole);
  
  if (!featureFlagResolver.isDrawingEnabled(flag, user)) {
    return Response.forbidden('Drawing module disabled');
  }
  
  // Continuar com sync...
}
```

---

## 📈 Métricas Obrigatórias

### Monitoramento

Antes de expandir rollout, validar:

| Métrica | Threshold |
|---|---|
| **Crash rate** | < 0.1% |
| **Tempo médio de desenho** | < 30s |
| **Cancelamentos por sessão** | < 20% |
| **Erros de validação topológica** | < 5% |
| **Uso offline** | > 80% funcional |

### Instrumentação

```dart
// Adicionar analytics
analytics.track('drawing_feature_accessed', {
  'user_id': userId,
  'rollout_percentage': flag.rolloutPercentage,
  'duration': drawingDuration,
});
```

---

## 🔄 Cache & TTL

### Configuração

| Parâmetro | Valor | Justificativa |
|---|---|---|
| **Cache TTL** | 15 min | Balança latência vs agilidade kill switch |
| **Background Update** | 30 min | Reduz carga no backend |
| **Stale Cache Fallback** | Sim | Funciona offline |

### Cache Keys

```dart
'feature_flag_drawing_v1'
'feature_flag_drawing_v1_timestamp'
```

---

## 🧩 Dependências

### Novos Pacotes

```yaml
dependencies:
  crypto: ^3.0.3           # Para hash SHA-256
  shared_preferences: ^2.2.0  # Cache local
```

### Instalação

```bash
flutter pub add crypto shared_preferences
flutter pub get
```

---

## 📝 Checklist de Implementação

Backend:
- [ ] Endpoint `/api/feature-flags`
- [ ] Validação server-side em endpoints protegidos
- [ ] Dashboard admin para gerenciar flags

Frontend:
- [x] `FeatureFlagModel`
- [x] `FeatureFlagResolver`
- [x] `FeatureFlagService`
- [x] Testes unitários (resolver + hash)
- [x] Teste de integração (drawing)
- [ ] Integrar em `private_map_screen.dart`
- [ ] Analytics/métricas

DevOps:
- [ ] Configurar flags no backend staging
- [ ] Configurar flags no backend produção
- [ ] Validar kill switch em staging

---

## 🎓 Exemplos de Uso

### Verificar Flag Simples

```dart
final flag = await featureFlagService.getFlag('drawing_v1');
final user = FeatureFlagUser(userId: '123', role: 'consultor');
final isEnabled = resolver.isFeatureEnabled(flag, user);

if (isEnabled) {
  // Renderizar feature
} else {
  // Fallback
}
```

### Hash Determinístico

```dart
// Mesmo userId sempre retorna mesma decisão
final user = FeatureFlagUser(userId: 'alice');

// Chamada 1
final result1 = resolver.isFeatureEnabled(flag, user); // true

// Chamada 2 (1 hora depois, mesmo flag)
final result2 = resolver.isFeatureEnabled(flag, user); // true

assert(result1 == result2); // ✅ Sempre consistente
```

### Lidar com Cache Expirado

```dart
// Se backend falhar, service retorna cache expirado (se existir)
// ou flag desabilitada (safe default)
final flag = await service.getDrawingFlag();

// flag.enabled pode ser:
// - true: Cache fresco ou backend respondeu
// - false: Kill switch OU backend/cache falhou (safe default)
```

---

## 🔍 Troubleshooting

### Usuário não vê feature mesmo em 100% rollout

**Causas possíveis**:
1. `enabled: false` (kill switch ativo)
2. `allowedRoles` não contém papel do usuário
3. `minAppVersion` maior que versão instalada
4. Cache local desatualizado

**Debug**:
```dart
print('Flag: ${flag.enabled}');
print('Rollout: ${flag.rolloutPercentage}%');
print('Roles: ${flag.allowedRoles}');
print('User role: ${user.role}');
print('Min version: ${flag.minAppVersion}');
```

### Cache não atualizando

**Solução**:
```dart
await featureFlagService.clearCache();
final flag = await featureFlagService.getFlag('drawing_v1');
```

---

## 📚 Referências

- [Feature Flags Best Practices](https://martinfowler.com/articles/feature-toggles.html)
- [Rollout Strategies](https://launchdarkly.com/blog/dos-and-donts-of-feature-flag-testing/)
- Tag baseline: `draw-stable-v1`

---

## ✅ Status

- ✅ Modelo de dados
- ✅ Resolver puro
- ✅ Service com cache
- ✅ Testes unitários
- ✅ Teste de integração
- ⬜ Integração em `private_map_screen.dart` (próximo passo)
- ⬜ Backend endpoint
- ⬜ Validação em staging
