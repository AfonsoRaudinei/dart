# CORREÇÃO FALHA 1: SYNC IMEDIATO NO BOOT DO DEVICE B

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em Inicialização e Lifecycle  
**Objetivo:** Disparar sync imediatamente após registro dos módulos no boot do app  
**Arquivo Alvo:** `lib/main.dart` ou widget raiz onde `registerSyncModules` é chamado  
**Prioridade:** CRÍTICA — resolve sintoma principal ("Device B não mostra dados ao abrir")

---

## 0️⃣ PASSO 0 — AUDITORIA PRÉ-EXECUÇÃO (OBRIGATÓRIO)

Execute **ANTES** de qualquer alteração:

```bash
# 1. Localizar onde registerSyncModules é chamado
grep -rn "registerSyncModules" lib/ --include="*.dart" -B 5 -A 10

# 2. Verificar se já existe algum triggerSync no boot
grep -rn "triggerSync\|manualSync" lib/main.dart lib/app.dart --include="*.dart"

# 3. Verificar SyncOrchestrator API
find lib/app/sync/ -name "*orchestrator*" -exec grep -H "triggerSync" {} \; -A 5
```

**SE ENCONTRAR triggerSync JÁ EXISTENTE NO BOOT → REPORTAR E NÃO PROSSEGUIR.**

---

## 1️⃣ ESCOPO

**Módulo:** `app/sync/`  
**Rota permitida:** N/A (lógica de inicialização, não roteamento)

**🚫 Proibido alterar:**
- Lógica interna de `SyncService` ou `SyncOrchestrator`
- Timers periódicos existentes (5 min / 15 min)
- Lógica de conectividade (`connectivityStateProvider`)
- Qualquer outro módulo além de `main.dart` ou widget raiz

**✅ Permitido:**
- Adicionar **1 linha** de código após `registerSyncModules`
- Usar `addPostFrameCallback` para garantir que o sync ocorre após build completo

---

## 2️⃣ OBJETIVO

Adicionar chamada de `triggerSync(SyncPriority.immediate)` logo após `registerSyncModules(orchestrator)` no boot do app, garantindo que o Device B sincronize imediatamente ao abrir, sem esperar timer ou mudança de conectividade.

---

## 3️⃣ REGRAS ABSOLUTAS

❌ Não alterar lógica de `SyncService` ou `SyncOrchestrator`  
❌ Não remover ou modificar timers existentes  
❌ Não adicionar UI ou feedback visual (fora do escopo)  
❌ Não criar novos providers ou observers  
✅ Apenas adicionar 1 linha de código no lugar correto  
✅ Usar `SchedulerBinding.instance.addPostFrameCallback` se necessário  
✅ Manter compatibilidade total com fluxo existente

---

## 4️⃣ PLANEJAMENTO

### 📂 Arquivos tocados
- `lib/main.dart` (ou `lib/app.dart` se for onde `registerSyncModules` está)

### 📥 Dado que entra
- Nenhum dado externo — apenas chamada de método no lifecycle do app

### 📤 Dado que sai
- Trigger de sync imediato com prioridade `SyncPriority.immediate`

### 🗃 Persistência
- Nenhuma — apenas dispara lógica existente

### ⚙ Evento que grava
- N/A — não há gravação, apenas leitura (pull de Supabase)

---

## 5️⃣ CONTRATO DE DADOS

**Entidade envolvida:** Nenhuma  
**Campos obrigatórios:** N/A  
**Campos opcionais:** N/A  
**Validações:** N/A  
**Fonte da verdade:** Supabase (dados remotos)  
**Impacto retrocompatível:** ✅ Zero impacto — apenas adiciona trigger

---

## 6️⃣ ESTADO

**Tipo:** Efêmero (trigger único no boot)  
**AutoDispose envolvido?** Não  
**Pode perder estado?** Não (é um trigger, não um estado)  
**Afeta fluxo Map-First?** Não

---

## 7️⃣ PERFORMANCE

**Widget rebuilda?** Não  
**Provider novo?** Não  
**Algum loop pesado?** Não  
**Algum cálculo síncrono em build?** Não  
**Pode impactar mapa?** Não (sync ocorre em background)

---

## 8️⃣ TESTABILIDADE

**Cenário feliz:**
- Device B abre o app → sync dispara imediatamente → dados aparecem em até 2 segundos

**Cenário erro:**
- Device B abre sem internet → sync falha normalmente (retry já implementado)

**Edge case:**
- Device B abre com token expirado → FALHA 3 (guard `userId == null`) ainda pula registros, mas ao menos o ciclo é disparado

**Impacta testes existentes?** Não — nenhum teste verifica timing de sync no boot  
**Precisa criar teste novo?** Opcional (pode adicionar teste de integração verificando que `triggerSync` é chamado no boot)

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
- Apenas adiciona 1 linha de código
- Não altera lógica existente
- Não cria novos providers
- Sync já é idempotente (pode rodar múltiplas vezes)
- Se falhar, o timer periódico de 5 min serve como fallback

---

## 1️⃣1️⃣ EXECUÇÃO

### Localização esperada (confirmar com PASSO 0):

```dart
// Provavelmente em main.dart ou app.dart, após runApp ou initState
void _initializeSync(SyncOrchestrator orchestrator) {
  registerSyncModules(orchestrator);
  
  // 🔹 ADICIONAR ESTA LINHA:
  SchedulerBinding.instance.addPostFrameCallback((_) {
    orchestrator.triggerSync(SyncPriority.immediate);
  });
}
```

### Alteração mínima:

**ANTES:**
```dart
registerSyncModules(orchestrator);
```

**DEPOIS:**
```dart
registerSyncModules(orchestrator);
SchedulerBinding.instance.addPostFrameCallback((_) {
  orchestrator.triggerSync(SyncPriority.immediate);
});
```

**Justificativa do `addPostFrameCallback`:**
Garante que o sync só dispara após o build completo do widget tree, evitando conflitos com inicialização de providers.

---

## 1️⃣2️⃣ VALIDAÇÃO FINAL

- [ ] Dashboard alterado? **NÃO**
- [ ] Outros módulos alterados? **NÃO**
- [ ] Navegação mudou? **NÃO**
- [ ] Tema mudou? **NÃO**
- [ ] Contrato alterado? **NÃO**
- [ ] Apenas `main.dart` ou `app.dart` foi afetado? **SIM**

**Se qualquer resposta ≠ esperado → rollback.**

---

## 1️⃣3️⃣ ENCERRAMENTO PADRÃO

**Resultado final:**

O módulo `app/sync/` foi ajustado para disparar sync imediatamente no boot do app.  
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.

**Comando de teste manual:**
1. Abrir Device B em modo avião
2. Ativar conexão
3. Abrir o app
4. Verificar se dados aparecem em até 2 segundos (sem esperar 5 min)

---

## APROVAÇÃO NECESSÁRIA

**Este prompt aguarda confirmação explícita antes de executar.**

Após aprovação:
- Copiar este prompt para o VS Code (Copilot `Ctrl+Shift+I`) ou Antigravity
- Executar `flutter analyze` após alteração
- Executar `arch_check.sh` (deve continuar Exit 0)
- Commitar: `git add lib/main.dart && git commit -m "fix(sync): trigger immediate sync on boot [FALHA-1]"`
