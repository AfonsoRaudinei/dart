# ADR-059 — Dados do plantio por safra nas ocorrências do talhão

**Data:** 09/11/2026  
**Status:** APROVADO  
**Módulos:** `consultoria/occurrences/`, `core/database/`, `ui/components/map/`

## Contexto

O consultor registra o plantio de um talhão numa ocorrência de categoria
Plantio (ADR-058: início, término, emergência, ciclo). As outras ocorrências
do mesmo talhão (Doença, Insetos, Ervas Daninhas, Nutrientes, Água, Amostra
de Solo) pediam de novo cultivar e data de plantio num bloco editável
"Cultivar & Plantio". O dado era digitado várias vezes, podia divergir do
Plantio e não guardava cultura nem safra.

O talhão (`drawings`) já tem `cultura`, `material`, `safra`, `data_plantio`,
`data_emergencia` e `ciclo_dias`, mas o write-back da ocorrência só
preenchia campos vazios. Um replantio ou correção não chegava ao talhão.

## Decisão

1. **SQLite v52** — colunas nullable em `occurrences`: `cultura TEXT` e
   `safra TEXT` (`'AAAA/AAAA+1'`). Migração idempotente
   (`database_migrations_v52.dart`): só adiciona a coluna se ela não
   existir. Instalação limpa passa por v0 → v52.
2. **Supabase** — `20261109240000_occurrences_cultura_safra.sql`
   (`add column if not exists`). `OccurrenceSyncService` envia e recebe as
   duas colunas no mesmo tier dos campos de plantio.
3. **Safra** — janela julho/AAAA a junho/AAAA+1 (`safraFromPlantio`,
   `occurrenceDateInSafra`). Safra da ocorrência de Plantio =
   `safra` salva, senão a safra do início do plantio, senão a da criação.
4. **Contexto de plantio do talhão** (`resolvePlantioContext`, função pura):
   - candidatas = ocorrências Plantio do mesmo `field_id`, não excluídas;
   - filtra pela safra que contém a data de referência (data da ocorrência
     em edição; agora na criação);
   - vence a de criação mais recente (`created_at`, desempate por
     `updated_at`). Editar um Plantio antigo não o torna o atual;
   - sem candidata na safra, usa o talhão (`drawings`) só se a safra do
     talhão contiver a data de referência. Senão, sem contexto.
5. **Formulário** — card Plantio ganha Cultura e Safra (safra sugerida pela
   data de início). Nas outras categorias, com contexto, o bloco editável
   vira o card somente leitura "Dados do plantio" (Cultura · Safra,
   Cultivar, Início + DAP, Término, Emergência + DAE, Ciclo). Ao salvar, os
   valores são copiados para a ocorrência. Na edição só preenche campos
   vazios; nunca sobrescreve valor já salvo. Sem contexto, o bloco editável
   continua como antes. Sementes, estande, avaliação e objetivo não são
   copiados.
6. **Estádio sugerido** — cultura soja (ou vazia) com DAE: pré-seleciona o
   estádio de maior `dap` ≤ DAE em `kEstadios` (o seed conta `dap` a partir
   de VE = 0, ou seja, dias após a emergência). Só quando nenhum estádio foi
   escolhido.
7. **Talhão** — `writeBackTalhaoPlantio` substitui o atual: ao salvar uma
   ocorrência Plantio, grava no talhão cultura, material (cultivar), safra,
   início, emergência e ciclo não vazios via `IDrawingFieldWriter`. Na
   edição, só se o Plantio for o mais recente da sua safra. Outras
   categorias não gravam no talhão. Término do plantio não vai para o
   talhão. Falha do writer não desfaz a ocorrência.
8. **Detalhe** — linhas Cultura e Safra após Cultivar.

## Não-objetivos

- Alterar contratos de `core/contracts/` ou o módulo `drawing/`.
- Histórico em tabela própria: o histórico são as próprias ocorrências de
  Plantio, separadas por safra.
- Sugerir estádio para culturas além da soja.

## Consequências

- Ocorrências antigas ficam com cultura/safra nulas até serem salvas de
  novo; o contexto deriva a safra das datas.
- O talhão passa a refletir o Plantio mais recente (replantio/correção),
  inclusive sobrescrevendo valores já preenchidos.
- A migration Supabase precisa estar aplicada no projeto live antes do push
  das duas colunas; sem ela o upsert remoto falha.
