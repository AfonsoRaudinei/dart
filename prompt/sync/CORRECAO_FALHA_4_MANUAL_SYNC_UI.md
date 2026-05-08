# CORREÇÃO FALHA 4: EXPOR manualSyncProvider NA UI

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em UI/UX e Estado Riverpod  
**Objetivo:** Adicionar botão de sync manual no SideMenu para permitir usuário forçar sincronização  
**Arquivo Alvo:** `lib/features/map/presentation/widgets/side_menu.dart` (ou equivalente)  
**Prioridade:** BAIXA — melhoria de UX, não resolve sintoma principal

---

## 0️⃣ PASSO 0 — AUDITORIA PRÉ-EXECUÇÃO (OBRIGATÓRIO)

Execute **ANTES** de qualquer alteração:

```bash
# 1. Localizar SideMenu ou equivalente
find lib/features/map/ -name "*side_menu*" -o -name "*drawer*" -type f

# 2. Verificar se manualSyncProvider já é usado em algum lugar
grep -rn "manualSyncProvider" lib/ --include="*.dart"

# 3. Verificar estrutura do SideMenu
find lib/features/map/ -name "*side_menu*" -exec cat {} \; | head -100

# 4. Verificar se há ícone de sync disponível
grep -rn "Icons.sync\|sync_outlined" lib/ --include="*.dart" | head -5
```

**SE manualSyncProvider JÁ ESTIVER SENDO USADO NA UI → REPORTAR E NÃO PROSSEGUIR.**

---

## 1️⃣ ESCOPO

**Módulo:** `features/map/presentation/widgets/`  
**Rota permitida:** N/A (widget, não rota)

**🚫 Proibido alterar:**
- Lógica de sync existente (apenas consumir provider)
- Outros widgets além do SideMenu
- Navegação ou rotas
- Tema ou design system
- Providers compartilhados

**✅ Permitido:**
- Adicionar 1 item no menu
- Consumir `manualSyncProvider` via `ref.read`
- Adicionar loading indicator durante sync

---

## 2️⃣ OBJETIVO

Adicionar item "Sincronizar agora" no SideMenu (ou equivalente) que consome `manualSyncProvider`, permitindo o usuário forçar sync manualmente sem esperar o timer de 5 minutos.

---

## 3️⃣ REGRAS ABSOLUTAS

❌ Não alterar lógica de `SyncService` ou `SyncOrchestrator`  
❌ Não criar novo provider (usar `manualSyncProvider` existente)  
❌ Não adicionar animações ou transições complexas  
❌ Não alterar outros itens do menu  
✅ Apenas adicionar 1 novo `ListTile` ou equivalente  
✅ Mostrar loading indicator durante sync  
✅ Desabilitar botão se sync já estiver em andamento

---

## 4️⃣ PLANEJAMENTO

### 📂 Arquivos tocados
- `lib/features/map/presentation/widgets/side_menu.dart` (ou equivalente)

### 📥 Dado que entra
- `manualSyncProvider` (AsyncValue<void>)

### 📤 Dado que sai
- Trigger de sync manual

### 🗃 Persistência
- Nenhuma — apenas dispara sync existente

### ⚙ Evento que grava
- N/A — sync em background

---

## 5️⃣ CONTRATO DE DADOS

**Entidade envolvida:** Nenhuma  
**Campos obrigatórios:** N/A  
**Campos opcionais:** N/A  
**Validações:** N/A  
**Fonte da verdade:** N/A  
**Impacto retrocompatível:** ✅ Zero impacto — apenas UI

---

## 6️⃣ ESTADO

**Tipo:** Efêmero (AsyncValue do provider)  
**AutoDispose envolvido?** Sim (manualSyncProvider é autoDispose)  
**Pode perder estado?** Sim (estado de loading desaparece após sync)  
**Afeta fluxo Map-First?** Não

---

## 7️⃣ PERFORMANCE

**Widget rebuilda?** Sim (apenas o botão, quando `manualSyncProvider` muda)  
**Provider novo?** Não (usa existente)  
**Algum loop pesado?** Não  
**Algum cálculo síncrono em build?** Não  
**Pode impactar mapa?** Não

---

## 8️⃣ TESTABILIDADE

**Cenário feliz:**
- Usuário clica em "Sincronizar agora" → loading aparece → sync completa → loading desaparece

**Cenário erro:**
- Sync falha (sem internet) → snackbar de erro aparece

**Edge case:**
- Usuário clica múltiplas vezes → botão desabilitado durante sync

**Impacta testes existentes?** Não  
**Precisa criar teste novo?** Opcional (widget test verificando que botão aparece)

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
- Apenas adiciona UI
- Não altera lógica de sync
- Provider já existe e é testado
- Se sync falhar, já há tratamento de erro no provider

---

## 1️⃣1️⃣ EXECUÇÃO

### Localização esperada (confirmar com PASSO 0):

**Arquivo:** `lib/features/map/presentation/widgets/side_menu.dart`

### Alteração mínima:

**Adicionar item no menu (exemplo):**

```dart
// Após outros ListTiles (ex: Relatórios, Carteira, etc)

Consumer(
  builder: (context, ref, _) {
    final syncState = ref.watch(manualSyncProvider);
    
    return ListTile(
      leading: syncState.isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      title: const Text('Sincronizar agora'),
      enabled: !syncState.isLoading,
      onTap: syncState.isLoading
          ? null
          : () {
              ref.read(manualSyncProvider.notifier).triggerSync();
              
              // Opcional: fechar drawer após disparar sync
              Navigator.of(context).pop();
              
              // Opcional: mostrar snackbar de confirmação
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronização iniciada'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
    );
  },
),
```

**Importação necessária (adicionar se não existir):**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte/app/sync/providers/manual_sync_provider.dart'; // ajustar path se necessário
```

---

## 1️⃣2️⃣ VALIDAÇÃO FINAL

- [ ] Dashboard alterado? **NÃO**
- [ ] Outros módulos alterados? **NÃO**
- [ ] Navegação mudou? **NÃO**
- [ ] Tema mudou? **NÃO**
- [ ] Contrato alterado? **NÃO**
- [ ] Apenas `side_menu.dart` foi afetado? **SIM**

**Se qualquer resposta ≠ esperado → rollback.**

---

## 1️⃣3️⃣ ENCERRAMENTO PADRÃO

**Resultado final:**

O SideMenu foi ajustado para incluir botão "Sincronizar agora".  
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.

**Comando de teste manual:**
1. Abrir SideMenu
2. Clicar em "Sincronizar agora"
3. Verificar loading indicator aparece
4. Verificar dados sincronizam (logs no console)

---

## APROVAÇÃO NECESSÁRIA

**Este prompt aguarda confirmação explícita antes de executar.**

**Perguntas antes de prosseguir:**
1. O SideMenu está em `side_menu.dart` ou outro arquivo?
2. Há algum padrão de UI específico para itens de menu (ex: usar `Card` ao invés de `ListTile`)?
3. O snackbar de confirmação é desejado ou apenas o loading indicator?

Após aprovação:
- Executar `flutter analyze`
- Executar `arch_check.sh` (deve continuar Exit 0)
- Testar em device real
- Commitar: `git commit -m "feat(sync): add manual sync button in side menu [FALHA-4]"`
