# Checklist — restore após reinstall (IPA)

**PRD (fases + capacidade):** `docs/PRD_RESTORE_REINSTALL_IPA.md`  
**Data:** 22/Ago/2026 (noite: F2.4 live ainda 0)  
**Prova no aparelho:** IPA. Não é `flutter run`. Hot restart não conta.  
**100%:** soma dos 8 itens = 100 pontos. Fora de escopo **não entra**.  
**Cadeado:** `docs/03_ENFORCEMENT/supervisor-merge-gate.md` · REGRA-ENTREGA-1  
**Live:** `pyoejhhkjlrjijiviryq`

**Como marcar ponto:** SHA em `origin/main`, migration no live, ou QA no IPA. Código na branch ≠ feito.

---

## Placar — **55%** (55 / 100)

| # | Critério | Peso | Item | Pontos |
|---|---|---:|---|---:|
| 1 | Código na `main`: hydrate + relatórios + marketing | 25 | **100%** · PR [#67](https://github.com/AfonsoRaudinei/dart/pull/67) `94a8ddc` | **25** |
| 2 | Código na `main`: carteira + SQL no **live** | 15 | **100%** · PR [#68](https://github.com/AfonsoRaudinei/dart/pull/68) `173ce7b` · migration `20260822223918` | **15** |
| 3 | IPA gerado **depois** de `173ce7b` | 15 | **100%** · IPA 224 · bump PR [#70](https://github.com/AfonsoRaudinei/dart/pull/70) `bd1fabb` · `./build_testflight.sh` Exit 0 | **15** |
| 4 | Fase A: IPA por cima, live counts sobem | 20 | **0%** · após tela Sincronizando, live mapa/carteira/relatórios/marketing cases = 0 | **0** |
| 5 | Fase B — mapa | 7 | **0%** · bloqueada (sem F2.4) | **0** |
| 6 | Fase B — carteira | 8 | **0%** · bloqueada | **0** |
| 7 | Fase B — lista de relatórios | 5 | **0%** · bloqueada | **0** |
| 8 | Fase B — marketing publicado | 5 | **0%** · bloqueada | **0** |
| | **Trilha restore** | **100** | | **55** |

Reparos de **código + SQL + IPA** estão entregues. A prova de restore (itens 4–8) **não**. Wipe neste aparelho **não** fecha os 100%.

---

## Feito

- [x] Hydrate + bootstrap espera/retry — #67
- [x] Relatórios / marketing sync modules — #67
- [x] Carteira ADR-051 + SQLite v42 + SQL live — #68
- [x] IPA `1.34.0+224` neste Mac (não reutilizar `+223`)

## Não feito (não marcar 100%)

- [ ] F2.4 live > 0 (este install não empurrou clientes/carteira)
- [ ] F3 wipe + pull das 4 superfícies
- [ ] Transporter/TestFlight se o 224 ainda não estiver no aparelho da conta cheia

## Fora desta trilha

Publicações técnicas, corpo rico do relatório, foto de sheet, `local_only` / draft — não restauram hoje.

---

## Próximo passo único

**Não desinstalar** esperando a nuvem devolver mapa/carteira.  
Se houver iPhone com SQLite antigo intacto: 224 **por cima**. Senão: reparo de código encerrado em 55% de prova.
