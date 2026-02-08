# CONTRATO ARQUITETURAL DE NAMESPACES DE ROTAS
**STATUS: CONTRATO CONGELADO**
**DATA:** 08/02/2026

Este documento define a estratégia oficial de namespaces de rotas no SoloForte.
É a fonte da verdade para toda lógica que depende de contexto de navegação.

---

## 1. VISÃO GERAL

O SoloForte adota um modelo de navegação baseado em **namespaces de rotas**, e **não** em rotas isoladas.

Uma rota representa um **contexto funcional**, não apenas uma tela.

### 1.1. Regra Central
> **"Componentes globais nunca devem depender de igualdade exata de rota, apenas de pertencimento a namespace."**

---

## 2. PRINCÍPIO ARQUITETURAL FUNDAMENTAL

> **"Rotas definem domínios funcionais."**
> **"Telas são estados dentro desses domínios."**

Qualquer lógica de:
- Navegação
- Botão global
- Menu
- Permissões
- Persistência
- Comportamento sistêmico

deve operar sobre **namespaces**, nunca sobre strings exatas.

---

## 3. NAMESPACES CANÔNICOS DO SISTEMA

### 3.1. `/dashboard/*` — Namespace Central (Mapa)

O Dashboard é o **centro do app** e é tratado como **namespace raiz funcional**.

**Inclui, mas não se limita a:**
- `/dashboard`
- `/dashboard/mapa-tecnico`
- `/dashboard/clima-eventos`
- `/dashboard/ocorrencias`
- `/dashboard/publicacoes`
- Qualquer rota futura sob `/dashboard/*`

⚠️ **Todas essas rotas SÃO Dashboard** do ponto de vista arquitetural.

---

### 3.2. `/consultoria/*` — Namespace de Consultoria

**Inclui:**
- Clientes (`/consultoria/clientes`)
- Relatórios (`/consultoria/relatorios`)
- Agenda (se aplicável)
- Comunicação
- Histórico

**Rotas sob esse namespace:**
- **NÃO** são Dashboard
- **NÃO** abrem SideMenu
- Usam botão global de **retorno ao Dashboard**

---

### 3.3. `/settings/*` — Namespace de Configurações

**Inclui:**
- Perfil
- Tema
- Offline
- Sessão

**Mesmo comportamento:**
- Fora do Dashboard
- Retorno explícito para `/dashboard`

---

## 4. REGRA CANÔNICA DE DETECÇÃO DE NAMESPACE

### 4.1. Implementação Obrigatória

```dart
final path = GoRouterState.of(context).uri.path;

final bool isDashboard =
    path == AppRoutes.dashboard ||
    path.startsWith('${AppRoutes.dashboard}/');
```

**Ou, com constantes:**
```dart
final bool isDashboard = path == AppRoutes.dashboard || 
                         path.startsWith('${AppRoutes.dashboard}/');

final bool isConsultoria = path.startsWith('/consultoria/');
final bool isSettings = path.startsWith('/settings');
```

### 4.2. Proibições Absolutas

É expressamente proibido:
- ❌ Usar igualdade exata apenas (`path == '/dashboard'`)
- ❌ Inferir namespace por widget visível
- ❌ Usar histórico de navegação (`canPop`, stack)
- ❌ Criar exceções "só para essa rota"

---

## 5. COMPONENTES AFETADOS POR NAMESPACE

Os seguintes componentes **devem** respeitar namespaces:

1. **SmartButton** (☰ / ←)
2. **SideMenu** (disponibilidade)
3. **Botão físico Back** (Android/iOS)
4. **Persistência de estado local**
5. **Modo Desenho**
6. **Ocorrências**
7. **Sessão de Visita**

Todos eles dependem de **onde o usuário está** (namespace), não de **qual tela exata**.

---

## 6. NAVEGAÇÃO DECLARATIVA (OBRIGATÓRIA)

O SoloForte adota navegação **declarativa e determinística**.

### 6.1. Regras de Navegação

**Proibido:**
- ❌ `Navigator.pop()`
- ❌ `context.pop()`
- ❌ `context.canPop()`
- ❌ Navegação baseada em stack

**Obrigatório:**
- ✅ `context.go('/dashboard')`
- ✅ `context.go(AppRoutes.dashboard)`
- ✅ Rotas explícitas

