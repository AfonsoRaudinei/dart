# 🚨 Kill Switch - Procedimento de Emergência

## Quando Usar o Kill Switch?

Use o kill switch **IMEDIATAMENTE** se detectar:

- 🐛 **Bug crítico** que impacta produção
- 💥 **Crash sistemático** da feature
- 🔒 **Vulnerabilidade de segurança** descoberta
- 📊 **Métricas alarmantes** (crash rate, error rate)
- 👥 **Reclamações massivas** de usuários
- ⚡ **Performance degradada** (ANR, timeout)

---

## 🚀 Execução Rápida (1 minuto)

### Staging

```bash
cd backend
./scripts/kill_switch.sh staging drawing_v1
```

### Production

```bash
cd backend
export ADMIN_TOKEN="your-production-admin-token"
./scripts/kill_switch.sh production drawing_v1
```

**Pronto!** A feature está desabilitada para todos os usuários.

---

## 📋 Procedimento Completo

### 1️⃣ Detecção do Problema

**Fontes de Alerta:**
- 📊 Crashlytics (Firebase)
- 📈 Analytics (taxas de erro anormais)
- 🐛 Sentry/Bugsnag (error tracking)
- 📞 Suporte (tickets/reclamações)
- 👀 Monitoring (APM, logs)

**Checklist de Validação:**
- [ ] Problema confirmado em múltiplos dispositivos?
- [ ] Problema reproduzível?
- [ ] Impacto estimado (% de usuários)?
- [ ] Gravidade (crítico, alto, médio, baixo)?

### 2️⃣ Decisão de Kill Switch

**Critérios para Ativação:**

| Critério | Limite | Ação |
|---|---|---|
| Crash rate | > 5% | 🚨 Kill switch IMEDIATO |
| Error rate | > 10% | 🚨 Kill switch IMEDIATO |
| ANR rate | > 3% | ⚠️ Considerar kill switch |
| User complaints | > 50/hora | ⚠️ Investigar + considerar |
| Security issue | Qualquer | 🚨 Kill switch IMEDIATO |

**Responsáveis:**
- 🚨 **Crítico**: Tech Lead, CTO, Product Manager (qualquer um pode acionar)
- ⚠️ **Alto**: Tech Lead + Product Manager (consenso)
- 📊 **Médio**: Team discussion

### 3️⃣ Comunicação

**ANTES de executar o kill switch:**

1. **Notificar equipe (Slack/Teams):**
   ```
   🚨 KILL SWITCH ATIVADO
   Feature: drawing_v1
   Ambiente: PRODUCTION
   Motivo: [descrição breve]
   Executado por: [seu nome]
   ```

2. **Notificar stakeholders:**
   - Product Manager
   - Customer Support
   - Marketing (se feature anunciada)

### 4️⃣ Execução

```bash
# 1. Validar conexão com servidor
curl https://api.soloforte.com.br/health

# 2. Listar flags atuais
./scripts/list_flags.sh production

# 3. Executar kill switch
export ADMIN_TOKEN="your-production-admin-token"
./scripts/kill_switch.sh production drawing_v1

# Output esperado:
# ✅ Kill switch executed successfully!
# ✅ Flag drawing_v1 is now DISABLED in production
# 💾 Backup: data/backups/kill_switch_drawing_v1_20260212_103045.json
```

**Tempo de propagação:**
- Frontend cache: até 15 minutos (TTL)
- Background updates: até 30 minutos
- Server-side: **IMEDIATO** (novas requests já validam)

### 5️⃣ Validação

**Verificar que flag está desabilitada:**

```bash
# Via API
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
     https://api.soloforte.com.br/api/feature-flags/drawing_v1 | jq '.flag.enabled'
# Output esperado: false

# Via script
./scripts/list_flags.sh production
# Output esperado: Status: 🔴 DISABLED
```

**Testar no app:**
1. Abrir app em dispositivo de teste
2. Tentar acessar feature drawing
3. Verificar que aparece `DrawingDisabledWidget`

