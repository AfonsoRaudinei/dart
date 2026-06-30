# PROMPT 05 — Auditoria de Migration: `marketing_cases_cache` vs SQLite v30

**Especialização do agente:** Engenheiro Sênior Flutter/Dart — Persistência SQLite + Migrations Idempotentes  
**Tipo:** AUDITORIA + CORREÇÃO CIRÚRGICA (se necessário)  
**Módulo:** `marketing/` + `core/` (database migrations)  
**Rota afetada:** Nenhuma

---

## CONTEXTO

A vistoria confirmou que a tabela `marketing_cases_cache` existe e é usada pelo `MarketingCaseRepositoryImpl`. Porém, **não foi confirmado em qual versão do SQLite a migration foi criada**. O banco está em **v30**. Se a migration do `marketing_cases_cache` não for idempotente (padrão `DROP + CREATE` do projeto), pode haver inconsistência em upgrades de schema.

**Padrão obrigatório do projeto:** Migrations usam `DROP TABLE IF EXISTS + CREATE TABLE` — nunca `ALTER TABLE`.

---

## PASSO 0 — LOCALIZAÇÃO OBRIGATÓRIA

```bash
# Arquivo central de migrations do banco principal
find lib/ -name "database_helper.dart" -o -name "soloforte_database.dart" -o -name "app_database.dart" | sort
find lib/ -name "*migration*" | sort

# Migration específica do marketing
grep -rn "marketing_cases_cache\|marketing_cases" lib/ | sort

# Versão atual do schema
grep -rn "version.*30\|version.*29\|schemaVersion\|_dbVersion" lib/ | sort
```

Reporte todos os outputs antes de qualquer ação.

---

## PASSO 1 — LEITURA DO SISTEMA DE MIGRATIONS

### 1.1 Estrutura do sistema de migrations
- Como as migrations são organizadas? (switch/case por versão? lista de migrations? arquivo por versão?)
- Qual é a versão atual declarada no código?
- O padrão `DROP + CREATE` está sendo seguido em todas as migrations?

### 1.2 Migration do `marketing_cases_cache`
- Em qual versão foi adicionada? (v??)
- O `CREATE TABLE marketing_cases_cache` tem o padrão idempotente?
- Os campos batem com o `toMap()` / `fromMap()` da entidade `MarketingCase`?

Verificar campos esperados:
```
id, tipo, visibilidade, lat, lng, localizacao_texto, produtor_fazenda,
produto_utilizado, criado_em, atualizado_em, sync_status, user_id,
produtividade_valor, produtividade_unidade, nome_vendedor, telefone_vendedor,
descricao, foto_principal_url, quantidade_produzida, foto_antes_url,
foto_depois_url, ganho_produtividade, economia_gerada, nome_talhao,
tamanho_ha, conclusao, deletado_em, avaliacoes (JSON), roi (JSON)
```

Se algum campo existir na entidade mas não na tabela → **PARAR e reportar divergência.**

### 1.3 Campo `user_id`
- `marketing_cases_cache` tem coluna `user_id`? (obrigatório após fix de isolamento de usuário, Abr/2026)
- Se não tiver → registrar como **DT crítica** e propor migration de correção

---

## PASSO 2 — DIAGNÓSTICO

Produzir relatório:

```
Marketing migration status:
├── Versão SQLite declarada no código: vXX
├── Versão real do banco (v30): BATE / NÃO BATE
├── marketing_cases_cache criada em: vXX
├── Migration é idempotente (DROP+CREATE)?: SIM / NÃO
├── Campo user_id presente?: SIM / NÃO
├── Divergência de campos entidade vs tabela: NENHUMA / LISTA
└── Ação necessária: NENHUMA / MIGRATION v31
```

---

## PASSO 3 — CORREÇÃO (somente se necessário)

Se houver divergência (campo faltando, `user_id` ausente, migration não idempotente):

**Criar migration v31:**
```dart
// Padrão obrigatório — DROP + CREATE
case 31:
  await db.execute('DROP TABLE IF EXISTS marketing_cases_cache');
  await db.execute('''
    CREATE TABLE marketing_cases_cache (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT '',
      // ... todos os campos corretos
    )
  ''');
```

**Regras da migration:**
- Incrementar `_dbVersion` de 30 para 31
- Usar `DROP + CREATE` — nunca `ALTER TABLE`
- Incluir `user_id NOT NULL DEFAULT ''`
- Testar com banco já em v30 (upgrade) e banco novo (fresh install)

**Gate:** `flutter analyze lib/` → 0 novos erros após migration.

---

## PASSO 4 — RESTRIÇÕES ABSOLUTAS

❌ Não usar `ALTER TABLE`  
❌ Não alterar `MarketingCase` entidade  
❌ Não alterar `MarketingCaseRepositoryImpl` além do necessário para nova migration  
❌ Não criar nova tabela — apenas corrigir a existente  
❌ Não alterar versão sem criar migration completa  

---

## PASSO 5 — VALIDAÇÃO FINAL

```bash
flutter analyze lib/
bash tool/arch_check.sh
```

Se migration foi necessária:
- Testar upgrade (banco v30 → v31): tabela recriada corretamente
- Testar fresh install: tabela criada corretamente
- `user_id` presente e populado corretamente

**Responder:**

| Verificação | Resultado |
|---|---|
| migration_cases_cache idempotente? | SIM/NÃO→CORRIGIDO |
| user_id presente na tabela? | SIM/NÃO→CORRIGIDO |
| Versão SQLite atualizada? | v30/v31 |
| Entidade vs tabela em sincronia? | SIM |
| arch_check.sh Exit 0? | SIM |

---

## ENCERRAMENTO

Migration `marketing_cases_cache` auditada e corrigida se necessário.  
Schema SQLite em sincronia com a entidade `MarketingCase`.
