# PROMPT — PASSO 2: Rotas (app_routes + app_router)
# Agente: GitHub Copilot / Antigravity / Cursor
# Módulo: core/router (único arquivo autorizado a conhecer módulos)
# Tipo: feature
# Bounded context: NÃO altera fronteiras — apenas adiciona rotas no ponto oficial
# Pré-requisito: PASSO 1 concluído e build_runner rodado

---

## CONTEXTO

O projeto usa GoRouter declarativo.
- `lib/core/router/app_routes.dart` — constantes de rotas
- `lib/core/router/app_router.dart` — definição do GoRouter
- Namespace `/consultoria/*` já existe no projeto
- SmartButton já detecta `path.startsWith('/consultoria/')` → exibe ← sem alteração

---

## OBJETIVO

Adicionar 5 constantes em `AppRoutes` e 5 `GoRoute` no `GoRouter`.
NÃO alterar nenhuma rota existente. NÃO mover nenhum arquivo.

---

## ARQUIVO 1 — app_routes.dart

**Destino:** `lib/core/router/app_routes.dart`

**Adicionar dentro da classe `AppRoutes` (junto às demais constantes):**

```dart
// Relatórios
static const relatorios = '/consultoria/relatorios';
static const relatorioDetail = '/consultoria/relatorios/:id';
static String relatorioDetailPath(String id) =>
    '/consultoria/relatorios/$id';

// Publicações
static const publicacoes = '/consultoria/publicacoes';
static const publicacaoNova = '/consultoria/publicacoes/nova';
static const publicacaoDetail = '/consultoria/publicacoes/:id';
static String publicacaoDetailPath(String id) =>
    '/consultoria/publicacoes/$id';
```

**Restrições:**
- NÃO criar sub-rotas de `/map`
- NÃO alterar nenhuma constante existente
- Ordem: adicionar após as constantes de `/consultoria` já existentes

---

## ARQUIVO 2 — app_router.dart

**Destino:** `lib/core/router/app_router.dart`

**Adicionar dentro do GoRouter, junto às rotas de `/consultoria`:**

```dart
GoRoute(
  path: AppRoutes.relatorios,
  builder: (context, state) => const RelatoriosListScreen(),
),
GoRoute(
  path: AppRoutes.relatorioDetail,
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return RelatorioDetailScreen(relatorioId: id);
  },
),
GoRoute(
  path: AppRoutes.publicacoes,
  builder: (context, state) => const PublicacoesListScreen(),
),
GoRoute(
  path: AppRoutes.publicacaoNova,
  builder: (context, state) => const PublicacaoFormScreen(),
),
GoRoute(
  path: AppRoutes.publicacaoDetail,
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return PublicacaoDetailScreen(publicacaoId: id);
  },
),
```

**Imports a adicionar no topo do app_router.dart:**
```dart
import '../../modules/consultoria/relatorios/presentation/relatorios_list_screen.dart';
import '../../modules/consultoria/relatorios/presentation/relatorio_detail_screen.dart';
import '../../modules/consultoria/publicacoes/presentation/publicacoes_list_screen.dart';
import '../../modules/consultoria/publicacoes/presentation/publicacao_form_screen.dart';
import '../../modules/consultoria/publicacoes/presentation/publicacao_detail_screen.dart';
```

**Restrições:**
- NÃO alterar nenhuma rota existente
- NÃO criar sub-rota de `/map`
- NÃO usar `Navigator.push` ou `context.pop`
- Todas as telas novas usam `context.go()` internamente

---

## VALIDAÇÃO FINAL

- [ ] `AppRoutes` tem 7 novas constantes (5 rotas + 2 helpers de path)
- [ ] `GoRouter` tem 5 novos `GoRoute`
- [ ] Nenhuma rota existente foi alterada ou removida
- [ ] Nenhuma sub-rota de `/map` foi criada
- [ ] `flutter analyze` → 0 erros
