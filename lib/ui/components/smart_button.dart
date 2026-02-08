/*
════════════════════════════════════════════════════════════════════
SMART BUTTON — CONTRATO DE NAVEGAÇÃO (SOLOFORTE)
════════════════════════════════════════════════════════════════════

Este botão é um CONTROLE SISTÊMICO, não um botão de tela.

REGRA CANÔNICA:
- O Dashboard (/dashboard) é o centro absoluto do aplicativo.
- O botão NUNCA depende de stack, histórico ou Navigator.pop().
- O comportamento é 100% determinístico e baseado apenas na rota atual.

COMPORTAMENTO OBRIGATÓRIO:
1) Quando a rota atual for EXACTAMENTE /dashboard:
   - Ícone: ☰ (menu)
   - Ação: abrir o SideMenu global

2) Quando estiver em QUALQUER outra rota:
   - Ícone: ← (voltar)
   - Ação: navegar DIRETAMENTE para /dashboard (context.go)
   - NÃO usar pop, canPop, maybePop ou variações

PROIBIÇÕES ABSOLUTAS:
- ❌ Navigator.pop()
- ❌ context.pop()
- ❌ canPop()
- ❌ lógica baseada em stack ou níveis hierárquicos
- ❌ exceções por módulo

MOTIVAÇÃO TÉCNICA:
Apps map-centric exigem uma âncora de navegação estável.
O Dashboard é a raiz única. Tudo sai dele. Tudo volta para ele.

⚠️ Qualquer alteração neste comportamento exige revisão
da documentação de navegação do SoloForte.

Autor: Contrato arquitetural validado por engenheiro sênior Flutter/Dart
════════════════════════════════════════════════════════════════════
*/
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

class SmartButton extends ConsumerWidget {
  const SmartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access current route URI
    final RouteMatchList matchList = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration;
    final String uri = matchList.uri.path;

    // 0. PUBLIC MAP (CTA)
    // Contexto público: botão CTA para login
    if (uri == AppRoutes.publicMap || uri == '/') {
      return Container(
        margin: const EdgeInsets.only(bottom: 40, right: 20),
        child: FloatingActionButton.extended(
          onPressed: () => context.go(AppRoutes.login),
          backgroundColor: SoloForteColors.greenIOS,
          label: const Text(
            'Acessar SoloForte',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          icon: const Icon(Icons.login, color: Colors.white),
        ),
      );
    }

    // REGRA ÚNICA (fonte da verdade):
    // isDashboard = rota atual é exatamente /dashboard
    final bool isDashboard = uri == AppRoutes.dashboard;

    // 1. DASHBOARD (/dashboard)
    // Ícone: ☰ (menu)
    // Ação: abrir SideMenu
    if (isDashboard) {
      return Container(
        margin: const EdgeInsets.only(bottom: 40, right: 20),
        child: FloatingActionButton(
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
          backgroundColor: SoloForteColors.greenIOS,
          child: const Icon(Icons.menu, color: Colors.white),
        ),
      );
    }

    // 2. QUALQUER OUTRA ROTA AUTENTICADA
    // Ícone: ← (voltar)
    // Ação: navegar direto para /dashboard via go_router declarativo
    // Sem uso de pop() - navegação determinística
    return Container(
      margin: const EdgeInsets.only(bottom: 40, right: 20),
      child: FloatingActionButton(
        onPressed: () {
          // Navegação declarativa: sempre volta para o dashboard
          context.go(AppRoutes.dashboard);
        },
        backgroundColor: SoloForteColors.greenIOS,
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}