**Monitorar impacto:**
- Crashlytics: crash rate deve cair
- Analytics: tentativas de acesso à feature
- Logs: erros relacionados devem parar

### 6️⃣ Comunicação Pós-Kill Switch

**Atualizar equipe:**
```
✅ KILL SWITCH EXECUTADO COM SUCESSO
Feature: drawing_v1
Ambiente: PRODUCTION
Horário: 12/02/2026 10:35 BRT
Propagação: em até 30min
Backup: data/backups/kill_switch_drawing_v1_20260212_103045.json

Próximos passos:
1. Investigar root cause
2. Fix + testes
3. Deploy fix
4. Validar em staging
5. Reativar em production
```

**Customer Support:**
- Atualizar script de resposta
- Notificar sobre feature temporariamente indisponível

---

## 🔄 Rollback do Kill Switch (Reativação)

**IMPORTANTE**: Só reative após:
- ✅ Root cause identificado
- ✅ Fix implementado e testado
- ✅ Validação em staging OK
- ✅ Métricas normalizadas

### Cenário 1: Restaurar Estado Anterior (Rollback Completo)

```bash
# Usar o backup gerado pelo kill switch
./scripts/restore_flag.sh production data/backups/kill_switch_drawing_v1_20260212_103045.json
```

### Cenário 2: Reativar com Rollout Progressivo (Recomendado)

```bash
# Fase 1: 5% de rollout (early adopters)
curl -X PUT \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "rollout_percentage": 5,
    "allowed_roles": ["consultor"]
  }' \
  https://api.soloforte.com.br/admin/flags/drawing_v1

# Monitorar por 24h

# Fase 2: 25%
# Fase 3: 50%
# Fase 4: 100%
```

---

## 📊 Post-Mortem (Obrigatório)

Após resolver o problema, documentar:

1. **O que aconteceu?**
   - Timeline de eventos
   - Impacto (% usuários, duração)

2. **Root Cause**
   - Causa técnica do problema
   - Por que não foi detectado antes?

3. **Resposta**
   - Tempo de detecção
   - Tempo de kill switch
   - Efetividade da resposta

4. **Prevenção**
   - O que vamos fazer diferente?
   - Novos testes? Alerts? Monitoramento?

---

## 🎯 Checklist de Kill Switch

**Antes:**
- [ ] Problema validado
- [ ] Gravidade avaliada (crítico/alto)
- [ ] Equipe notificada (Slack/Teams)
- [ ] Conexão com servidor OK

**Durante:**
- [ ] Backup automático criado
- [ ] Kill switch executado
- [ ] HTTP 200 recebido
- [ ] Flag verificada (disabled)

**Depois:**
- [ ] Equipe atualizada (status)
- [ ] Customer Support notificado
- [ ] Monitoramento validado (crash rate caiu)
- [ ] Post-mortem agendado
- [ ] Root cause investigation iniciada

---

## 🛠️ Troubleshooting

### Problema: Kill switch não executa (erro de autenticação)

```bash
# Verificar token
echo $ADMIN_TOKEN

# Testar autenticação
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
     https://api.soloforte.com.br/admin/flags
```

### Problema: Flag ainda aparece habilitada após kill switch

**Causa**: Cache do app (TTL de 15min)

**Solução**:
1. Aguardar até 30min (background update)
2. Ou forçar clear cache no app (dev)
3. Server-side validation **já está bloqueando** novos requests

### Problema: Não consigo restaurar backup

**Causa**: Arquivo de backup corrompido ou não encontrado

**Solução**:
1. Listar backups: `ls -lh data/backups/`
2. Verificar conteúdo: `cat data/backups/kill_switch_*.json | jq`
3. Se perdeu backup, recriar flag manualmente via admin API

---

## 📞 Contatos de Emergência

**Tech Lead**: [nome] - [tel/slack]  
**CTO**: [nome] - [tel/slack]  
**Product Manager**: [nome] - [tel/slack]  
**DevOps On-Call**: [rotation/slack]

---

**Última revisão**: 12/02/2026  
**Versão**: 1.0
