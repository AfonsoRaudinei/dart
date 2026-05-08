# CORREÇÃO FALHA 3: LOG NO GUARD userId == null

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em Observabilidade e Debug  
**Objetivo:** Adicionar log de warning quando `userId == null` pula registros no sync  
**Arquivos Alvo:** Todos os 5 sync services (clients, farms, fields, visit_sessions, occurrences)  
**Prioridade:** MÉDIA — torna falha observável sem alterar comportamento

---

## 0️⃣ PASSO 0 — AUDITORIA PRÉ-EXECUÇÃO (OBRIGATÓRIO)

Execute **ANTES** de qualquer alteração:

```bash
# 1. Mapear todos os sync services
find lib/consultoria/ -name "*sync_service.dart" -type f

# 2. Localizar todos os guards de userId
grep -rn "if.*userId.*null" lib/consultoria/*/data/sync/ --include="*.dart" -B 2 -A 2

# 3. Verificar se AppLogger está disponível
grep -rn "AppLogger\|import.*logger" lib/consultoria/*/data/sync/ --include="*.dart" | head -5

# 4. Verificar padrão de log atual
grep -rn "AppLogger.warning\|AppLogger.error" lib/consultoria/ --include="*.dart" | head -10
```

**SE JÁ EXISTIR LOG NO GUARD → REPORTAR E NÃO PROSSEGUIR.**

---

## 1️⃣ ESCOPO

**Módulos afetados:**
- `consultoria/clientes/data/sync/`
- `consultoria/fazendas/data/sync/`
- `consultoria/fields/data/sync/`
- `consultoria/visitas/data/sync/`
- `consultoria/occurrences/data/sync/`

**Rotas permitidas:** N/A (lógica de sincronização, não roteamento)

**🚫 Proibido alterar:**
- Lógica de push/pull (apenas adicionar log)
- Condição do guard `if (userId == null)`
- Comportamento após o guard (`continue` ou `return`)
- Outros módulos além dos listados acima

**✅ Permitido:**
- Adicionar 1 linha de `AppLogger.warning` antes de `continue` ou `return`
- Importar `AppLogger` se não estiver importado

---

## 2️⃣ OBJETIVO

Adicionar log de warning em todos os guards `if (userId == null)` nos sync services, tornando a falha observável via logs do app, sem alterar comportamento (registros continuam sendo pulados).

---

## 3️⃣ REGRAS ABSOLUTAS

❌ Não alterar lógica de sync além do log  
❌ Não remover ou modificar o guard existente  
❌ Não adicionar retry ou tentativa de recuperação  
❌ Não criar novos providers ou observers  
✅ Apenas adicionar 1 linha de log antes de `continue` ou `return`  
✅ Usar `AppLogger.warning` (padrão do projeto)  
✅ Manter compatibilidade total com fluxo existente

---

## 4️⃣ PLANEJAMENTO

### 📂 Arquivos tocados
- 5 arquivos `*_sync_service.dart` (um por módulo)

### 📥 Dado que entra
- `userId` (pode ser `null`)

### 📤 Dado que sai
- Log de warning no console/Sentry (se configurado)

### 🗃 Persistência
- Nenhuma — apenas log efêmero

### ⚙ Evento que grava
- N/A — não há gravação

---

## 5️⃣ CONTRATO DE DADOS

**Entidade envolvida:** Nenhuma  
**Campos obrigatórios:** N/A  
**Campos opcionais:** N/A  
**Validações:** N/A  
**Fonte da verdade:** N/A  
**Impacto retrocompatível:** ✅ Zero impacto — apenas adiciona log

---

## 6️⃣ ESTADO

**Tipo:** Efêmero (log)  
**AutoDispose envolvido?** Não  
**Pode perder estado?** Sim (log desaparece após fechar console)  
**Afeta fluxo Map-First?** Não

---

## 7️⃣ PERFORMANCE

**Widget rebuilda?** Não  
**Provider novo?** Não  
**Algum loop pesado?** Não  
**Algum cálculo síncrono em build?** Não  
**Pode impactar mapa?** Não

---

## 8️⃣ TESTABILIDADE

**Cenário feliz:**
- `userId` é válido → nenhum log gerado

**Cenário erro:**
- `userId` é `null` → log aparece: `"[SyncService] Skipping sync: userId is null"`

**Edge case:**
- Múltiplos ciclos com `userId == null` → múltiplos logs (não é problema)

**Impacta testes existentes?** Não (testes não verificam logs)  
**Precisa criar teste novo?** Opcional (teste pode verificar que log é gerado quando `userId == null`)

---

## 9️⃣ MAP-FIRST CHECK

**Move raiz funcional?** Não  
**Altera nível de navegação?** Não  
**Cria sub-rota fora do contrato?** Não  
**Quebra regra L0 do /map?** Não

---

## 🔟 RISCO

**Classificação:** Baixo

**Motivo:**
- Apenas adiciona log
- Não altera lógica existente
- Não cria novos estados ou providers
- Se `AppLogger` não existir, dart analyzer vai acusar (fácil de detectar)

---

## 1️⃣1️⃣ EXECUÇÃO

### Padrão de alteração (aplicar em todos os 5 sync services):

**ANTES:**
```dart
final userId = _supabase.auth.currentUser?.id;
if (userId == null) continue; // ou return;
```

**DEPOIS:**
```dart
final userId = _supabase.auth.currentUser?.id;
if (userId == null) {
  AppLogger.warning('[${runtimeType}] Skipping sync: userId is null');
  continue; // ou return;
}
```

**Importação necessária (adicionar se não existir):**
```dart
import 'package:soloforte/core/logging/app_logger.dart';
```

---

### Arquivos específicos a serem alterados:

1. `lib/consultoria/clientes/data/sync/client_sync_service.dart`
2. `lib/consultoria/fazendas/data/sync/farm_sync_service.dart`
3. `lib/consultoria/fields/data/sync/field_sync_service.dart`
4. `lib/consultoria/visitas/data/sync/visit_sync_service.dart`
5. `lib/consultoria/occurrences/data/sync/occurrence_sync_service.dart`

---

## 1️⃣2️⃣ VALIDAÇÃO FINAL

- [ ] Dashboard alterado? **NÃO**
- [ ] Outros módulos alterados? **NÃO** (apenas sync services de 5 módulos)
- [ ] Navegação mudou? **NÃO**
- [ ] Tema mudou? **NÃO**
- [ ] Contrato alterado? **NÃO**
- [ ] Apenas sync services foram afetados? **SIM**

**Se qualquer resposta ≠ esperado → rollback.**

---

## 1️⃣3️⃣ ENCERRAMENTO PADRÃO

**Resultado final:**

Os 5 sync services foram ajustados para logar warning quando `userId == null`.  
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.

**Comando de teste manual:**
1. Forçar logout no app
2. Abrir app sem fazer login
3. Aguardar ciclo de sync
4. Verificar console: deve aparecer `"[ClientSyncService] Skipping sync: userId is null"`

---

## APROVAÇÃO NECESSÁRIA

**Este prompt aguarda confirmação explícita antes de executar.**

Após aprovação:
- Executar `flutter analyze`
- Executar `arch_check.sh` (deve continuar Exit 0)
- Commitar: `git commit -m "feat(sync): add warning log when userId is null [FALHA-3]"`
