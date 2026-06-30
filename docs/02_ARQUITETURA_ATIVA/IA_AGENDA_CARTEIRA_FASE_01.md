# IA Agenda + Carteira — Fase 01 (Contrato e Regras)

Status: **Concluída**  
Data: 2026-04-15

## Objetivo da fase

Fechar o contrato funcional e técnico mínimo da recomendação de visitas, sem acoplar UI nem provedor de IA ainda.

## Regras aprovadas

- KPI principal: **% de meta fechada** com foco em meta de categoria.
- Meta: **anual**.
- Unidade principal da meta: **R$** (com suporte a percentual por cliente/categoria).
- Recomendação: **top 1** cliente em aberto na categoria alvo.
- Geografia: priorizar **mesma cidade**; fallback até **50 km**.
- Cooldown: **7 dias**.
- UX final desejada: **lista + chat**.
- Segurança: chave OpenRouter apenas em backend.

## Entregáveis implementados

### 1) Contratos de domínio

- [visit_recommendation_policy.dart](../../../lib/modules/agenda_ai/domain/entities/visit_recommendation_policy.dart)
- [visit_recommendation_context.dart](../../../lib/modules/agenda_ai/domain/entities/visit_recommendation_context.dart)
- [visit_recommendation.dart](../../../lib/modules/agenda_ai/domain/entities/visit_recommendation.dart)
- [i_visit_recommendation_engine.dart](../../../lib/modules/agenda_ai/domain/services/i_visit_recommendation_engine.dart)

### 2) Definição de política padrão MVP

- `VisitRecommendationPolicy.annualTop1`
  - `topN = 1`
  - `prioritizeSameCity = true`
  - `maxDistanceKm = 50`
  - `cooldown = 7 dias`
  - `metaWindow = annual`

## Revisão da fase

Checklist:

- [x] regras de negócio convertidas em contrato de domínio
- [x] parâmetros críticos fixados em uma política explícita
- [x] contexto mínimo definido para ranking determinístico
- [x] resultado de recomendação definido com motivo curto

## Riscos remanescentes para Fase 02

1. Mapear fonte real de dados para cidade/coordenadas do cliente.
2. Resolver ausência de histórico de resultado de visita (usar última visita/cooldown por agenda).
3. Definir como derivar categoria-alvo com maior gap anual em R$.

## Go/No-Go

Pronto para iniciar **Fase 02**: motor determinístico de recomendação (top 1) com cooldown e geografia.
