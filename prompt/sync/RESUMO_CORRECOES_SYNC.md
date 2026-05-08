# RESUMO: 4 CORREÇÕES DE SYNC — ORDEM DE EXECUÇÃO

---

## 📊 VISÃO GERAL

| Falha | Prioridade | Impacto | Risco | Arquivos | Tempo Estimado |
|-------|-----------|---------|-------|----------|----------------|
| **FALHA 1** | CRÍTICA | Resolve sintoma principal | Baixo | 1 arquivo | 5 min |
| **FALHA 2** | ALTA | Resolve push silencioso | Médio | 1-2 arquivos | 15 min |
| **FALHA 3** | MÉDIA | Torna falha observável | Baixo | 5 arquivos | 10 min |
| **FALHA 4** | BAIXA | Melhoria de UX | Baixo | 1 arquivo | 10 min |

---

## 🎯 ORDEM DE EXECUÇÃO RECOMENDADA

### **1️⃣ FALHA 1 — SYNC NO BOOT (CRÍTICA)**
**Objetivo:** Disparar sync imediatamente ao abrir Device B  
**Arquivo:** `lib/main.dart` ou widget raiz  
**Mudança:** Adicionar `orchestrator.triggerSync(SyncPriority.immediate)` após `registerSyncModules`

**Por que primeiro:**
- Resolve o sintoma principal ("dados não aparecem no Device B")
- Baixíssimo risco (apenas 1 linha de código)
- Pode validar se outras falhas são bloqueadoras antes de corrigi-las

**Validação:**
- Abrir Device B → dados aparecem em 2-5 segundos (sem esperar 5 min)

**Prompt:** `CORRECAO_FALHA_1_SYNC_BOOT.md`

---

### **2️⃣ FALHA 2 — TIPO DE sync_status (ALTA)**
**Objetivo:** Padronizar `sync_status` para String em todos os módulos  
**Arquivos:** Sync services + possivelmente migration v32  
**Mudança:** Converter `int` → `String` e criar migration de reparo

**Por que segundo:**
- Sem essa correção, push continua não encontrando registros "sujos"
- FALHA 1 pode mascarar esse problema temporariamente (pull funciona, push não)
- Necessita teste em device real antes de merge

**Validação:**
- Criar registro no Device A → verificar `sync_status = 'pending'` no SQLite
- Aguardar sync → verificar `sync_status = 'synced'`

**Prompt:** `CORRECAO_FALHA_2_SYNC_STATUS_TYPE.md`

---

### **3️⃣ FALHA 3 — LOG NO GUARD (MÉDIA)**
**Objetivo:** Adicionar log quando `userId == null` pula registros  
**Arquivos:** 5 sync services  
**Mudança:** Adicionar `AppLogger.warning` antes de `continue`

**Por que terceiro:**
- Não resolve o problema, apenas torna observável
- Útil para debug futuro
- Zero risco (apenas adiciona log)

**Validação:**
- Forçar `userId == null` → verificar log no console

**Prompt:** `CORRECAO_FALHA_3_USERID_LOG.md`

---

### **4️⃣ FALHA 4 — BOTÃO DE SYNC MANUAL (BAIXA)**
**Objetivo:** Adicionar item "Sincronizar agora" no SideMenu  
**Arquivos:** `side_menu.dart`  
**Mudança:** Adicionar `ListTile` que consome `manualSyncProvider`

**Por que último:**
- Melhoria de UX, não bugfix
- Opcional (usuário pode esperar timer automático)
- Pode ser adiada para próximo sprint

**Validação:**
- Abrir SideMenu → clicar em "Sincronizar agora" → dados sincronizam

**Prompt:** `CORRECAO_FALHA_4_MANUAL_SYNC_UI.md`

---

## 🚦 GATE DE APROVAÇÃO

**Após cada correção:**
1. ✅ `flutter analyze` (0 novos erros)
2. ✅ `arch_check.sh` (Exit 0)
3. ✅ Teste manual em device real
4. ✅ Commit isolado (1 falha = 1 commit)

**Antes de merge final:**
- ✅ Teste em 2 devices diferentes (A cria dados, B recebe)
- ✅ Teste com/sem internet
- ✅ Teste com token expirado
- ✅ Validar que testes automatizados continuam verdes (645/645)

---

## 📝 NOTAS IMPORTANTES

### **Dependências entre correções:**
- FALHA 1 é **independente** (pode ser executada sozinha)
- FALHA 2 **depende de FALHA 1** (para validar que push funciona após sync inicial)
- FALHA 3 é **independente** (apenas adiciona log)
- FALHA 4 é **independente** (apenas UI)

### **Rollback:**
- Cada correção é 1 commit isolado
- Se algo falhar → `git revert <commit_hash>`
- Não acumular múltiplas correções em 1 commit

### **Teste de integração recomendado:**
Após executar as 4 correções:
1. Device A: criar 5 registros (cliente, fazenda, talhão, visita, ocorrência)
2. Device B: abrir app (deve aparecer tudo em até 5 segundos)
3. Device B: criar 3 novos registros
4. Device A: abrir app (deve receber os 3 registros)
5. Ambos: fazer logout → login → dados devem persistir

---

## 🎯 RESULTADO ESPERADO

Após as 4 correções:
- ✅ Device B sincroniza imediatamente ao abrir (FALHA 1)
- ✅ Push encontra registros "sujos" corretamente (FALHA 2)
- ✅ Logs indicam quando `userId == null` (FALHA 3)
- ✅ Usuário pode forçar sync manualmente (FALHA 4)

**Comportamento final:**
> "Ao trocar de dispositivo, o usuário vê seus dados imediatamente (em 2-5 segundos), sem esperar 5 minutos ou realizar ação manual."

---

## 📦 ARQUIVOS GERADOS

- `CORRECAO_FALHA_1_SYNC_BOOT.md` ← **EXECUTAR PRIMEIRO**
- `CORRECAO_FALHA_2_SYNC_STATUS_TYPE.md` ← EXECUTAR SEGUNDO
- `CORRECAO_FALHA_3_USERID_LOG.md` ← EXECUTAR TERCEIRO
- `CORRECAO_FALHA_4_MANUAL_SYNC_UI.md` ← EXECUTAR QUARTO (opcional)
- `RESUMO_CORRECOES_SYNC.md` ← Este arquivo

---

**Todos os prompts seguem o SKILL OFICIAL (estrutura 0-13 obrigatória).**  
**Nenhum código será executado sem aprovação explícita.**
