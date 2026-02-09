# DECISÃO ARQUITETURAL: MAP-FIRST (Dashboard → Map)

**STATUS:** ✅ IMPLEMENTADO  
**DATA DA DECISÃO:** 09/02/2026  
**AUTORIA:** Arquitetura SoloForte  
**IMPACTO:** 🔴 **CRÍTICO** — Mudança estrutural no núcleo do sistema

---

## 📋 Resumo Executivo

O namespace `/dashboard` foi **DEFINITIVAMENTE SUBSTITUÍDO** por `/map` como namespace central canônico do SoloForte.

Esta é uma decisão arquitetural **irreversível** que reflete a verdadeira natureza Map-First do sistema.

---

## 🎯 Objetivo

Redefinir o núcleo do sistema substituindo o namespace `/dashboard` por `/map`, consolidando o mapa como **rota única, singleton e central**, e removendo rotas que representavam apenas estados visuais.

---

## 🔁 Mudança Estrutural Obrigatória

### ❌ Namespace Antigo (DESCONTINUADO)

```
/dashboard
/dashboard/*
```

**Motivos para descontinuação:**
- O termo "Dashboard" não representa o modelo mental do app
- Não reflete arquitetura map-first real
- Induz erro de criar sub-rotas para estados visuais

### ✅ Novo Namespace Canônico

```
/map
```

**Verdade definitiva:**
- `/map` é o home
- `/map` é o único ponto de entrada do mapa
- `/map` é o centro cognitivo e operacional do SoloForte
- Existe um **único mapa físico** (singleton)

---

## 🚫 Proibição Absoluta de Sub-rotas do Mapa

As seguintes rotas **NÃO DEVEM EXISTIR**:

```
/map/mapa-tecnico    ❌
/map/clima-eventos   ❌
/map/ocorrencias     ❌
/map/publicacoes     ❌
/map/ndvi            ❌
```

### Motivo

Estas rotas não representam:
- ❌ Telas diferentes
- ❌ Navegação entre páginas
- ❌ Hierarquia de navegação

Elas representam **modos, camadas e overlays** do mesmo mapa físico único.

Criar sub-rotas para isso é **erro arquitetural grave**.

---

## ✅ Modelo Correto — Estado Interno do Mapa

Esses contextos passam a ser **estado local do mapa**, controlados por contrato explícito:

```dart
enum MapContext {
  tecnico,
  clima,
  ocorrencias,
  publicacoes,
  ndvi,
}
```

### Regras

1. **Ícones** acima do mapa alteram somente `MapContext`
2. A **URL** permanece sempre `/map`
3. **Back button** não altera contexto
4. **Estado** pode ser persistido (offline-first)

---

## 🔗 Deep Link (Permitido de Forma Controlada)

Aceito **somente na entrada**:

```
/map?context=ocorrencias
/map?context=ndvi
/map?context=clima
```

**Regras:**
- Lido apenas no **bootstrap**
- Define **estado inicial**
- Após inicialização, URL **não governa comportamento**

---

## 🧠 Princípio de Ouro (Atualizado)

> **"Rota muda quando o usuário sai do mapa."**  
> **"Ícones mudam quando o usuário muda o contexto do mapa."**  
> **"/map substitui definitivamente /dashboard."**

---

## 📝 Mudanças Implementadas

### 1. Código Dart

#### `lib/core/router/app_routes.dart`
- ✅ Criada constante `AppRoutes.map = '/map'`
- ✅ `AppRoutes.dashboard` marcada como `@Deprecated`
- ✅ Função `getLevel()` atualizada (prioriza `/map`)
- ✅ Comentários atualizados

#### `lib/core/router/app_router.dart`
- ✅ Redirect de autenticação agora vai para `AppRoutes.map`
- ✅ Rota principal alterada de `/dashboard` para `/map`
- ✅ Redirect legado criado: `/dashboard` → `/map`

### 2. Documentação

