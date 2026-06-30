# IA Agenda + Carteira — Fase 03 (Backend + OpenRouter)

Status: **Concluída**  
Data: 2026-04-15

## Objetivo da fase

Criar endpoint backend para recomendação de visitas com:

- motor determinístico no servidor
- explicação opcional via OpenRouter (chave somente backend)
- fallback operacional quando IA estiver indisponível

## Entregável implementado

- Edge Function:
  - [supabase/functions/agenda-ai-recommend/index.ts](../../../supabase/functions/agenda-ai-recommend/index.ts)

## Comportamento do endpoint

### Segurança

- exige `Authorization: Bearer <jwt>`
- valida usuário via `SUPABASE_SERVICE_ROLE_KEY`
- bloqueia `consultantId` diferente do usuário autenticado

### Recomendação determinística

- filtra categoria alvo em aberto (`< 100%`)
- aplica cooldown em dias
- prioriza mesma cidade
- fallback por raio (km)
- ordena por menor progresso da categoria
- retorna `topN`

### IA (OpenRouter)

- habilitada por `useAiExplanation=true`
- usa `OPENROUTER_API_KEY` no backend
- modelo padrão: `qwen/qwen2.5-7b-instruct:free`
- timeout curto e fallback automático
- se falhar, mantém recomendação determinística e retorna motivo de indisponibilidade

## Variáveis de ambiente necessárias

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OPENROUTER_API_KEY` (opcional; sem ela a IA fica desabilitada)
- `OPENROUTER_MODEL` (opcional)

## Exemplo de payload (resumo)

```json
{
  "consultantId": "<user-id>",
  "currentCity": "Brejinho",
  "currentLocation": { "lat": -6.18, "lon": -35.35 },
  "targetCategoryId": "cat_quimico",
  "annualTargetValue": 100000,
  "annualAchievedValue": 50000,
  "opportunities": [
    {
      "clientId": "c1",
      "clientName": "Augusto",
      "city": "Brejinho",
      "location": { "lat": -6.19, "lon": -35.34 },
      "categoryId": "cat_quimico",
      "categoryProgressPercent": 50,
      "categoryAchievedValue": 5000,
      "lastVisitAt": "2026-04-01T10:00:00Z"
    }
  ],
  "policy": {
    "topN": 1,
    "prioritizeSameCity": true,
    "maxDistanceKm": 50,
    "cooldownDays": 7
  },
  "useAiExplanation": true
}
```

## Revisão da fase

Checklist:

- [x] endpoint backend criado
- [x] chave OpenRouter fora do app
- [x] fallback determinístico quando IA falha
- [x] validação de auth e consultantId
- [x] resposta curta para explicação IA

## Riscos remanescentes para Fase 04

1. integração Flutter ainda não conectada ao endpoint
2. criação de visita com confirmação ainda não integrada
3. qualidade da explicação depende da disponibilidade de modelo free

## Go/No-Go

Pronto para iniciar **Fase 04**: integração no app (ícone IA → lista + chat + ação de criar visita com confirmação).
