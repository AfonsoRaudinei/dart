# ADR-063 — Ocorrência Plantio em duas fases (Execução + Emergência)

**Data:** 17/11/2026  
**Status:** APROVADO  
**Módulos:** `consultoria/occurrences/`, `core/database/`, Supabase `occurrences`

## Contexto

Plantio na visita pode ser registrado em dois momentos: acompanhamento da
semeadura (execução) e validação da emergência em visita posterior. Às vezes o
consultor só confere a emergência, sem ter acompanhado o plantio.

O formulário único e longo misturava execução e emergência e sugeria
`data_plantio` como pré-requisito implícito para salvar.

## Decisão

1. **Duas fases no UX** — resumo compacto + sanfonas Execução e Emergência no
   card Plantio. Atalho “Acompanhar emergência” foca a fase Emergência.
2. **Estados derivados (não persistidos)** — chip de status:
   `Validação pendente` | `Execução não acompanhada` | `Completo`, calculado
   dos campos preenchidos.
3. **SQLite v55** — `occurrences.data_validacao TEXT` (ISO `yyyy-MM-dd`),
   `occurrences.avaliacao_emergencia TEXT` (`boa` | `ruim`, mesmo sanitizer de
   `avaliacao_plantio`).
4. **Supabase** — `20261117_occurrences_plantio_validacao.sql` com
   `add column if not exists`. Sync no mesmo tier dos campos de plantio v47/v51.
5. **Salvar Plantio** — permitido com execução **ou** emergência **ou**
   cultivar + emergência; emergência-only **sem** exigir `data_plantio`.
6. **Write-back talhão** — inalterado na política ADR-059: categoria plantio,
   parcial permitido (emergência-only pode gravar datas/cultura sem plantio).
7. **Detalhe** — linhas “Validação (visita)” e “Avaliação da emergência” quando
   preenchidas.

## Não-objetivos

- Enum ou coluna de “fase” no banco.
- Alterar outras categorias de ocorrência (ADR-059).
- Relatório HTML neste ciclo.
- Segundo campo de estande: continua `estande_plantas` (planejado vs observado
  só no rótulo da UI).

## Consequências

- Ocorrências legadas sem validação ficam com `data_validacao` e
  `avaliacao_emergencia` nulos até nova edição.
- Migration Supabase deve estar aplicada antes do push dos novos campos.