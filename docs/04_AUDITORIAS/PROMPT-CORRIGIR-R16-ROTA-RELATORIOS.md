# PROMPT — Corrigir R16: Rota /consultoria/relatorios

**Tipo:** Correção de rota — sem alterar lógica
**Risco:** BAIXO
**Arquivo alvo:** lib/core/router/app_router.dart

---

## OBJETIVO

Garantir que a rota de relatorios está registrada como sub-rota de
/consultoria/relatorios e não como rota raiz genérica.

---

## VERIFICAR

Localizar em app_router.dart como a rota está registrada hoje.

Se estiver assim (errado):
```dart
GoRoute(
  path: '/relatorios',
  builder: (_, __) => const RelatoriosPage(),
),
```

Corrigir para:
```dart
GoRoute(
  path: '/consultoria/relatorios',
  builder: (_, __) => const RelatoriosPage(),
),
```

---

## REGRA MAP-FIRST

SmartButton em /consultoria/relatorios:
- isMap = false (path != '/map')
- Ícone: ←
- Ação: context.go('/map')

Verificar que SmartButton detecta corretamente o namespace /consultoria/.

---

## VALIDACAO FINAL

- [ ] Rota registrada como /consultoria/relatorios
- [ ] context.go('/consultoria/relatorios') navega corretamente
- [ ] SmartButton mostra ← nesta rota
- [ ] flutter analyze → 0 erros novos
- [ ] arch_check.sh → Exit 0
