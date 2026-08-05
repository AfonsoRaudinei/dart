# PROMPT FIX — MIGRAÇÃO REAL `publicacoes_tecnicas`

**Fonte:** `prompt/AUDITORIA_OFFLINE_FIRST_RELATORIO.md` — Dimensão 9 (CRÍTICO)  
**Agente:** Engenheiro Sênior Flutter/Dart — Persistência SQLite / Schema  
**Prioridade:** 🔴 CRÍTICO — install limpo pode crashar ao inserir publicação  
**Tipo:** correção de schema · escopo fechado · zero improviso  
**Declaração:** `@MÓDULO: PERSISTENCIA_OFFLINE`

---

## 0️⃣ PASSO 0 — OBRIGATÓRIO

```bash
find lib/ -name "database_helper.dart"
find lib/ -name "database_migrations*.dart"
find lib/ -name "publicacao_table.dart"
find lib/ -name "publicacao_repository_impl.dart"
rg -n "publicacoes_tecnicas|migrateToV12|migrateToV4[0-9]|version:" \
  lib/core/database/ lib/modules/consultoria/publicacoes/
```

Ler:

- `lib/modules/consultoria/publicacoes/data/publicacao_table.dart` (DDL de referência)
- `lib/core/database/database_migrations_v1_v23.dart` `migrateToV12` (hoje no-op)
- `lib/core/database/database_helper.dart` (version atual = **40**)
- ADR-009 se existir em `docs/02_ARQUITETURA_ATIVA/`

---

## 1️⃣ DECLARAÇÃO

```
Módulo:       core/database (+ consultoria/publicacoes DDL de referência)
Bounded ctx:  core · consultoria/publicacoes
Objetivo:     Garantir CREATE TABLE publicacoes_tecnicas em install limpo e upgrade
Arquivos:     database_helper.dart (bump versão),
              database_migrations*.dart (nova migrateToV41 ou corrigir caminho),
              publicacao_table.dart (apenas se precisar alinhar comentário DDL),
              testes de migração se existirem
Contrato:     NÃO altera contratos Riverpod/API; só schema SQLite
Fronteira:    NÃO
```

---

## 2️⃣ BUG CONFIRMADO

1. `PublicacaoTable` documenta DDL e afirma migração em `DatabaseHelper._migrateToV12`  
   → `publicacao_table.dart`
2. `migrateToV12` é **no-op** (“Reservada — sem alterações”)  
   → `database_migrations_v1_v23.dart:369-372`
3. Nenhum `CREATE TABLE ... publicacoes_tecnicas` nas migrações  
   → `rg CREATE TABLE.*publicacoes` em `lib/core/database` = vazio
4. `clearUserLocalData` e `_validateSchema`/listas V21 **referenciam** a tabela  
   → crash ou silêncio em ALTER se tabela ausente; insert do repo falha em install limpo
5. Schema runtime atual: **v40** (`database_helper.dart:27`)

---

## 3️⃣ CORREÇÃO OBRIGATÓRIA

### A) Nova migração (preferido: v41)

**Não** reabrir `migrateToV12` no-op histórico se installs intermediários já passaram por v12 — preferir:

1. Bump `openDatabase(version: 41)` em `database_helper.dart`
2. Adicionar `migrateToV41` em `database_migrations_v24_v38.dart` (ou arquivo v39+ existente) + case no switch de `_runMigrations`
3. DDL = `CREATE TABLE IF NOT EXISTS publicacoes_tecnicas (...)` **idêntico** ao bloco de referência em `publicacao_table.dart` (colunas, tipos, defaults de `sync_status` / `deleted_at` / `user_id` conforme o DDL canônico do módulo)
4. Idempotente: `IF NOT EXISTS` + safe se já criada manualmente

### B) Alinhar documentação

- Atualizar comentário em `publicacao_table.dart`: migração real = **v41** (não v12)
- Se AGENTS.md / skill citarem schema, atualizar para **v41** apenas se o bump for feito neste PR

### C) Verificação pós-migração

- Garantir que `PublicacaoRepositoryImpl.save` / `softDelete` funcionam após:
  - install limpo (0 → 41)
  - upgrade 40 → 41
- `clearUserLocalData` continua deletando por `user_id` na tabela (já referencia o nome)

### D) Fora de escopo deste prompt

- Sync remoto de publicações / registro no `SyncOrchestrator`
- Soft-delete drawing / pull local-wins (outros prompts)
- Normalização global de `sync_status`

---

## 4️⃣ PROIBIDO

- ❌ Dropar/recriar tabelas de produção com perda de dados
- ❌ Hard delete de dados sincronizáveis de domínio
- ❌ Alterar UI, rotas, tema, FAB
- ❌ Inventar colunas não presentes no DDL de referência / ADR-009
- ❌ `git add .` / `git add -A`
- ❌ Dados fictícios em seeds

---

## 5️⃣ TESTES OBRIGATÓRIOS

Se houver harness de migração no repo, adicionar:

1. DB vazio → após migrations até v41 → `publicacoes_tecnicas` existe  
2. Insert mínimo via mapa alinhado a `PublicacaoTable` não lança  
3. Upgrade simulado 40→41 é idempotente (rodar migrate duas vezes / IF NOT EXISTS)

Se não houver harness, criar teste mínimo focado na DDL string / execução in-memory sqflite_ffi **somente** se o projeto já usar esse padrão; senão documentar validação manual no PR e cobrir com teste de repositório que abre DB de teste.

---

## 6️⃣ VALIDAÇÃO

```bash
flutter analyze lib/core/database/ lib/modules/consultoria/publicacoes/
./tool/arch_check.sh   # Exit 0
flutter test   # testes tocados
```

Confirmar `version:` no `DatabaseHelper` = **41** após o fix.

---

## 7️⃣ CRITÉRIO DE ACEITE

- [ ] `CREATE TABLE IF NOT EXISTS publicacoes_tecnicas` executa em onCreate e onUpgrade
- [ ] Comentário DDL aponta para a migração correta (v41)
- [ ] Schema version bumpada e case no orquestrador de migrations
- [ ] Install limpo: insert de publicação não crasha por table missing
- [ ] `arch_check.sh` Exit 0
- [ ] Diff limitado a database (+ publicacao_table comment) + testes

---

## 8️⃣ ENTREGA

Commit sugerido:

`fix(core): cria publicacoes_tecnicas na migração SQLite v41`

PR referencia `AUDITORIA_OFFLINE_FIRST_RELATORIO.md` Dimensão 9 e ADR-009.
