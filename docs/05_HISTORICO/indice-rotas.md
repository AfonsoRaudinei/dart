# Índice Canônico de Rotas — SoloForte

## 1. Visão Geral
Este documento é a **ÚNICA FONTE DA VERDADE** para a estrutura de navegação do SoloForte. Ele reflete a arquitetura real implementada no código e serve como guia para desenvolvedores, auditores e agentes de IA.

### Princípios de Namespaces
O SoloForte utiliza uma navegação baseada em domínios (namespaces). O **`/map`** é o centro gravitacional do app (Map-First).

### Regra de Leitura
- **Canônica**: Rota oficial, deve ser usada para navegação ativa.
- **Técnica**: Rota de suporte, ShellRoute ou redirect estrutural.
- **Legado**: Rota mantida apenas para compatibilidade curta, será removida em breve.


---

## 2. Hierarquia Canônica do Sistema

Estrutura oficial de rotas do SoloForte em ordem de prioridade arquitetural:

```
/              → Roteamento técnico (redirect baseado em auth)
├─ /public-map → Exceção pública (landing page, pré-login, isolado)
├─ /login      → Autenticação
├─ /signup     → Cadastro
│
/map           → NÚCLEO ABSOLUTO (singleton, Map-First)
│                - Único mapa técnico do sistema
│                - Contextos via MapContext (estado interno)
│                - Deep links: /map?context=X
│
/consultoria/* → Fluxos secundários (retorno obrigatório para /map)
├─ /consultoria/relatorios
├─ /consultoria/clientes
│  └─ /consultoria/clientes/:id/fazendas/:farmId/talhoes/:fieldId
│
/settings      → Geral (transitório, retorno para /map)
/agenda        → Geral (transitório, retorno para /map)
/feedback      → Geral (transitório, retorno para /map)
```

**Regras:**
- `/map` é o **centro gravitacional** (Map-First)
- Rotas fora de `/map` retornam **explicitamente** via `context.go('/map')`
- `/public-map` é **isolado** (não compartilha estado com `/map`)
- "Geral" é **transitório** (migração futura planejada)

---

## 3. Índice Canônico (Tabela Oficial)

| Namespace | Rota | Descrição Funcional | Status | Agente IA |
| :--- | :--- | :--- | :--- | :--- |
| **Técnico** | `/` | Roteamento técnico (não renderiza UI) — Pré-login: `/public-map` · Pós-login: `/map` | Técnico | Sim |
| **Público** | `/public-map` | Mapa de boas-vindas (Landing Page) | Oficial | Sim |
| **Público** | `/login` | Tela de autenticação | Oficial | Sim |
| **Público** | `/signup` | Cadastro de novos usuários | Oficial | Sim |
| **Map** | `/map` | Mapa Técnico (Coração do App / Map-First) | **Oficial** | Sim |
| **Map** | `/dashboard` | Redirect legado para `/map` | Legado | Não |
| **Consultoria** | `/consultoria/relatorios` | Listagem de relatórios de visita | Oficial | Sim |
| **Consultoria** | `/consultoria/relatorios/novo` | Formulário de criação de relatório | Oficial | Sim |
| **Consultoria** | `/consultoria/relatorios/:id` | Detalhe completo do relatório | Oficial | Sim |
| **Consultoria** | `/consultoria/clientes` | Listagem de Clientes/Produtores | Oficial | Sim |
| **Consultoria** | `/consultoria/clientes/novo` | Cadastro de novo cliente | Oficial | Sim |
| **Consultoria** | `/consultoria/clientes/:id` | Detalhe do Cliente (incluindo Fazendas) | Oficial | Sim |
| **Consultoria** | `/consultoria/clientes/:id/fazendas/:farmId` | Detalhe da Fazenda (incluindo Talhões) | Oficial | Sim |
| **Consultoria** | `/consultoria/clientes/:id/fazendas/:farmId/talhoes/:fieldId` | Detalhe do Talhão | Oficial | Sim |
| **Consultoria** | `/clientes` | Alias legado para `/consultoria/clientes` | Legado | Não |
| **Geral** | `/settings` | Configurações do App e Perfil | Oficial | Sim |
| **Geral** | `/agenda` | Agenda de compromissos técnicos | Oficial | Sim |
| **Geral** | `/feedback` | Canal de suporte e feedbacks | Oficial | Sim |

---

## 4. Diagnóstico de Arquitetura

### ⚠️ Rotas Fora de Namespace
As seguintes rotas estão no nível raiz e não seguem a estrutura de namespaces `/nome-do-modulo/*`:
- `/settings`
- `/agenda`
- `/feedback`

**Recomendação:** No futuro, migrar para `/perfil/settings` ou `/utilitarios/*` para manter a consistência com `/consultoria`.

### 🛑 Namespace “Geral” — Classificação Transitória

