# Prompt de correção — revisão do chat Plantio / Supabase / IPA 321

> Cole no agente na pasta `~/dev/appdart`.
> Objetivo: fechar os itens que **não** estão em 100%. Não refazer o que já está na `main`.

## Já entregue (não mexer)

| Item | Evidência |
|---|---|
| Ficha Plantio (clareza, fazenda/talhão, rótulos, ciclo, término, contexto por safra, write-back do talhão salvo) | PRs #456 #457 #458 #460 mergeados |
| Testes da toolbar do talhão | PR #459 |
| Cabeçalhos de seção sem emoji + `AGENTS.md` schema v52 | PR #461 |
| Colunas live `occurrences.data_fim_plantio`, `ciclo_dias`, `cultura`, `safra` | HTTP 200 no PostgREST; `migration repair` de `20261109230000` e `20261109240000` |
| Histórico de migrations | `supabase migration list --linked` casa local = remoto, **exceto** a linha abaixo |
| IPA 320 | Rejeitado pela Apple (90186 + 90062). **Não reenviar.** |
| IPA 321 | `1.35.0+321`, `~/Desktop/soloforte_app_321.ipa`, `main` @ `0ca6b88f`. Binário ok. Aceite no App Store Connect **não confirmado**. |

## Correção 1 — última migration órfã (código)

Produção já tem a versão `20260831191135`. O arquivo que a espelha existe só no commit `8326d414` (branch `claude/supabase-verify-tables-8276dd`), **não** na `main`.

```bash
git fetch origin
git checkout -b cursor/supabase-mirror-20260831191135-3322 origin/main
git cherry-pick 8326d414
# NÃO rodar o SQL de novo no banco. A versão remota já está applied.
supabase migration list --linked
# Esperado: zero linhas com Local vazio ou Remote vazio.
```

Abrir PR para `main`. Sem `db push`, sem `db reset`. Se o cherry-pick conflitar, copiar só o arquivo `supabase/migrations/20260831191135_marketing_cases_restore_push_columns.sql`.

## Correção 2 — confirmar o IPA 321 na Apple (humano)

1. Transporter: enviar **somente** `~/Desktop/soloforte_app_321.ipa`.
2. App Store Connect: versão **1.35.0**, build **321**.
3. Se a Apple recusar, colar o código do erro aqui. Não gerar outro IPA com `1.34.0` nem reutilizar o build 321.

## Correção 3 — conferência no aparelho (humano)

Com o 321 instalado, num talhão com Plantio da safra atual:

- [ ] Nova ocorrência de outra categoria mostra o bloco "Dados do plantio" só leitura.
- [ ] Campos vazios de uma ocorrência antiga são preenchidos; campos já preenchidos não são sobrescritos.
- [ ] Editar o Plantio mais recente atualiza o talhão (cultivar, datas, término, ciclo, cultura, safra).
- [ ] Depois de sincronizar, a ocorrência não fica presa em pendente.

## Fora de escopo

Emojis do enum de categorias (`occurrence.dart`), nível de água e o aviso de estádio. Foram deixados de propósito.
