# Checklist — restore após reinstall (IPA)

**PRD (fases + capacidade):** `docs/PRD_RESTORE_REINSTALL_IPA.md`  
**Data:** 31/Ago/2026 (IPA 227 wipe+reinstall: cliente voltou)  
**Prova no aparelho:** IPA. Não é `flutter run`. Hot restart não conta.  
**100%:** soma dos 8 itens = 100 pontos. Fora de escopo **não entra**.  
**Cadeado:** `docs/03_ENFORCEMENT/supervisor-merge-gate.md` · REGRA-ENTREGA-1  
**Live:** `pyoejhhkjlrjijiviryq`

**Como marcar ponto:** SHA em `origin/main`, migration no live, ou QA no IPA. Código na branch ≠ feito.

---

## Placar — **82%** (82 / 100)

| # | Critério | Peso | Item | Pontos |
|---|---|---:|---|---:|
| 1 | Código na `main`: hydrate + relatórios + marketing | 25 | **100%** · PR [#67](https://github.com/AfonsoRaudinei/dart/pull/67) `94a8ddc` | **25** |
| 2 | Código na `main`: carteira + SQL no **live** | 15 | **100%** · PR [#68](https://github.com/AfonsoRaudinei/dart/pull/68) `173ce7b` · migration `20260822223918` | **15** |
| 3 | IPA gerado **depois** de `173ce7b` | 15 | **100%** · IPA 224 · bump PR [#70](https://github.com/AfonsoRaudinei/dart/pull/70) `bd1fabb` · `./build_testflight.sh` Exit 0 | **15** |
| 4 | Fase A: live counts sobem | 20 | **100%** · 31/Ago/2026 IPA 227 wipe+reinstall — live clients > 0 (usuário confirmou cliente voltou) | **20** |
| 5 | Fase B — mapa | 7 | **100%** · IPA 227 wipe+reinstall — cliente voltou no mapa | **7** |
| 6 | Fase B — carteira | 8 | **0%** · sem prova no IPA 227 | **0** |
| 7 | Fase B — lista de relatórios | 5 | **0%** · sem prova no IPA 227 | **0** |
| 8 | Fase B — marketing publicado | 5 | **0%** · sem prova no IPA 227 | **0** |
| | **Trilha restore** | **100** | | **82** |

Mapa/cliente fechou prova no IPA 227. Carteira, relatórios e marketing **não** — itens 6–8 permanecem 0 até wipe-prova.

**Contingência (31/Ago/2026, sem wipe):** live counts carteira/relatórios/marketing = 0. Push de marketing no IPA 227 ia falhar (PGRST204: `toJson()` com chaves ausentes). Live ganhou as colunas; PR [#84](https://github.com/AfonsoRaudinei/dart/pull/84) `d7582c1` whitelist `toRemoteRow`. Carteira (`allowedColumns`) e relatórios (`toRemoteRow`) já batiam com o live. IPA 227 sem wipe ainda precisa **criar/publicar** nas 3 superfícies para os counts subirem.

---

## Feito

- [x] Hydrate + bootstrap espera/retry — #67
- [x] Relatórios / marketing sync modules — #67
- [x] Carteira ADR-051 + SQLite v42 + SQL live — #68
- [x] IPA `1.34.0+224` neste Mac (não reutilizar `+223`)
- [x] IPA 227 wipe+reinstall — cliente voltou (itens 4 e 5, 31/Ago/2026)

## Não feito (não marcar 100%)

- [ ] Fase B carteira (item 6)
- [ ] Fase B lista de relatórios (item 7)
- [ ] Fase B marketing publicado (item 8)

## Fora desta trilha

Publicações técnicas, corpo rico do relatório, foto de sheet, `local_only` / draft — não restauram hoje.

---

## Próximo passo único

No **mesmo IPA 227, sem desinstalar**: criar/editar carteira; gerar relatório e **Publicar**; criar case de marketing e **Publicar**. Avisar `sincronizei carteira/relatorio/marketing`. Wipe só depois de live counts > 0 nessas três tabelas.