O **namespace define o destino**, não o histórico.

---

## 7. ANTIPADRÕES PROIBIDOS

É expressamente proibido:

1. Criar lógica especial para `/dashboard/mapa-tecnico` isoladamente
2. Tratar `/dashboard` como tela única (ignorando sub-rotas)
3. Criar exceções "só para essa rota" sem namespace
4. Basear comportamento em `ModalRoute.of(context)`
5. Inferir contexto por visibilidade de widget
6. Usar `if (widget is PrivateMapScreen)` para lógica de navegação

### 7.1. Por Que São Proibidos

Esses antipadrões causam:
- Regressões silenciosas
- Bugs intermitentes
- Inconsistência de UX
- Comportamento imprevisível do botão global
- Dificuldade de escalabilidade

---

## 8. JUSTIFICATIVA TÉCNICA

O SoloForte é:
- **Map-centric**: O mapa é a âncora cognitiva.
- **Orientado a campo**: Operações críticas em ambientes instáveis.
- **Offline-first**: Sem dependência de conectividade.

**Namespaces garantem:**
- Previsibilidade (sempre sabemos o contexto)
- Escalabilidade (adicionar rotas não quebra lógica)
- Facilidade de auditoria (logs mostram domínio, não tela)
- Adição de rotas sem refatorar lógica global

---

## 9. EXEMPLOS PRÁTICOS

### 9.1. SmartButton (Correto)
```dart
final path = GoRouterState.of(context).uri.path;
final bool isDashboard = path == AppRoutes.dashboard || 
                         path.startsWith('${AppRoutes.dashboard}/');

if (isDashboard) {
  // Ícone: ☰ (Menu)
  return FloatingActionButton(
    onPressed: () => Scaffold.of(context).openEndDrawer(),
    child: Icon(Icons.menu),
  );
} else {
  // Ícone: ← (Voltar para Dashboard)
  return FloatingActionButton(
    onPressed: () => context.go(AppRoutes.dashboard),
    child: Icon(Icons.arrow_back),
  );
}
```

### 9.2. SmartButton (ERRADO — NÃO FAZER)
```dart
// ❌ ERRADO: Usa igualdade exata
final bool isDashboard = path == '/dashboard';

// ❌ ERRADO: Depende de widget
if (child is PrivateMapScreen) { ... }

// ❌ ERRADO: Depende de histórico
if (Navigator.canPop(context)) { ... }
```

---

## 10. ADICIONANDO NOVOS NAMESPACES

Ao criar um novo domínio funcional (ex: `/marketing/*`, `/analise/*`):

1. **Documentar** o namespace em `AppRoutes`
2. **Atualizar** SmartButton se necessário
3. **Definir** comportamento de retorno (sempre para `/dashboard`)
4. **Testar** deep links e navegação direta
5. **NÃO** criar lógica especial por rota exata

---

## 11. REGRA PARA AGENTES (PROMPTS FUTUROS)

Todo agente técnico, humano ou IA, deve respeitar:

> "Dashboard é um **namespace**, não uma rota única.
> Sub-rotas pertencem ao mesmo domínio.
> Componentes globais **nunca** usam igualdade exata de path.
> Navegação é **declarativa**, não baseada em stack."

**Exceções exigem revisão arquitetural formal.**

❌ **Pull Requests que violem esse contrato devem ser rejeitados.**

---

## 12. STATUS DO CONTRATO

Este contrato é:
- ✅ Oficial
- ✅ Obrigatório
- ✅ Retrocompatível
- ❌ Não opcional
- ❌ Não sujeito a exceções por módulo

Qualquer mudança neste documento requer revisão arquitetural explícita.

---

## 13. VALIDAÇÃO DE CONFORMIDADE

### Checklist para Code Review

- [ ] Componente usa `path.startsWith()` ao invés de `path ==`?
- [ ] Nenhuma lógica depende de `Navigator.canPop()`?
- [ ] Navegação usa `context.go()` ao invés de `pop()`?
- [ ] Nenhum `if (widget is ...)` para lógica de navegação?
- [ ] Deep links funcionam corretamente?

---

**FIM DO CONTRATO DE NAMESPACES**
