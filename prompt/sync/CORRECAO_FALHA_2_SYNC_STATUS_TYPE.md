# CORREÇÃO FALHA 2: PADRONIZAÇÃO DE sync_status (TIPO INCONSISTENTE)

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em Schema SQLite e Migrations  
**Objetivo:** Padronizar tipo de `sync_status` em todos os módulos (String ou int, nunca misturado)  
**Arquivos Alvo:**  
- Sync services de `occurrence`, `visit`, `agenda`  
- Possivelmente migrations SQLite (se necessário criar v32)  
**Prioridade:** ALTA — push silenciosamente não encontra registros "sujos" devido a mismatch de tipo

---

## 0️⃣ PASSO 0 — AUDITORIA PRÉ-EXECUÇÃO (OBRIGATÓRIO)

Execute **ANTES** de qualquer alteração:

```bash
# 1. Mapear todos os sync services
find lib/consultoria/ -name "*sync_service.dart" -type f

# 2. Verificar tipo de sync_status em cada um
grep -rn "sync_status" lib/consultoria/*/data/sync/ --include="*.dart" -B 2 -A 2

# 3. Verificar schema SQLite (migrations)
find lib/core/database/migrations/ -name "*.sql" -exec grep -H "sync_status" {} \;

# 4. Verificar se há enum ou constantes definidas
grep -rn "enum.*Sync\|SyncStatus" lib/ --include="*.dart"
```

**SE O SCHEMA SQL JÁ DEFINE sync_status COMO TEXT OU INTEGER GLOBALMENTE → REPORTAR O TIPO ANTES DE PROSSEGUIR.**

---

## 1️⃣ ESCOPO

**Módulos afetados:**
- `consultoria/occurrences/data/sync/`
- `consultoria/visitas/data/sync/` (se houver `visit_sync_service.dart`)
- `consultoria/agenda/data/sync/`

**Rotas permitidas:** N/A (lógica de sincronização, não roteamento)

**🚫 Proibido alterar:**
- Lógica de push/pull (apenas tipo de dado)
- Contratos entre módulos
- Providers compartilhados
- Estrutura de pastas
- Outros módulos além dos listados acima

**✅ Permitido:**
- Alterar tipo de `sync_status` de `int` para `String` (ou vice-versa)
- Atualizar queries SQL (`WHERE sync_status = ?`)
- Criar migration de reparo (v32) se necessário

---

## 2️⃣ OBJETIVO

Padronizar o tipo de `sync_status` em todos os módulos de sync, eliminando o mismatch que causa `WHERE sync_status = ?` retornar 0 registros quando valor esperado é `'pending'` mas armazenado é `1`.

**Decisão de design:** Padronizar para `String` (`'pending'`, `'synced'`, `'failed'`) em todos os módulos, pois é mais legível e já usado em 2 de 3 módulos.

---

## 3️⃣ REGRAS ABSOLUTAS

❌ Não alterar lógica de push/pull além do tipo de dado  
❌ Não criar novos campos ou tabelas  
❌ Não refatorar código adjacente  
❌ Não alterar contratos de dados entre módulos  
✅ Apenas ajustar tipo de `sync_status` e queries relacionadas  
✅ Criar migration SQLite v32 se necessário (para converter registros existentes)  
✅ Manter retrocompatibilidade (migration deve ser idempotente)

---

## 4️⃣ PLANEJAMENTO

### 📂 Arquivos tocados
- `lib/consultoria/occurrences/data/sync/occurrence_sync_service.dart` (mudar `int` → `String`)
- Possivelmente `lib/core/database/migrations/v32_sync_status_repair.sql` (nova migration)

### 📥 Dado que entra
- Registros existentes no SQLite com `sync_status = 1` ou `sync_status = 0`

### 📤 Dado que sai
- Após migration: `sync_status = 'pending'` ou `sync_status = 'synced'`

### 🗃 Persistência
- SQLite local (campo `sync_status` nas tabelas afetadas)

### ⚙ Evento que grava
- Migration roda automaticamente ao abrir o app (se versão < 32)

---

## 5️⃣ CONTRATO DE DADOS

**Entidade envolvida:** Todas as tabelas com coluna `sync_status`  
**Campos obrigatórios:** `sync_status` (String, NOT NULL)  
**Campos opcionais:** N/A  
**Validações:** Valores permitidos: `'pending'`, `'synced'`, `'failed'`  
**Fonte da verdade:** SQLite local (não afeta Supabase)  
**Impacto retrocompatível:** ✅ Migration converte registros antigos automaticamente

---

## 6️⃣ ESTADO

**Tipo:** Persistente (SQLite)  
**AutoDispose envolvido?** Não  
**Pode perder estado?** Não (migration preserva dados)  
**Afeta fluxo Map-First?** Não

---

## 7️⃣ PERFORMANCE

