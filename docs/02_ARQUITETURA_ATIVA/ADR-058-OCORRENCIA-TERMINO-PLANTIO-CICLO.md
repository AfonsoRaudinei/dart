# ADR-058 — Término do plantio e ciclo na ocorrência

**Data:** 09/11/2026  
**Status:** APROVADO  
**Módulos:** `consultoria/occurrences/`, `core/database/`, `ui/components/map/`

## Contexto

O card Plantio da ocorrência registra o início do plantio (`data_plantio`),
a emergência e os campos agronômicos da v47. Faltava o término do plantio,
que o consultor anota quando a semeadura dura mais de um dia.

O campo "Ciclo (dias)" já aparecia no formulário, mas não era salvo na
ocorrência: só ia para o talhão quando o talhão estava vazio. Ao reabrir
a ocorrência para edição, o campo voltava vazio.

## Decisão

1. **SQLite v51** — colunas nullable em `occurrences`:
   `data_fim_plantio TEXT` (ISO `yyyy-MM-dd`) e `ciclo_dias INTEGER`.
   Migração idempotente (`database_migrations_v51.dart`): só adiciona a
   coluna se ela não existir. Instalação limpa passa por v0 → v51.
2. **Supabase** — `20261109230000_occurrences_plantio_fim_ciclo.sql`
   (`add column if not exists`). Sync no mesmo tier dos campos de plantio
   da v47: `OccurrenceSyncService` envia e recebe as duas colunas ao lado
   de `data_emergencia`.
3. **Domínio** — `Occurrence` ganha `dataFimPlantio` e `cicloDias`, com
   `clearDataFimPlantio` / `clearCicloDias` no `copyWith`. A edição limpa
   o valor quando o formulário envia `null`.
4. **Formulário** — "Término do plantio" logo após "Início do plantio".
   O seletor começa no início, quando houver. Se o início passar a ser
   depois do término, o término é limpo. Ao salvar, término antes do
   início bloqueia com mensagem.
5. **Talhão** — o write-back do ciclo e das datas no talhão continua igual
   (`writeBackTalhaoPlantioIfEmpty`): só preenche o talhão vazio.
6. **Detalhe** — linhas "Término do plantio" e "Ciclo". Com término, a
   linha de início passa a se chamar "Início do plantio".

## Não-objetivos

- Calcular término ou ciclo automaticamente.
- Levar os dois campos ao HTML do relatório ou a contratos de `core/`.
- Alterar o término/ciclo do talhão já preenchido.

## Consequências

- Ocorrências antigas ficam com os dois campos nulos até o consultor
  salvar de novo.
- A migration Supabase precisa estar aplicada no projeto live antes do
  push das duas colunas; sem ela o upsert remoto falha.
