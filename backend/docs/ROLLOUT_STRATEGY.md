# 🎯 Feature Flag Rollout Strategy

Estratégia de rollout progressivo para minimizar riscos ao lançar novas features.

---

## 📊 Fases de Rollout (Recomendadas)

### Fase 0: Desenvolvimento (Dev/QA Only)
- **Rollout**: 0% (flag desabilitada para todos)
- **Duração**: Durante desenvolvimento
- **Objetivo**: Testar código sem impacto em usuários

### Fase 1: Early Adopters (5%)
- **Rollout**: 5% de usuários
- **Roles**: Apenas consultores (power users)
- **Duração**: 2-3 dias
- **Objetivo**: Validação inicial com usuários reais
- **Métricas**: Crash rate, error rate, user feedback

### Fase 2: Beta Expansion (25%)
- **Rollout**: 25% de usuários
- **Roles**: Consultores + Produtores
- **Duração**: 3-5 dias
- **Objetivo**: Validar escala, performance, edge cases
- **Métricas**: Performance (ANR, load time), completion rate

### Fase 3: Majority Rollout (50%)
- **Rollout**: 50% de usuários
- **Roles**: Todos
- **Duração**: 5-7 dias
- **Objetivo**: Validação em larga escala
- **Métricas**: Server load, cost, user satisfaction

### Fase 4: Full Rollout (100%)
- **Rollout**: 100% de usuários
- **Roles**: Todos
- **Duração**: Permanente
- **Objetivo**: Disponibilizar feature para todos
- **Métricas**: Adoption rate, success rate, NPS

---

## 🎯 Exemplo: Drawing Module

### Timeline Completo

```
┌─────────────────────────────────────────────────────────────┐
│  Fase 0        Fase 1      Fase 2      Fase 3      Fase 4   │
│  (Dev)         (5%)        (25%)       (50%)       (100%)    │
│  ░░░░░░░░░░░   ████        █████       ██████      ████████  │
│  1-2 weeks     2-3 days    3-5 days    5-7 days    Forever  │
└─────────────────────────────────────────────────────────────┘
```

### Configuração por Fase

**Fase 1: Early Adopters**
```bash
curl -X PUT \
  -H "Authorization: Bearer staging-admin-token-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 5,
    "allowed_roles": ["consultor"],
    "version": 1,
    "min_app_version": "1.1.0"
  }' \
  http://localhost:8080/admin/flags/drawing_v1
```

**Monitoramento (2-3 dias):**
- Crashlytics: crash rate < 1%
- Analytics: completion rate > 80%
- Feedback: NPS > 7

**Go/No-Go Decision:**
- ✅ Métricas OK → Avançar para Fase 2
- ❌ Problemas detectados → Kill switch + fix

---

**Fase 2: Beta Expansion**
```bash
curl -X PUT \
  -H "Authorization: Bearer staging-admin-token-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 25,
    "allowed_roles": ["consultor", "produtor"],
    "version": 2
  }' \
  http://localhost:8080/admin/flags/drawing_v1
```

**Monitoramento (3-5 dias):**
- Performance: ANR rate < 3%
- Server: response time < 500ms (p95)
- Users: completion rate > 75%

---

**Fase 3: Majority Rollout**
```bash
curl -X PUT \
  -H "Authorization: Bearer staging-admin-token-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 50,
    "allowed_roles": ["consultor", "produtor"],
    "version": 3
  }' \
  http://localhost:8080/admin/flags/drawing_v1
```

**Monitoramento (5-7 dias):**
- Scale: server load OK
- Cost: infrastructure cost within budget
- Adoption: usage rate > 60% of eligible users

---

**Fase 4: Full Rollout**
```bash
curl -X PUT \
  -H "Authorization: Bearer admin-secret-token-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 100,
    "allowed_roles": ["consultor", "produtor"],
    "version": 4
  }' \
  https://api.soloforte.com.br/admin/flags/drawing_v1
```

---

## 📊 Métricas de Decisão

### Critérios de Go/No-Go

| Métrica | Threshold | Ação se Excedido |
|---|---|---|
| **Crash Rate** | < 1% | 🚨 Kill switch + rollback |
| **Error Rate** | < 5% | ⚠️ Investigar + hold rollout |
| **ANR Rate** | < 3% | ⚠️ Performance optimization |
| **Completion Rate** | > 70% | 📊 OK para avançar |
| **User Complaints** | < 10/dia | 📊 OK para avançar |
| **Server Response Time** (p95) | < 500ms | ⚠️ Optimize backend |

