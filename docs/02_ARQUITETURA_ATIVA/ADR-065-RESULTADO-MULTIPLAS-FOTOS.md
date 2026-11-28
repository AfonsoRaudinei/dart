# ADR-065 — Resultado: múltiplas fotos (1–5) com capa legada + carrossel

**Data:** 27/11/2026  
**Status:** APROVADO  
**Módulos:** `marketing/`, `core/html_templates/` (renderer de marketing), Supabase `marketing_cases`

## Contexto

O case tipo Resultado aceitava exatamente uma foto (`foto_principal_url`). O
consultor precisa registrar o resultado da área com mais de um ângulo, e o
relatório HTML só tinha um hero.

## Decisão

1. **Limite** — de 1 a 5 fotos por case Resultado. Mínimo 1 continua
   obrigatório: publicar ou salvar edição sem foto é bloqueado em
   `novo_case_sheet` e `edit_case_sheet` (mesma mensagem de antes). O máximo
   vive em `kMarketingResultadoFotosMax` (`domain/marketing_resultado_fotos.dart`).
2. **Dado remoto** — nova coluna `marketing_cases.fotos_resultado_json TEXT`
   nullable, JSON array de URLs em string (mesma convenção de
   `avaliacoes_json` e `parametros_json`). Sem índice, sem backfill.
3. **Capa legada** — `foto_principal_url` continua existindo e é sempre a 1ª
   foto da lista. Pin do mapa, story e leitores antigos seguem lendo só ela.
4. **Entidade** — `MarketingCase.fotosResultado` (`List<String>`, default
   `const []`) e o getter `fotosResultadoEfetivas`: lista própria quando
   preenchida; senão `[fotoPrincipalUrl]`; senão vazia. Cases legados com uma
   foto funcionam sem migração de dados. `fromJson` aceita String JSON, List
   ou null; valor malformado vira lista vazia sem lançar; strings vazias são
   descartadas e o limite é aplicado.
5. **Repositório** — `fotos_resultado_json` entra em `remoteColumns`. O cache
   local (`marketing_cases.db`, blob JSON) não precisa de migration; o SQLite
   principal (schema v55) não muda.
6. **Captura** — `FotosResultadoPickerWidget`: miniaturas horizontais, remover
   com confirmação, tile “Adicionar foto” enquanto houver menos de 5, contador
   N/5. Upload de uma foto por vez via `MarketingPhotoService`
   (pasta `resultado`). `FotoPickerWidget` segue só para Antes/Depois e
   Avaliação. A 1ª miniatura exibe o selo **Capa** (é a que alimenta pin,
   story e `foto_principal_url`). Com 2 ou mais fotos, toque na área da miniatura
   (fora do X de remover) move essa URL para a 1ª posição e dispara
   `onChanged` — sem schema novo, só reordenação da lista.
7. **Leitura** — no sheet do case, 2 ou mais fotos viram carrossel
   (`PageView` + pontinhos); com 1 foto o visual anterior permanece.
8. **Relatório HTML** — o hero é a 1ª foto; as fotos 2..N entram como figuras
   extras na seção “Registro fotográfico”, legenda “Foto N” (+ data quando
   houver). Toda `<img>` de foto começa com `<img data-sf-photo `. O parse da
   lista fica em `core/html_templates/marketing_resultado_fotos_html.dart`
   (sem importar `modules/`).
9. **Campo de teste (ADR-064)** — a foto do seed (`seed.photoPath`) vira a 1ª
   foto da lista.

## Compatibilidade

- Cases antigos: `fotos_resultado_json` nulo; a capa vira a lista efetiva.
- Apps antigos ignoram a coluna nova e continuam lendo `foto_principal_url`.
- Edição de um case antigo grava a lista (capa = 1ª foto, lista = efetivas).
- Ao salvar Antes/Depois ou Avaliação, `fotos_resultado_json` é zerado junto
  com `foto_principal_url`.

## Migration

`supabase/migrations/20261127230000_marketing_cases_fotos_resultado_json.sql`
(`ADD COLUMN IF NOT EXISTS` + `COMMENT`, idempotente).

**Pré-requisito de release:** aplicar a migration no Supabase **antes** de
publicar a versão do app. A coluna entra em `remoteColumns` e o upsert falha
com `PGRST204` se ela não existir.

## Limitações conhecidas

- Story e pin do mapa mostram só a capa (1ª foto).
- Não há multisseleção de arquivos: cada foto é enviada em um passo.

## Não-objetivos

- Múltiplas fotos para Antes/Depois e Avaliação (já têm blocos próprios).
- Alterar `marketing_case_marker` ou o story.
- Mudança de schema do SQLite principal.
