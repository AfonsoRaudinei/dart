# CHECKLIST DE VALIDAÇÃO VISUAL - SMARTBUTTON
**STATUS: OBRIGATÓRIO**
**DATA:** 04/02/2026

Este documento comprova a conformidade visual da regra de navegação.

## 1. Regra de Ouro (Visual)

| Nível | Contexto | Ícone Esperado | Ação do Botão | Cor |
|---|---|---|---|---|
| **L0** | Mapa Técnico (`/dashboard/mapa-tecnico`) | ☰ (Menu) | Abre SideMenu (Drawer) | Verde |
| **L1** | Módulos (Ex: `/consultoria/clientes`) | ← (Voltar) | `go(AppRoutes.mapRoot)` | Verde |
| **L2+** | Sub-Telas (Ex: Detalhe Cliente) | ← (Voltar) | `pop()` | Verde |

## 2. Checklist de Rotas Reais

O desenvolvedor deve validar visualmente cada rota abaixo:

| Rota (URI) | Ícone Renderizado | Ação Executada | Status |
|---|---|---|---|
| `/dashboard/mapa-tecnico` | ☰ | Abriu SideMenu | ✅ VALIDADO |
| `/consultoria/clientes` | ← | Foi p/ Mapa | ✅ VALIDADO |
| `/consultoria/relatorios` | ← | Foi p/ Mapa | ✅ VALIDADO |
| `/settings` | ← | Foi p/ Mapa | ✅ VALIDADO |
| `/consultoria/clientes/:id` | ← | Voltou p/ Lista | ✅ VALIDADO |
| `/consultoria/clientes/:id/fazendas/:farmId` | ← | Voltou p/ Cliente | ✅ VALIDADO |

## 3. Comportamento de Fallback (L2+)

Se o usuário recarregar a página (F5) em uma rota profunda (L2+):
1. O SmartButton deve persistir como ← (Voltar).
2. Ao clicar, se `canPop() == false`, deve executar `go(AppRoutes.mapRoot)`.

**Status Fallback:** ✅ VALIDADO NA LÓGICA DE CÓDIGO
