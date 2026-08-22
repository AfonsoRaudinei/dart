# Checklist — restore após reinstall (mesmo login)

**Data:** 22/Ago/2026  
**Trilha:** desinstalar apaga o sandbox (`soloforte.db`); logout **não** apaga. Restore = hydrate no login + pull remoto.  
**Cadeado de merge:** `docs/03_ENFORCEMENT/supervisor-merge-gate.md` (código na `main` = `mergedAt`; auto-merge armado **não** conta).  
**Fontes:** `.agent/AGENT_MEMORIA.md` · `.agent/AGENT_REGRAS.md` · `.agent/Prompt.md` (REGRA-ENTREGA-1) · `.agent/AUDITORIA_REGRESSAO_IPA210.md` (não misturar com SheetSkin; só blast/transversal).  
**Projeto live:** `pyoejhhkjlrjijiviryq` (SoloForte Dart) · `https://pyoejhhkjlrjijiviryq.supabase.co`

**Como marcar:** `[x]` só com evidência (SHA em `origin/main`, migration no live, ou QA no aparelho). `[ ]` = não concluído. Não promover “código na branch” a feito.

---

## Concluído

### Código na `main` (REGRA-ENTREGA-1)

- [x] Hydrate após auth + bootstrap espera/retry se `clients==0` — PR [#67](https://github.com/AfonsoRaudinei/dart/pull/67) · `94a8ddc`
- [x] Relatórios: `RelatorioSyncModule` tier 1 ↔ `public.relatorios_v2` (lossy: título/notas/ids; **não** apaga snapshot rico local)
- [x] Marketing: `MarketingSyncModule` tier 1 (`pending_sync` → push; depois `getCases(forceSync: true)`)
- [x] Carteira ADR-051: SQLite v42 + `CarteiraSyncModule` tier 1 + soft delete — PR [#68](https://github.com/AfonsoRaudinei/dart/pull/68) · `173ce7b`
- [x] Opportunity lookup ignora tombstone (`deleted_at IS NULL`)
- [x] Mac local em `main` = `origin/main` `173ce7b` (Cursor Desktop)

### Schema live (esta sessão, 22/Ago/2026)

- [x] SQL do repo `supabase/migrations/20260822190000_carteira_remote_sync.sql` aplicado no live via MCP `apply_migration`
- [x] Histórico remoto: versão `20260822223918` nome `carteira_remote_sync` (timestamp MCP ≠ filename do repo; SQL idêntico)
- [x] 7 tabelas existem, RLS ligado, 3 policies cada (SELECT/INSERT/UPDATE `authenticated` + `user_id = auth.uid()`)
  - `carteira_tipos_produto` · `carteira_categorias` · `carteira_config` · `carteira_safras` · `carteira_metas` · `carteira_cliente_categorias` · `carteira_lancamentos`
- [x] Sem policy anônima nas 7 tabelas (anon com GRANT default do Postgres **não** passa RLS)

---

## Não concluído

### Bloqueia “carteira volta no aparelho”

- [ ] **QA dispositivo (obrigatório):** com binário que contém `173ce7b`+  
  1. Abrir o app **uma vez** logado (push da carteira local → live; tabelas live ainda `rows: 0` até esse passo)  
  2. Desinstalar  
  3. Reinstalar + mesmo login  
  4. Conferir tipos, categorias, safras, metas, vínculos cliente, lançamentos  
  **Hot restart não basta** se o IPA/APK for anterior a #67/#68 (`AGENT_MEMORIA.md`).
- [ ] Mesmo ciclo para **núcleo do mapa** (clientes/fazendas/talhões/ocorrências) — código já na `main`; falta prova no aparelho
- [ ] Mesmo ciclo para **lista de relatórios** (metadados `relatorios_v2`) e **casos de marketing publicados** (`pending_sync` / não-draft)

### Fora de escopo desta trilha (não restauram hoje)

- [ ] Publicações técnicas: **não há** tabela remota `publicacoes_tecnicas` no repo — **não** mapear em pins `publicacoes` (ADR-007). Só avança com ADR + migration se o produto pedir
- [ ] Corpo rico do relatório (fotos, talhões, snapshots) — nunca esteve em `relatorios_v2`
- [ ] Fotos de ocorrência em sheet (`photo_path` = arquivo local; some com o sandbox)
- [ ] Relatórios ainda `local_only` / não publicados — o módulo **não** faz push
- [ ] Rascunhos de marketing `local_only` / `draft` — o módulo **não** faz push

### Débito conhecido (não bloqueia schema live)

- [ ] P2 marketing: `saveToCache` delete-all pode apagar rascunhos locais se a lista remota não for vazia (agravado pelo hydrate em todo login — nota do revisor #67)
- [ ] Defense-in-depth Postgres: `GRANT` default de `public` ainda lista DELETE/TRUNCATE para `anon` e `authenticated`. **RLS barra** (sem policy DELETE, sem policy anon). `REVOKE` extra **não** está no SQL do ADR-051; só fazer se pedirem hardening explícito
- [ ] Advisors de segurança pré-existentes no projeto (funções `SECURITY DEFINER` executáveis, OTP longo, leaked-password off, Postgres 17.4.1 com patch disponível, extension `vector` em `public`). **Não** nascem desta migration; não misturar neste PR

### Cadeado / processo (esta trilha)

- [x] Path crítico `lib/core/database/` já passou pelo gate no PR #68 (ok no chat + `mergedAt`)
- [ ] Próximo código Flutter desta trilha: executor + revisor DIFF; P0/P1 não mergeia; P2 pede ok; path crítico pede ok de novo (`supervisor-merge-gate.md`)
- [ ] IPA/archive novo **depois** do QA — não reutilizar `+N` (`AGENT_REGRAS.md` REGRA-SHEET-BLAST-1 / release)

---

## O que “feito” **não** é

| Aparência | Verdade |
|---|---|
| SQL só no Git | Restore de carteira **impossível** até o live ter as tabelas — **já resolvido nesta sessão** |
| Tabelas live vazias (`rows: 0`) | Esperado até o aparelho com dados locais abrir **uma vez** e fazer push |
| Auto-merge armado | **Não** está na `main` (`AGENTS.md` REGRA-ENTREGA-1) |
| Hot restart | Não atualiza binário antigo |

---

## Próximo passo único

No Cursor Desktop Mac, com `main` = `173ce7b`: **rodar o app logado (push) → desinstalar → reinstalar → login** e marcar o item de QA da carteira acima.
