# PRD — Restore após reinstall (fechar 100% via IPA)

**Produto:** SoloForte App (Flutter · iOS · Android · Map-First)  
**Versão do documento:** 1.0  
**Data:** 22/Ago/2026  
**Status:** ATIVO — execução  
**Placar vivo:** `.agent/CHECKLIST_RESTORE_REINSTALL.md`  
**Cadeado:** `docs/03_ENFORCEMENT/supervisor-merge-gate.md` · REGRA-ENTREGA-1  
**Contrato remoto carteira:** ADR-051  
**Live:** `pyoejhhkjlrjijiviryq`

---

## 1. Resumo

Desinstalar o app apaga o sandbox (`soloforte.db`). Logout **não** apaga. O consultor precisa reabrir a **mesma conta** e ver de volta o que já estava no remoto.

O código e o SQL live **já estão prontos** (40/100). Os 60 pontos que faltam **não são feature nova**: são um IPA que contém `173ce7b` e um ciclo de prova no iPhone.

**Estado agora:** 40%  
**Meta deste PRD:** 100% da trilha restore (tabela de 8 itens)  
**Prova:** IPA. Não é `flutter run`. Não é hot restart.

---

## 2. Problema

| Fato | Consequência |
|---|---|
| IPA 223 = SHA `36b3527` (19/Ago) | **Não** tem PRs #67/#68 (hydrate, carteira remota) |
| Live carteira/mapa/relatórios/marketing = `0` linhas | Desinstalar agora **perde** o que só existe no SQLite local |
| Simulador / iPhone vazio | Não prova restore da conta real |

**Capacidade que este PRD usa:** 1 Mac com certificado de Distribution, 1 iPhone com os dados locais ainda instalados, 1 sessão de TestFlight/ad hoc, supervisor para counts no live (sem PII). **Não usa** Cloud Agent para archive iOS. **Não usa** executor Flutter no caminho feliz.

---

## 3. Objetivo e definição de 100%

Consultor com IPA `1.34.0+224` (ou maior, desde que o SHA do archive contenha `173ce7b`):

1. Atualiza **por cima** (Fase A) → dados sobem ao live.  
2. Desinstala e reinstala o **mesmo** IPA (Fase B) → mapa, carteira, lista de relatórios e casos de marketing publicados voltam.

**100% = 100 pontos** da tabela abaixo, todos verdes.

