# 🌍 Guia de Configuração de Ambientes

Configuração de feature flags para diferentes ambientes (local, staging, production).

---

## 📋 Resumo dos Ambientes

| Ambiente | URL | Rollout Drawing | Rate Limit | Tokens |
|---|---|---|---|---|
| **Local** | http://localhost:8080 | 100% | 1000/min | Mock fixos |
| **Staging** | https://api-staging.soloforte.com.br | 50% | 100/min | Staging secrets |
| **Production** | https://api.soloforte.com.br | 100% | 1000/min | Prod secrets (JWT) |

---

## 🔧 Configuração Local

### Iniciar Servidor

```bash
cd backend
dart pub get
dart run bin/server.dart
```

### Testar Endpoints

```bash
# Health
curl http://localhost:8080/health

# Listar flags
curl -H "Authorization: Bearer app-client-token-2026" \
     http://localhost:8080/api/feature-flags
```

### Tokens (Mock)

```bash
ADMIN_TOKEN="admin-secret-token-2026"
APP_CLIENT_TOKEN="app-client-token-2026"
```

---

## 🟡 Configuração Staging

### 1. Configurar Secrets

Criar arquivo `.env.staging`:

```bash
# backend/.env.staging
ADMIN_TOKEN="staging-admin-[RANDOM-32-CHARS]"
APP_CLIENT_TOKEN="staging-app-[RANDOM-32-CHARS]"
DATABASE_URL="postgresql://..."
SENTRY_DSN="https://..."
```

**⚠️ NÃO COMMITAR .env.staging no git!**

### 2. Inicializar Flags

```bash
cd backend
dart run scripts/init_flags.dart staging
```

Flags inicializadas:
- `drawing_v1`: enabled=true, rollout=50%, roles=[consultor, produtor]
- `new_sync_engine_v2`: enabled=true, rollout=25%, roles=[consultor]

### 3. Deploy

```bash
# Opção A: Docker
docker-compose -f docker-compose.staging.yml up -d

# Opção B: Cloud Run (GCP)
gcloud run deploy feature-flags-staging \
  --source . \
  --region us-central1 \
  --allow-unauthenticated

# Opção C: Heroku
git push staging main
```

### 4. Validar

```bash
# Health check
curl https://api-staging.soloforte.com.br/health

# Testar kill switch
./scripts/kill_switch.sh staging drawing_v1

# Verificar rollout
curl -H "Authorization: Bearer $STAGING_APP_TOKEN" \
     https://api-staging.soloforte.com.br/api/feature-flags/drawing_v1
```

### 5. Monitoramento Staging

**Logs**:
```bash
# Docker
docker logs -f feature-flags-staging

# Cloud Run
gcloud logging read --limit 50

# Heroku
heroku logs --tail -a feature-flags-staging
```

**Métricas**:
- Request count
- Error rate (< 5%)
- Response time (p95 < 500ms)

---

## 🔴 Configuração Production

### ⚠️ PRÉ-REQUISITOS

- [ ] Testes em staging passando por 48h
- [ ] Crash rate < 0.5%
- [ ] Aprovação de Tech Lead + PM
- [ ] Backup de flags atual
- [ ] Plano de rollback documentado
- [ ] Team on-call escalado

### 1. Configurar Secrets (Produção)

**NÃO usar tokens fixos! Usar JWT ou OAuth2.**

```bash
# Gerar tokens seguros
ADMIN_TOKEN=$(openssl rand -hex 32)
APP_CLIENT_TOKEN=$(openssl rand -hex 32)

# Ou usar JWT (recomendado)
# Implementar autenticação com Firebase Auth, Auth0, etc.
```

Configurar secrets no provedor:

```bash
# GCP Secret Manager
gcloud secrets create admin-token --data-file=- <<< "$ADMIN_TOKEN"
gcloud secrets create app-client-token --data-file=- <<< "$APP_CLIENT_TOKEN"

# AWS Secrets Manager
aws secretsmanager create-secret --name admin-token --secret-string "$ADMIN_TOKEN"

# Heroku
heroku config:set ADMIN_TOKEN="$ADMIN_TOKEN" -a feature-flags-prod
```

### 2. Configurar Banco de Dados (Substituir JSON)

**PostgreSQL (Recomendado)**:

```sql
CREATE TABLE feature_flags (
  key VARCHAR(255) PRIMARY KEY,
  enabled BOOLEAN NOT NULL DEFAULT false,
  rollout_percentage INT DEFAULT 0,
  allowed_roles TEXT[],
  version INT DEFAULT 1,
  min_app_version VARCHAR(20),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_enabled ON feature_flags(enabled);
CREATE INDEX idx_key ON feature_flags(key);
```

Implementar `PostgresFeatureFlagStorage`:

```dart
// lib/storage/postgres_storage.dart
class PostgresFeatureFlagStorage implements FeatureFlagStorage {
  final DatabaseConnection _db;
  
  @override
  Future<List<Map<String, dynamic>>> getAllFlags() async {
    final result = await _db.query('SELECT * FROM feature_flags');
    return result.map((row) => row.toColumnMap()).toList();
  }
  
  // ... implementar outros métodos
}
```

### 3. Configurar HTTPS Obrigatório

```dart
// bin/server.dart
if (environment == 'production' && !request.requestedUri.isScheme('https')) {
  return Response.forbidden('HTTPS required');
}
```

### 4. Configurar Rate Limiting por Usuário

