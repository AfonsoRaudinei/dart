# IA Agenda + Carteira — Fase 02 (Motor Determinístico)

Status: **Concluída**  
Data: 2026-04-15

## Objetivo da fase

Implementar o motor de recomendação **sem LLM**, garantindo top 1 com regras de negócio previsíveis.

## Regras implementadas

- filtra somente oportunidades da categoria alvo com progresso < 100%
- aplica cooldown de 7 dias
- prioriza mesma cidade
- fallback por raio de 50 km quando não houver mesma cidade
- ordena por menor progresso na categoria (maior oportunidade)

## Entregáveis implementados

- motor determinístico:
  - [deterministic_visit_recommendation_engine.dart](../../../lib/modules/agenda_ai/domain/services/deterministic_visit_recommendation_engine.dart)

- testes de unidade:
  - [deterministic_visit_recommendation_engine_test.dart](../../../test/modules/agenda_ai/deterministic_visit_recommendation_engine_test.dart)

## Resultado dos testes

- 3 testes executados
- 3 testes aprovados
- 0 falhas

## Revisão da fase

Checklist:

- [x] top 1 determinístico implementado
- [x] priorização por cidade implementada
- [x] fallback por distância implementado
- [x] cooldown implementado
- [x] motivo curto de recomendação retornado
- [x] testes cobrindo cenários principais

## Riscos remanescentes para Fase 03

1. dados reais de cidade/coordenada podem não estar completos para todos os clientes
2. sem histórico de resultado da visita, a assertividade depende apenas de meta + contexto geográfico
3. ainda não há backend/API para alimentar contexto automaticamente

## Go/No-Go

Pronto para iniciar **Fase 03**: integração backend (endpoint de recomendação + fallback operacional), mantendo chave da OpenRouter apenas no servidor.