**Widget rebuilda?** Não  
**Provider novo?** Não  
**Algum loop pesado?** Sim, na migration (UPDATE de todos os registros), mas roda 1x apenas  
**Algum cálculo síncrono em build?** Não  
**Pode impactar mapa?** Não

---

## 8️⃣ TESTABILIDADE

**Cenário feliz:**
- Registros com `sync_status = 1` são convertidos para `'pending'`
- Push encontra os registros corretamente com `WHERE sync_status = 'pending'`

**Cenário erro:**
- Usuário com app atualizado mas sem rodar migration → deve ser forçado a migrar (versão do DB é checada no boot)

**Edge case:**
- Registros criados entre v31 e v32 em devices diferentes → migration deve ser idempotente

**Impacta testes existentes?** Possivelmente (se houver testes verificando `sync_status = 1`)  
**Precisa criar teste novo?** Sim (teste de migration v32)

---

## 9️⃣ MAP-FIRST CHECK

**Move raiz funcional?** Não  
**Altera nível de navegação?** Não  
**Cria sub-rota fora do contrato?** Não  
**Quebra regra L0 do /map?** Não

---

## 🔟 RISCO

**Classificação:** Médio

**Motivo:**
- Migration SQL pode falhar se houver constraint inesperada
- Registros em devices não sincronizados podem ter `sync_status` misturado temporariamente
- Necessita teste em device real antes de merge

**Mitigação:**
- Migration deve usar `DROP + CREATE` (padrão idempotente atual)
- Testar em clone do DB antes de aplicar em produção

---

## 1️⃣1️⃣ EXECUÇÃO

### Passo 1: Atualizar sync service

**Arquivo:** `lib/consultoria/occurrences/data/sync/occurrence_sync_service.dart`

**ANTES:**
```dart
// Linha 58
'sync_status': 1, // int
```

**DEPOIS:**
```dart
'sync_status': 'pending', // String
```

**ANTES:**
```dart
// Linha que faz SELECT local
where: 'sync_status = ?',
whereArgs: [1],
```

**DEPOIS:**
```dart
where: 'sync_status = ?',
whereArgs: ['pending'],
```

---

### Passo 2: Criar migration v32 (SE NECESSÁRIO)

**Confirmar antes de criar:** O schema SQL atual define `sync_status` como `TEXT` ou `INTEGER`?

**Se for `INTEGER` → criar migration:**

```sql
-- lib/core/database/migrations/v32_sync_status_repair.sql

-- Converter valores numéricos para strings
UPDATE occurrences SET sync_status = 'pending' WHERE sync_status = '1';
UPDATE occurrences SET sync_status = 'synced' WHERE sync_status = '0';
UPDATE visit_sessions SET sync_status = 'pending' WHERE sync_status = '1';
UPDATE visit_sessions SET sync_status = 'synced' WHERE sync_status = '0';
UPDATE agenda_events SET sync_status = 'pending' WHERE sync_status = '1';
UPDATE agenda_events SET sync_status = 'synced' WHERE sync_status = '0';

-- Nota: Se a coluna for INTEGER, considerar recriar tabela com TEXT (padrão DROP+CREATE)
```

**Se for `TEXT` → não criar migration, apenas corrigir o código.**

---

## 1️⃣2️⃣ VALIDAÇÃO FINAL

- [ ] Dashboard alterado? **NÃO**
- [ ] Outros módulos alterados? **NÃO** (apenas sync services de 3 módulos)
- [ ] Navegação mudou? **NÃO**
- [ ] Tema mudou? **NÃO**
- [ ] Contrato alterado? **SIM** (tipo de `sync_status`, mas sem impacto cross-módulo)
- [ ] Apenas sync services foram afetados? **SIM**

**Se qualquer resposta ≠ esperado → rollback.**

---

## 1️⃣3️⃣ ENCERRAMENTO PADRÃO

**Resultado final:**

O tipo de `sync_status` foi padronizado para `String` em todos os módulos de sync.  
Nenhum outro módulo, rota, estado ou contrato cross-módulo do SoloForte foi alterado.

**Comando de teste manual:**
1. Criar ocorrência no Device A
2. Verificar SQLite: `SELECT sync_status FROM occurrences WHERE id = ?` → deve ser `'pending'`
3. Aguardar sync
4. Verificar novamente: deve ser `'synced'`

---

## APROVAÇÃO NECESSÁRIA

**Este prompt aguarda confirmação explícita antes de executar.**

**Perguntas antes de prosseguir:**
1. O schema SQL atual define `sync_status` como `TEXT` ou `INTEGER`?
2. Há registros existentes em produção que precisam ser convertidos?
3. Criar migration v32 ou apenas corrigir o código?

Após aprovação:
- Executar `flutter analyze`
- Executar `arch_check.sh` (deve continuar Exit 0)
- Testar migration em clone do DB
- Commitar: `git commit -m "fix(sync): standardize sync_status to String [FALHA-2]"`