| # | Item | Pontos | Estado 22/Ago |
|---|---|---:|---|
| 1 | Código `main` hydrate + relatórios + marketing (#67) | 25 | feito |
| 2 | Código `main` carteira + SQL live (#68) | 15 | feito |
| 3 | IPA contendo `173ce7b`+ (`+224`, não reutilizar `+223`) | 15 | **falta** |
| 4 | Fase A: IPA por cima + live counts sobem | 20 | **falta** |
| 5 | Fase B mapa | 7 | **falta** |
| 6 | Fase B carteira | 8 | **falta** |
| 7 | Fase B lista de relatórios | 5 | **falta** |
| 8 | Fase B marketing publicado | 5 | **falta** |

### Superfície vazia na conta (não prende os 100%)

Se na Fase A a conta **não tem** aquela superfície (`N = 0` no aparelho **e** live `0` com evidência), o item pontua como **N/A comprovado** (recebe os pontos). Não inventar dado. Não usar draft/local_only para “criar” prova.

Se `N > 0` na Fase A e a Fase B não devolver, o item fica **0** — trilha não fecha.

---

## 4. Escopo

### Dentro (fecha os 100%)

- Bump `1.34.0+224` em `origin/main` e archive IPA (`./build_testflight.sh`)
- Instalar esse IPA **por cima** da instalação que ainda tem SQLite
- Hydrate logado com rede
- Um wipe (desinstalar) + reinstalar o mesmo IPA + mesmo login
- Conferir 4 superfícies (ou N/A comprovado)

### Fora (não entram nos 100%; outro PRD se o produto pedir)

| Tema | Capacidade hoje |
|---|---|
| Publicações técnicas | **Zero** — não há tabela remota; proibido mapear em pins `publicacoes` |
| Corpo rico do relatório (fotos, talhões, snapshots) | **Zero** — `relatorios_v2` é lossy |
| Foto de ocorrência no sheet | **Zero** — `photo_path` é arquivo local |
| Relatório `local_only` / marketing `draft` | **Zero** — módulo não faz push |
| P2 `saveToCache` apagar drafts | Débito; não bloqueia restore publicado |
| `REVOKE` GRANT default Postgres | RLS já barra; hardening opcional |
| Android APK deste ciclo | Fora desta prova (iOS IPA). `allowBackup=false` já vale se no futuro houver ciclo Android |

### Não fazer neste PRD

- Novo módulo, ADR, contrato, rota, tema, FAB, `pop()`, sub-rota em `/map`
- Alterar `smart_button.dart`
- `git push origin main` / `gh pr merge --admin`
- Reutilizar build `+223`

---

## 5. Capacidade por papel

| Papel | Consegue | Não consegue |
|---|---|---|
| **Humano no Mac** | `git pull` `main`, bump `+224`, `./build_testflight.sh`, TestFlight | Provar restore sem o iPhone com dados |
| **Humano no iPhone** | Update por cima, anotar N, desinstalar, reinstalar, login | Ver counts do Postgres |
| **Supervisor (este chat)** | Counts live sem PII, atualizar placar, gate de fase | Archive IPA, desinstalar o app, tocar UI |
| **Executor Flutter** | Só se Fase B falhar (contingência) | Não entra no caminho feliz |
| **Cloud Agent Linux** | PR de bump `pubspec` | Codesign / keychain deste Mac |

Uma fase só avança com a capacidade da linha. Não paralelizar o que tem dependência dura.

---

## 6. Fases menores (caminho feliz · 40% → 100%)

Ordem **estrita**. Não pular. Cada fase tem teto de tempo e um único entregável.

### F0 — Já entregue (40 pts) — capacidade: nenhuma agora

Código #67/#68 na `main` + 7 tabelas carteira no live.  
**Saída:** placar 40%. Não reabrir salvo regressão.

---

### F1 — IPA `+224` (15 pts) · 40% → 55%

**Capacidade:** Mac local + certificado iOS Distribution + `main` = `173ce7b`+. ~30–90 min. Cloud Agent não substitui o archive.

| Micro | Quem | Fazer | Pronto quando |
|---|---|---|---|
| F1.1 | Executor + supervisor | Bump `pubspec.yaml` `1.34.0+224` (commit por arquivo, PR, rebase). Path não crítico | `mergedAt` na `main` |
| F1.2 | Humano Mac | `git pull origin main` · `./build_testflight.sh` · `./tool/release_store_check.sh` | IPA em `build/ios/ipa/soloforte_app.ipa`, `CFBundleVersion=224`, `SUPABASE_URL` do live |
| F1.3 | Humano Mac | Enviar TestFlight (ou ad hoc no mesmo UDID) · registrar em `AGENTIPA.md` | Build processável no aparelho |

**Proibido:** archive em cima de `+223`; archive de SHA anterior a `173ce7b`.

**Bloqueio típico:** codesign / “No Accounts” — parar; não marcar F1. Capacidade extra: restaurar certificado, não “inventar” IPA velho.

---

### F2 — Fase A, push (20 pts) · 55% → 75%

**Capacidade:** o **mesmo** iPhone que ainda tem a conta e o SQLite. 10–20 min. Simulador = capacidade **zero**.

| Micro | Quem | Fazer | Pronto quando |
|---|---|---|---|
| F2.1 | Humano iPhone | Instalar IPA 224 **por cima**. **Não** apagar o app | Versão do app mostra `224` (ou build TestFlight correspondente) |
| F2.2 | Humano iPhone | Abrir **já logado**, rede ligada, esperar hydrate (não forçar “conta nova”) | Mapa/carteira ainda visíveis como antes |
| F2.3 | Humano iPhone | Anotar N: clientes; safras/lançamentos; títulos de relatório; casos **publicados** | Quatro números (podem ser 0) |
| F2.4 | Supervisor | Counts live, sem PII | Para cada superfície com N>0 no aparelho, a tabela remota correspondente `> 0` |

**Não desinstalar** se F2.4 falhar. Investigar sync/JWT/rede. Placar F2 permanece 0.

---

### F3 — Fase B, wipe + pull (25 pts) · 75% → 100%

**Capacidade:** um único desinstalar. As quatro conferências cabem na **mesma** sessão (~15–25 min). Não precisa de quatro wipes.

**Pré-condição dura:** F2.4 verde (ou N/A comprovado em todas as superfícies — aí F3 é no-op e os pontos N/A já estão no placar; wipe ainda vale como prova de “conta vazia continua vazia e não crasha”).

| Micro | Quem | Pontos | Passa | Fora (não falha a trilha) |
|---|---|---:|---|---|
| F3.0 | Humano iPhone | 0 | Apagar o app → instalar o **mesmo** IPA 224 → mesmo login → hydrate | — |
| F3.1 | Humano iPhone | 7 | Clientes, fazendas, talhões, ocorrências voltam | Foto de sheet |
| F3.2 | Humano iPhone | 8 | Tipos, categorias, config, safras, metas, vínculos, lançamentos (sem tombstone) | — |
| F3.3 | Humano iPhone | 5 | Lista (título/notas) | Corpo rico / fotos / talhões |
| F3.4 | Humano iPhone | 5 | Casos publicados | `draft` / `local_only` |

**Falha imediata (zera F3.1–F3.4 aplicáveis):** bootstrap “conta nova” com live já tendo linhas daquela superfície.

F3.1–F3.4 são independentes no placar: mapa pode passar e marketing falhar. 100% só com todos os aplicáveis verdes.

---

### F4 — Fechar o placar (0 pts de produto, obrigatório de processo)

**Capacidade:** supervisor, 5 min.

- Atualizar `.agent/CHECKLIST_RESTORE_REINSTALL.md` para **100%**
- Uma linha em `AGENTIPA.md` (IPA 224 + SHA)
- Não declarar “no app” se o TestFlight ainda não estiver no aparelho que passou F3

---

## 7. Sequência visual

```
F0 40% ──────────────────────────────────────── já feito
F1.1 bump 224 ──► F1.2 archive ──► F1.3 TestFlight     +15 → 55%
F2.1 update ──► F2.2 hydrate ──► F2.3 anotar ──► F2.4 live +20 → 75%
F3.0 wipe ──► F3.1 mapa / F3.2 carteira / F3.3 relatórios / F3.4 marketing
                                                      +25 → 100%
F4 registro
```

Não há atalho F1 → F3. Sem F2 o live continua 0 e o wipe apaga o único original.

---

## 8. Contingência (fora do 100% feliz)

Só abre se F2.4 ou F3.x aplicável falhar. **Não** misturar com o placar até o fix estar em `origin/main` **e** um IPA **`+225`** (não reutilizar `+224`).

| Sintoma | Hipótese de capacidade | Quem |
|---|---|---|
| Live continua 0 após F2 | JWT/hydrate, módulo não registrado, RLS, SQL live | Supervisor lê logs; executor só com brief fechado |
| Mapa volta, carteira não | Push carteira / colunas / RLS | Executor `carteira/` + path crítico `core/database` se tocar schema |
| Lista de relatórios vazia com N>0 na F2 | só `pending_sync` sobe; `local_only` não é bug deste PRD | Produto: publicar um relatório **antes** de repetir F2 |
| Marketing vazio com N>0 na F2 | draft não sobe | Produto: um caso publicado **antes** de repetir F2 |
| “Conta nova” com live > 0 | bootstrap não espera pull | Executor `private_map_bootstrap_screen` / session hydrate |

Gate: P0/P1 não mergeia; path crítico pede ok; depois IPA novo.

---

## 9. Critérios de aceite (produto)

- [ ] IPA `CFBundleVersion ≥ 224` gerado de `origin/main` que contém `173ce7b`
- [ ] Fase A sem uninstall; live counts sobem onde N>0
- [ ] Fase B: mesmo IPA, mesmo login; superfícies aplicáveis restauram
- [ ] Placar 100/100 (ou N/A comprovado nos itens 5–8 vazios)
- [ ] Nenhuma das linhas “fora de escopo” usada como critério de passa

---

## 10. Próxima ação única

**F1.1 + F1.2:** bump `1.34.0+224` na `main` e archive neste Mac. Sem esse IPA, F2 e F3 têm capacidade zero.