```dart
// middleware/auth_middleware.dart
class RateLimiter {
  final Map<String, List<DateTime>> _requestsPerUser = {};
  
  Middleware rateLimitPerUser({int maxRequests = 100}) {
    return (Handler innerHandler) {
      return (Request request) async {
        final userId = request.headers['x-user-id'];
        if (userId == null) return Response.forbidden('User ID required');
        
        _requestsPerUser.putIfAbsent(userId, () => []);
        final userRequests = _requestsPerUser[userId]!;
        
        // Limpar requests antigas (> 1 min)
        userRequests.removeWhere((t) => 
          DateTime.now().difference(t).inSeconds > 60
        );
        
        if (userRequests.length >= maxRequests) {
          return Response(429, body: 'Rate limit exceeded');
        }
        
        userRequests.add(DateTime.now());
        return await innerHandler(request);
      };
    };
  }
}
```

### 5. Configurar Monitoring

**Prometheus Metrics**:

```dart
// lib/monitoring/prometheus.dart
class PrometheusMetrics {
  static final requestCounter = Counter(
    name: 'http_requests_total',
    help: 'Total HTTP requests',
    labelNames: ['method', 'path', 'status'],
  );
  
  static final requestDuration = Histogram(
    name: 'http_request_duration_seconds',
    help: 'HTTP request duration',
    labelNames: ['method', 'path'],
  );
  
  static void recordRequest(String method, String path, int status, Duration duration) {
    requestCounter.labels([method, path, status.toString()]).inc();
    requestDuration.labels([method, path]).observe(duration.inMilliseconds / 1000);
  }
}
```

**Alertas (Prometheus Alertmanager)**:

```yaml
# alerts.yml
groups:
  - name: feature_flags
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on feature flags API"
          
      - alert: SlowResponses
        expr: histogram_quantile(0.95, http_request_duration_seconds) > 0.5
        for: 10m
        labels:
          severity: warning
```

### 6. Deploy Production

```bash
export ADMIN_TOKEN="your-production-admin-token"
export APP_CLIENT_TOKEN="your-production-app-client-token"

# Backup flags atuais
mkdir -p backend/data/backups
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
     https://api.soloforte.com.br/admin/flags \
     > backend/data/backups/prod_$(date +%Y%m%d_%H%M%S).json

# Deploy
./scripts/deploy.sh production

# Validar
curl https://api.soloforte.com.br/health
```

### 7. Post-Deploy Checklist

- [ ] Health check OK (200)
- [ ] Logs sem erros
- [ ] Métricas normais (request count, latency)
- [ ] Flags carregadas corretamente
- [ ] Autenticação funcionando
- [ ] Rate limiting ativo
- [ ] CORS configurado
- [ ] HTTPS obrigatório
- [ ] Backup automático configurado

---

## 🔄 Procedimento de Rollout Progressivo

### Fase 1: 5% (Early Adopters)

```bash
curl -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 5,
    "allowed_roles": ["consultor"],
    "version": 1,
    "min_app_version": "1.1.0"
  }' \
  https://api.soloforte.com.br/admin/flags/drawing_v1
```

**Monitorar por 2-3 dias:**
- Crashlytics: crash rate < 1%
- Analytics: completion rate > 80%
- Feedback: tickets de suporte

**Go/No-Go Decision:**
- ✅ Métricas OK → Avançar para Fase 2
- ❌ Problemas → Kill switch + fix

### Fase 2: 25% (Beta Expansion)

```bash
curl -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 25,
    "allowed_roles": ["consultor", "produtor"],
    "version": 2
  }' \
  https://api.soloforte.com.br/admin/flags/drawing_v1
```

**Monitorar por 3-5 dias**

### Fase 3: 50% (Majority)

```bash
curl -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"rollout_percentage": 50, "version": 3}' \
  https://api.soloforte.com.br/admin/flags/drawing_v1
```

**Monitorar por 5-7 dias**

### Fase 4: 100% (Full Rollout)

```bash
curl -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"rollout_percentage": 100, "version": 4}' \
  https://api.soloforte.com.br/admin/flags/drawing_v1
```

---

## 🚨 Kill Switch de Emergência

### Staging

```bash
./scripts/kill_switch.sh staging drawing_v1
```

### Production

```bash
export ADMIN_TOKEN="your-production-admin-token"
./scripts/kill_switch.sh production drawing_v1
```

**Tempo de propagação**:
- Server-side: **IMEDIATO** (próximo request)
- App cache: até 15 minutos (TTL)
- Background update: até 30 minutos

---

## 📊 Monitoramento e Alertas

### Métricas Críticas

| Métrica | Threshold | Alerta |
|---|---|---|
| Crash rate | > 5% | 🚨 Kill switch |
| Error rate | > 10% | 🚨 Kill switch |
| Response time (p95) | > 500ms | ⚠️ Investigate |
| Request rate | > 10k/min | 📈 Scale up |

### Dashboards

**Grafana**:
- Request count (por endpoint)
- Error rate (4xx, 5xx)
- Response time (p50, p95, p99)
- Active flags (habilitadas vs desabilitadas)

**Firebase Analytics**:
- Feature usage (DAU, MAU)
- Completion rate
- User segments (por role)

---

## 🔐 Segurança

### Produção Checklist

- [ ] JWT ou OAuth2 (não tokens fixos)
- [ ] HTTPS obrigatório
- [ ] Rate limiting por usuário
- [ ] Input validation
- [ ] CORS configurado (whitelist)
- [ ] Secrets em Secret Manager (não hardcoded)
- [ ] Audit log de mudanças de flags
- [ ] Backup automático diário
- [ ] Disaster recovery plan

---

## 📞 Suporte

**Emergências (Kill Switch)**:
- Slack: #feature-flags-alerts
- On-call: [rotation]

**Documentação**:
- [KILL_SWITCH_PROCEDURE.md](KILL_SWITCH_PROCEDURE.md)
- [ROLLOUT_STRATEGY.md](ROLLOUT_STRATEGY.md)
- [README.md](README.md)

---

**Última atualização**: 12/02/2026  
**Versão**: 1.0
