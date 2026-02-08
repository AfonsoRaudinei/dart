# Índice Canônico de Rotas — SoloForte

## 1. Visão Geral
Este documento é a **ÚNICA FONTE DA VERDADE** para a estrutura de navegação do SoloForte. Ele reflete a arquitetura real implementada no código e serve como guia para desenvolvedores, auditores e agentes de IA.

### Princípios de Namespaces
O SoloForte utiliza uma navegação baseada em domínios (namespaces). O `/dashboard` é o centro gravitacional do app (Map-First).

### Regra de Leitura
- **Canônica**: Rota oficial, deve ser usada para navegação ativa.
- **Técnica**: Rota de suporte, ShellRoute ou redirect estrutural.
- **Legado**: Rota mantida apenas para compatibilidade curta, será removida em breve.

---

## 2. Índice Canônico (Tabela Oficial)

| Namespace | Rota | Descrição Funcional | Status | Agente IA |
| :--- | :--- | :--- | :--- | :--- |
| **Público** | `/` | Redirect inicial para `/public-map` | Técnico | Sim |
| **Público** | `/public-map` | Mapa de boas-vindas (Landing Page) | Oficial | Sim |
| **Público** | `/login` | Tela de autenticação | Oficial | Sim |
| **Público** | `/signup` | Cadastro de novos usuários | Oficial | Sim |
| **Dashboard** | `/dashboard` | Mapa Técnico (Coração do App / Map-First) | Oficial | Sim |
| **Dashboard** | `/map` | Alias legado para `/dashboard` | Legado | Não |
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

## 3. Diagnóstico de Arquitetura

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

Ela é a **ÚNICA rota autorizada** a renderizar um mapa **fora do namespace `/dashboard/*`**.

#### Justificativa
- Contexto público (pré-login)
- Landing page e onboarding
- Não representa operação técnica nem uso em campo

#### Regras obrigatórias
- `/public-map` **não define padrão arquitetural**
- **É proibido criar novos mapas públicos**
- **É proibido renderizar mapas técnicos fora de `/dashboard/*`**
- `/public-map` **não deve ser usado como referência** para novas funcionalidades

⚠️ Qualquer novo mapa (técnico, operacional ou autenticado)
**DEVE obrigatoriamente** existir sob `/dashboard/*`.

Violação desta regra compromete:
- o contrato Map-First
- o comportamento do SmartButton
- a previsibilidade da navegação

### ⚠️ Rotas Fantasma (Legacy Masking)
- Arquivo `lib/ui/screens/misc_screens.dart` contém classes como `SettingsScreen`, `ClientesScreen` e `RelatoriosScreen` que estão sendo mascaradas (ocultadas) por imports de módulos no `app_router.dart`.
- Isso causa "Dead Code" silencioso e risco de importar a tela errada em refatorações manuais.

---

## 4. Regras para Futuras Rotas

1. **Hierarchy First**: Novas telas devem ser sub-rotas de um namespace existente.
2. **Namespace Obrigatório**: Se uma funcionalidade for um novo módulo, ela DEVE iniciar um novo namespace (ex: `/gestao/*`).
3. **SmartButton Awareness**: O SmartButton (FAB) altera seu comportamento baseado em `startsWith('/dashboard/')`. Se uma rota de mapa for criada fora de `/dashboard`, o SmartButton precisará de atualização.
4. **AppRoutes Alignment**: NUNCA usar strings hardcoded no código. Registrar em `AppRoutes` e usar no `AppRouter`.

---

## 5. Auditoria de Validação

- **Total de rotas identificadas:** 18 (15 canônicas + 1 inicial + 2 redirects legados)
- **Quantos namespaces existem:** 4 (Público, Dashboard, Consultoria, Geral)
- **Existe rota fora de namespace?** Sim (Geral: `/settings`, `/agenda`, `/feedback`)
- **Existe mapa fora de /dashboard/*?** Sim (`/public-map` na Landing Page)
- **Índice cobre 100% das rotas?** Sim
