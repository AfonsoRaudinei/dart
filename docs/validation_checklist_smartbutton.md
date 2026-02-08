# Checklist de Validação — SmartButton/SideMenu

**Data:** 2026-02-08  
**Versão:** 1.0 (Correção Definitiva)

---

## 📋 Tabela Verdade — Comportamento Esperado

| Rota | Nível | SmartButton | Ação ao Clicar | SideMenu |
|------|-------|-------------|----------------|----------|
| `/dashboard` | L0 | ☰ | Abrir SideMenu | ✅ SIM |
| `/dashboard/mapa-tecnico` | L0 | ☰ | Abrir SideMenu | ✅ SIM |
| `/consultoria/clientes` | L1 | ← | `go('/dashboard')` | ❌ NÃO |
| `/consultoria/clientes/:id` | L2+ | ← | `pop()` → volta para lista | ❌ NÃO |
| `/consultoria/clientes/:id/fazendas/:fid` | L2+ | ← | `pop()` → volta para cliente | ❌ NÃO |
| `/consultoria/relatorios` | L1 | ← | `go('/dashboard')` | ❌ NÃO |
| `/settings` | L1 | ← | `go('/dashboard')` | ❌ NÃO |
| `/agenda` | L1 | ← | `go('/dashboard')` | ❌ NÃO |
| `/feedback` | L1 | ← | `go('/dashboard')` | ❌ NÃO |
| `/public-map` | PUBLIC | CTA | "Acessar SoloForte" → `/login` | ❌ NÃO |
| `/login` | PUBLIC | CTA | "Acessar SoloForte" → `/login` | ❌ NÃO |

---

## ✅ Checklist de Validação

### 1. SmartButton — Comportamento por Nível

| Teste | Status | Evidência |
|-------|--------|-----------|
| `/dashboard` → ícone ☰ | ⬜ PENDENTE | Executar app e verificar visualmente |
| ☰ abre SideMenu | ⬜ PENDENTE | Clicar no botão e verificar drawer |
| `/consultoria/clientes` → ícone ← | ⬜ PENDENTE | Navegar para tela e verificar |
| ← vai para `/dashboard` | ⬜ PENDENTE | Clicar e verificar navegação |
| `/consultoria/clientes/:id` → ← volta para lista | ⬜ PENDENTE | Verificar pop() funciona |
| `/settings` → ← vai para mapa | ⬜ PENDENTE | |
| `/public-map` → CTA "Acessar SoloForte" | ⬜ PENDENTE | |

### 2. SideMenu — Isolamento ao Dashboard

| Teste | Status | Evidência |
|-------|--------|-----------|
| SideMenu abre em `/dashboard` | ⬜ PENDENTE | |
| SideMenu **NÃO** abre em `/settings` | ⬜ PENDENTE | Tentar swipe/apertar botão |
| SideMenu **NÃO** abre em `/consultoria/clientes` | ⬜ PENDENTE | |
| Swipe desabilitado fora do mapa | ⬜ PENDENTE | |

### 3. Ausência de Overlap

| Teste | Status | Evidência |
|-------|--------|-----------|
| Único FAB visível em `/dashboard` | ⬜ PENDENTE | |
| Único FAB visível em `/consultoria/clientes` | ⬜ PENDENTE | |
| Nenhum FAB local competindo | ⬜ PENDENTE | |

### 4. Mapa Público

| Teste | Status | Evidência |
|-------|--------|-----------|
| SmartButton **NÃO** aparece (apenas CTA) | ⬜ PENDENTE | |
| CTA navega para `/login` | ⬜ PENDENTE | |

---

## 🔬 Testes Automatizados

| Arquivo | Resultado |
|---------|-----------|
| `test/ui/components/side_menu_test.dart` | ✅ 28/28 PASSED |

---

## 📝 Arquivos Modificados

| Arquivo | Tipo |
|---------|------|
| `lib/core/router/app_routes.dart` | MODIFICADO — Adicionado enum `RouteLevel` e métodos `getLevel()`, `canOpenSideMenu()` |
| `lib/ui/components/smart_button.dart` | REESCRITO — Lógica determinística com switch/case por nível |
| `lib/ui/components/app_shell.dart` | REESCRITO — SideMenu trancado ao L0 via `canOpenSideMenu()` |
| `lib/ui/components/side_menu.dart` | SIMPLIFICADO — Removido botão voltar (não pertence ao menu) |
| `test/ui/components/side_menu_test.dart` | REESCRITO — Testes para `AppRoutes.getLevel()` |

---

## 🚫 Arquivos NÃO Modificados

- ❌ Rotas (nenhuma nova rota criada)
- ❌ Theme/Design System
- ❌ Dashboard/Mapa
- ❌ Outros módulos (Clientes, Relatórios, etc.)
- ❌ Persistência/Estado

---

## 📌 Instruções para Validação Manual

1. **Executar o app** no emulador ou dispositivo físico
2. **Login** com credenciais de demo
3. **Verificar cada cenário** da tabela acima
4. **Marcar como ✅** após confirmação visual
5. **Anotar prints/evidências** se necessário

---

## 🏁 Resultado Final

> ⬜ AGUARDANDO VALIDAÇÃO MANUAL

Após validação, preencher:

| Questão | Resposta |
|---------|----------|
| SmartButton no mapa é ☰? | |
| SmartButton fora do mapa é ←? | |
| SideMenu abre fora do mapa? | |
| SmartButton aparece no mapa público? | |
| Existe overlap com outro botão? | |
| Dashboard alterado? | |
| Outros módulos alterados? | |
| Navegação/tema mudaram? | |
| Apenas SmartButton/AppShell/SideMenu foi afetado? | |