O namespace **Geral** (rotas `/settings`, `/agenda`, `/feedback`) é classificado como
**TRANSITÓRIO** no estado atual da arquitetura.

Ele existe exclusivamente para:
- acomodar funcionalidades ainda não consolidadas em um domínio funcional definitivo
- evitar bloqueios de evolução enquanto os módulos amadurecem

⚠️ Regras obrigatórias:
- **É proibido adicionar novas rotas** ao namespace “Geral”.
- **É proibido expandir** este namespace como padrão arquitetural.
- O namespace **não representa um domínio final** do sistema.

#### Diretriz de Migração Futura
Em revisões arquiteturais futuras, rotas sob “Geral” **devem ser migradas** para
namespaces explícitos, como por exemplo:
- `/perfil/*` — conta, preferências, configurações
- `/utilitarios/*` — agenda, feedback, suporte, ajuda

❌ Tratar “Geral” como namespace definitivo é considerado violação arquitetural.

### 🛑 `/public-map` — Exceção Arquitetural Controlada

A rota **`/public-map`** é classificada como **EXCEÇÃO ARQUITETURAL CONTROLADA**.

Ela é a **ÚNICA rota autorizada** a renderizar um mapa **fora do namespace `/map`**.

#### Justificativa
- Contexto público (pré-login)
- Landing page e onboarding
- Não representa operação técnica nem uso em campo

#### Isolamento Obrigatório
- **NÃO compartilha estado** com o mapa interno (`/map`)
- **NÃO usa** `MapContext` (sem contextos técnicos)
- **NÃO evolui** para mapa técnico autenticado
- **NÃO interage** com dados de consultoria ou campo

#### Regras obrigatórias
- `/public-map` **não define padrão arquitetural**
- **É proibido criar novos mapas públicos**
- **É proibido renderizar mapas técnicos fora de `/map`**
- `/public-map` **não deve ser usado como referência** para novas funcionalidades

⚠️ Qualquer novo mapa (técnico, operacional ou autenticado)
**DEVE obrigatoriamente** existir como estado de `/map`, nunca como sub-rota.

Violação desta regra compromete:
- o contrato Map-First
- o comportamento do SmartButton
- a previsibilidade da navegação

### ⚠️ Rotas Fantasma (Legacy Masking)
- Arquivo `lib/ui/screens/misc_screens.dart` contém classes como `SettingsScreen`, `ClientesScreen` e `RelatoriosScreen` que estão sendo mascaradas (ocultadas) por imports de módulos no `app_router.dart`.
- Isso causa "Dead Code" silencioso e risco de importar a tela errada em refatorações manuais.

---

### 🔄 Regra de Retorno Obrigatório

**TODAS as rotas fora de `/map` devem retornar explicitamente para `/map`.**

#### Namespaces Afetados
- `/consultoria/*` (relatórios, clientes, fazendas, talhões)
- `/settings` (configurações)
- `/agenda` (compromissos)
- `/feedback` (suporte)

#### Regra Obrigatória

```dart
// ✅ CORRETO: Retorno explícito via context.go()
context.go('/map');
context.go(AppRoutes.map);
```

#### Proibições Absolutas

```dart
// ❌ PROIBIDO: Navegação baseada em stack
Navigator.pop(context);

// ❌ PROIBIDO: Uso de canPop()
if (context.canPop()) { context.pop(); }

// ❌ PROIBIDO: Retorno implícito ou heurístico
// Qualquer lógica que não use context.go('/map') explicitamente
```

**Justificativa:**
- Navegação declarativa (não baseada em histórico)
- Previsibilidade total do fluxo
- Garantia de retorno ao centro do app (Map-First)
- Sem dependência de estado de navegação



## 5. Regras para Futuras Rotas

1. **Hierarchy First**: Novas telas devem ser sub-rotas de um namespace existente.
2. **Namespace Obrigatório**: Se uma funcionalidade for um novo módulo, ela DEVE iniciar um novo namespace (ex: `/gestao/*`).
3. **SmartButton Awareness**: O SmartButton (FAB) altera seu comportamento baseado em `startsWith('/map/')`. Se uma rota de mapa for criada fora de `/map`, o SmartButton precisará de atualização.
4. **AppRoutes Alignment**: NUNCA usar strings hardcoded no código. Registrar em `AppRoutes` e usar no `AppRouter`.

---

## 6. Auditoria de Validação

- **Total de rotas identificadas:** 18 (15 canônicas + 1 inicial + 2 redirects legados)
- **Quantos namespaces existem:** 4 (Público, Map, Consultoria, Geral)
- **Existe rota fora de namespace?** Sim (Geral: `/settings`, `/agenda`, `/feedback`)
- **Existe mapa fora de /map?** Sim (`/public-map` na Landing Page — exceção controlada)
- **Índice cobre 100% das rotas?** Sim