#### `docs/indice-rotas.md`
- ✅ Namespace "Map" substituiu "Dashboard"
- ✅ `/map` marcado como **Oficial**
- ✅ `/dashboard` marcado como **Legado**
- ✅ Todas as referências atualizadas

#### `docs/arquitetura-navegacao.md`
- ✅ Seção 3 completamente reescrita (MAP-CENTRIC)
- ✅ Proibição explícita de sub-rotas `/map/*`
- ✅ Modelo de `MapContext` documentado
- ✅ Deep links documentados
- ✅ Princípio de Ouro atualizado

#### `docs/arquitetura-namespaces-rotas.md`
- ✅ Namespace `/map` como singleton
- ✅ Proibição de `startsWith('/map/')`
- ✅ Exemplos de código atualizados
- ✅ Regras de detecção de namespace atualizadas

---

## ⛔ Antipadrões Bloqueados

É **PROIBIDO**:

1. ❌ Usar `/dashboard` em novas implementações
2. ❌ Criar sub-rotas para modos do mapa
3. ❌ Tratar ícones como navegação
4. ❌ Inferir contexto do mapa via URL
5. ❌ Usar `startsWith('/map/...')` para estado interno

---

## ⚠️ Compatibilidade e Migração

### Período de Transição

- `/dashboard` continua **funcionando** via redirect para `/map`
- Código legado que usa `AppRoutes.dashboard` **continua funcionando**
- Warning de deprecação será exibido em desenvolvimento

### Remoção Futura

Em versão futura (após v1.2):
- Redirect `/dashboard` → `/map` será **removido**
- Constante `AppRoutes.dashboard` será **removida**
- Código que use `/dashboard` **quebrará**

**Recomendação:** Migrar todo código para usar `AppRoutes.map` imediatamente.

---

## 📊 Impacto

### Áreas Afetadas

- 🔴 **Core Router** — Mudança em rotas principais
- 🔴 **SmartButton** — Lógica de detecção de namespace  
- 🔴 **SideMenu** — Disponibilidade baseada em rota
- 🟡 **Deep Links** — Novo formato com query params
- 🟡 **Documentação** — Reescrita completa de contratos

### Áreas NÃO Afetadas

- ✅ **Telas existentes** — Funcionam sem alteração
- ✅ **Navegação de usuário** — Transparente
- ✅ **Persistência** — Sem impacto
- ✅ **Módulos** — Consultoria, Settings, etc. intocados

---

## 🎓 Justificativa Técnica

### Por que "/map" ao invés de "/dashboard"?

1. **Semântica Clara**
   - "Mapa" descreve exatamente o que é
   - "Dashboard" sugere múltiplas telas/widgets

2. **Modelo Mental Correto**
   - Existe um único mapa físico
   - Contextos são overlays, não páginas

3. **Prevenção de Erros**
   - Nome correto evita tentação de criar `/map/submenu`
   - Arquitetura autodocumentada

4. **Map-First Real**
   - Nome reflete arquitetura
   - Centro do app é literalmente "o mapa"

---

## ✅ Status da Decisão

- [x] Decisão aprovada
- [x] Código atualizado
- [x] Documentação atualizada
- [x] Testes de navegação validados
- [x] Compatibilidade garantida
- [x] Decisão congelada (irreversível)

---

## 📚 Referências

- `docs/arquitetura-navegacao.md`
- `docs/arquitetura-namespaces-rotas.md`
- `docs/indice-rotas.md`
- `lib/core/router/app_routes.dart`
- `lib/core/router/app_router.dart`

---

## 🔒 Imutabilidade

**Esta decisão é FINAL e IRREVERSÍVEL.**

Qualquer tentativa de:
- Reverter para `/dashboard`
- Criar sub-rotas `/map/*`
- Ignorar este contrato

Será **REJEITADA** em code review.

---

**Fim do Documento de Decisão Arquitetural**
