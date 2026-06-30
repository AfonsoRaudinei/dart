# CONTRATO ARQUITETURAL DE NAMESPACES DE ROTAS
**STATUS: CONTRATO CONGELADO**
**ÚLTIMA ATUALIZAÇÃO:** 09/02/2026 — Decisão Arquitetural MAP-FIRST

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

### 3.1. `/map` — Namespace Central (Mapa)

O Mapa é o **centro do app** e é tratado como **namespace raiz funcional**.

**Rota canônica:**
- `/map`

⚠️ **IMPORTANTE:** `/map` é um **singleton** — não possui sub-rotas válidas.

**Contextos do mapa (clima, ocorrências, NDVI, etc.) são estado interno, NÃO rotas.**

Qualquer tentativa de criar `/map/mapa-tecnico`, `/map/ocorrencias`, etc. é **violação arquitetural grave**.

---

### 3.2. `/consultoria/*` — Namespace de Consultoria

**Inclui:**
- Clientes (`/consultoria/clientes`)
- Relatórios (`/consultoria/relatorios`)
- Agenda (se aplicável)
- Comunicação
- Histórico

**Rotas sob esse namespace:**
- **NÃO** são Mapa
- **NÃO** abrem SideMenu
- Usam botão global de **retorno ao Mapa** (`/map`)

---

### 3.3. `/settings/*` — Namespace de Configurações

**Inclui:**
- Perfil
- Tema
- Offline
- Sessão

**Mesmo comportamento:**
- Fora do Mapa
- Retorno explícito para `/map`

---

## 4. REGRA CANÔNICA DE DETECÇÃO DE NAMESPACE

### 4.1. Implementação Obrigatória

```dart
final path = GoRouterState.of(context).uri.path;

final bool isMap = path == AppRoutes.map;
```

**Ou, com constantes:**
```dart
final bool isMap = path == AppRoutes.map;
final bool isConsultoria = path.startsWith('/consultoria/');
final bool isSettings = path.startsWith('/settings');
```

⚠️ **IMPORTANTE:** `/map` NÃO aceita `startsWith('/map/')` porque **não possui sub-rotas válidas**.

### 4.2. Proibições Absolutas

É expressamente proibido:
- ❌ Usar `path.startsWith('/map/')` (não existem sub-rotas)
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
- ✅ `context.go('/map')`
- ✅ `context.go(AppRoutes.map)`
- ✅ Rotas explícitas

O **namespace define o destino**, não o histórico.

---

## 7. ANTIPADRÕES PROIBIDOS

É expressamente proibido:

1. Criar sub-rotas sob `/map` (ex: `/map/mapa-tecnico`)
2. Tratar `/map` como namespace com sub-rotas
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
final bool isMap = path == AppRoutes.map;

if (isMap) {
  // Ícone: ☰ (Menu)
  return FloatingActionButton(
    onPressed: () => Scaffold.of(context).openEndDrawer(),
    child: Icon(Icons.menu),
  );
} else {
  // Ícone: ← (Voltar para Mapa)
  return FloatingActionButton(
    onPressed: () => context.go(AppRoutes.map),
    child: Icon(Icons.arrow_back),
  );
}
```

### 9.2. SmartButton (ERRADO — NÃO FAZER)
```dart
// ❌ ERRADO: Tenta usar sub-rotas de /map que não existem
final bool isMap = path.startsWith('/map/');

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
3. **Definir** comportamento de retorno (sempre para `/map`)
4. **Testar** deep links e navegação direta
5. **NÃO** criar lógica especial por rota exata

---

## 11. REGRA PARA AGENTES (PROMPTS FUTUROS)

Todo agente técnico, humano ou IA, deve respeitar:

> "O Mapa (`/map`) é um **singleton**, não um namespace com sub-rotas.
> Contextos do mapa (clima, ocorrências, NDVI) são **estado interno**, não rotas.
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