### Ferramentas de Monitoramento

1. **Crashlytics** (Firebase)
   - Crash-free rate
   - Most common crashes
   - Affected devices

2. **Analytics** (Firebase/Mixpanel)
   - Feature usage (DAU, MAU)
   - Completion funnel
   - Time to complete
   - Retry rate

3. **APM** (New Relic/Datadog)
   - Response time
   - Throughput
   - Error rate
   - Server load

4. **User Feedback**
   - In-app ratings
   - Support tickets
   - NPS surveys

---

## 🎛️ Scripts Úteis

### Avançar para Próxima Fase

```bash
#!/bin/bash
# scripts/advance_rollout.sh drawing_v1 staging

FEATURE=$1
ENV=$2
CURRENT_PHASE=$3

case $CURRENT_PHASE in
  1)
    NEW_ROLLOUT=25
    ;;
  2)
    NEW_ROLLOUT=50
    ;;
  3)
    NEW_ROLLOUT=100
    ;;
  *)
    echo "Invalid phase"
    exit 1
    ;;
esac

echo "Advancing $FEATURE to $NEW_ROLLOUT%..."

# Executar update via API
# ...
```

### Monitorar Métricas em Tempo Real

```bash
#!/bin/bash
# scripts/monitor_rollout.sh drawing_v1

FEATURE=$1

echo "📊 Monitoring $FEATURE..."

# Buscar métricas do Firebase/Analytics
# Exibir dashboard no terminal

# Exemplo de output:
# ┌─────────────────────────────────────┐
# │  Drawing v1 - Phase 1 (5%)         │
# ├─────────────────────────────────────┤
# │  Crash Rate:      0.3% ✅          │
# │  Error Rate:      1.2% ✅          │
# │  Completion:      85% ✅            │
# │  Avg Duration:    45s               │
# │  User Feedback:   8.5/10 ⭐         │
# └─────────────────────────────────────┘
```

---

## 🚨 Rollback Strategy

### Quando fazer Rollback?

| Situação | Ação |
|---|---|
| Crash rate > 5% | 🚨 **Rollback imediato** para fase anterior |
| Error rate > 10% | 🚨 **Rollback imediato** |
| Negative feedback spike | ⚠️ Hold rollout + investigate |
| Performance degradation | ⚠️ Hold + optimize |

### Rollback para Fase Anterior

```bash
# Fase 2 → Fase 1
./scripts/rollback_phase.sh drawing_v1 staging --to-phase 1

# Ou desabilitar completamente
./scripts/kill_switch.sh staging drawing_v1
```

---

## 📋 Checklist de Rollout

**Antes de cada fase:**
- [ ] Métricas da fase anterior OK
- [ ] Go/No-Go decision aprovada
- [ ] Equipe de suporte notificada
- [ ] Monitoring dashboards configurados
- [ ] Kill switch testado em staging

**Durante cada fase:**
- [ ] Monitorar métricas diariamente
- [ ] Daily standup: review metrics
- [ ] Feedback de usuários coletado
- [ ] Tickets de suporte triados

**Após cada fase:**
- [ ] Métricas dentro dos thresholds
- [ ] Retrospective da fase
- [ ] Documentar aprendizados
- [ ] Decisão de avançar registrada

---

## 🎯 Best Practices

### 1. Determinístico Hash-Based Rollout
✅ Mesmo usuário sempre vê mesma experiência  
✅ Evita "flickering" (enabled/disabled alternando)  
✅ Permite A/B testing consistente

### 2. Role-Based Filtering
✅ Power users primeiro (consultores)  
✅ Usuários menos técnicos depois (produtores)  
✅ Reduz impacto de bugs

### 3. Version Gating
✅ Só liberar para versões compatíveis do app  
✅ Evita crashs por incompatibilidade  
✅ Força updates para features críticas

### 4. Server-Side Validation
✅ Backend valida feature flags  
✅ Previne abuso (app modificado)  
✅ Kill switch afeta backend imediatamente

### 5. Graceful Fallback
✅ UI de fallback amigável  
✅ Não mostrar erros técnicos  
✅ Opção de retry após tempo

---

## 📞 Responsáveis

| Fase | Aprovador | Executor |
|---|---|---|
| Fase 1 (5%) | Tech Lead | Dev Team |
| Fase 2 (25%) | Tech Lead + PM | Dev Team |
| Fase 3 (50%) | PM + Tech Lead | DevOps |
| Fase 4 (100%) | PM + CTO | DevOps |

---

**Última revisão**: 12/02/2026  
**Versão**: 1.0
