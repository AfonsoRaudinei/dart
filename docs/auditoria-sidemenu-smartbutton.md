# AUDITORIA AUTOMÁTICA: SIDEMENU + SMARTBUTTON — SOLOFORTE
**TIPO:** Checklist de Validação Arquitetural  
**DATA DE CRIAÇÃO:** 08/02/2026  
**USO:** Executar sempre que houver mudança em Rotas, Navegação, SmartButton, SideMenu ou AppShell

---

## 📋 OBJETIVO DESTA AUDITORIA

Validar automaticamente que:
1. Todas as rotas estão catalogadas no índice canônico
2. O SideMenu está acessível apenas no namespace `/dashboard`
3. O SmartButton segue as regras de namespace
4. Não há uso de navegação imperativa (`pop`, `canPop`)
5. A implementação está aderente aos contratos arquiteturais

---

## 📚 CONTRATOS DE REFERÊNCIA (OBRIGATÓRIOS)

Esta auditoria valida conformidade com:
- ✅ `docs/arquitetura-navegacao.md`
- ✅ `docs/arquitetura-namespaces-rotas.md`
- ✅ `docs/arquitetura-sidemenu.md`
- ✅ `docs/indice-rotas.md`

---

## 🔍 FASE 1: AUDITORIA DE ROTAS

### 1.1. Cobertura do Índice Canônico
- [ ] Todas as rotas em `app_router.dart` estão listadas em `indice-rotas.md`
- [ ] Nenhuma rota hardcoded fora de `AppRoutes`
- [ ] Todas as rotas usam constantes de `AppRoutes`

### 1.2. Validação de Namespaces
Para cada rota listada em `indice-rotas.md`, verificar:
- [ ] Namespace está explícito na tabela
- [ ] Status (Oficial / Legado / Técnico) está definido
- [ ] Coluna "Agente IA" está preenchida

### 1.3. Rotas Fantasma
- [ ] Não há rotas não registradas no router
- [ ] Não há navegação para paths não existentes
- [ ] Não há `context.go()` com strings literais

---

## 🔍 FASE 2: AUDITORIA DO SIDEMENU

### 2.1. Disponibilidade
Verificar arquivo: `lib/ui/components/app_shell.dart`

- [ ] SideMenu é renderizado como `endDrawer`
- [ ] Existe condição `isAuth` para renderizar
- [ ] SideMenu é `const SideMenu()` (singleton)
- [ ] Não há múltiplas instâncias de SideMenu

### 2.2. Conteúdo Fixo
Verificar arquivo: `lib/ui/components/side_menu.dart`

- [ ] Lista de itens do menu é fixa (não muda por rota)
- [ ] Todos os itens usam `context.go(AppRoutes.xxx)`
- [ ] Nenhum item usa `Navigator.push()` ou variações
- [ ] Botão "Voltar ao Mapa" usa lógica de namespace

### 2.3. Lógica de "Voltar ao Mapa"
Verificar método: `SideMenu.shouldShowBackButton()`

- [ ] Usa lista de `rootNamespaces`
- [ ] Verifica igualdade exata para raízes
- [ ] Retorna `true` para sub-rotas
- [ ] NÃO usa `Navigator.canPop()`

**Namespaces Raiz Esperados:**
```dart
['/dashboard', '/consultoria', '/solo-cultivares', '/gestao-agricola', '/marketing']
```

---

## 🔍 FASE 3: AUDITORIA DO SMARTBUTTON

### 3.1. Detecção de Namespace
Verificar arquivo: `lib/ui/components/smart_button.dart`

- [ ] Usa `GoRouter.of(context).routerDelegate.currentConfiguration`
- [ ] Extrai `uri.path` da rota atual
- [ ] NÃO usa comparação de igualdade exata apenas

**Regra Obrigatória:**
```dart
final bool isDashboard =
    uri == AppRoutes.dashboard || uri.startsWith('${AppRoutes.dashboard}/');
```

### 3.2. Comportamento por Namespace

| Condição | Ícone | Ação | Validação |
|----------|-------|------|-----------|
| `isDashboard` | ☰ | Abrir SideMenu | `Scaffold.of(context).openEndDrawer()` |
| `!isDashboard` | ← | Ir para Dashboard | `context.go(AppRoutes.dashboard)` |
| Rota pública | CTA | Ir para Login | `context.go(AppRoutes.login)` |

- [ ] Código implementa exatamente esses 3 casos
- [ ] NÃO há uso de `Navigator.pop()`
- [ ] NÃO há uso de `context.pop()`
- [ ] NÃO há verificação de `canPop()`

### 3.3. Proibições Absolutas

Verificar que NÃO existe no código:
- [ ] ❌ `Navigator.pop()`
- [ ] ❌ `context.pop()`
- [ ] ❌ `Navigator.canPop()`
- [ ] ❌ `context.canPop()`
- [ ] ❌ `ModalRoute.of(context)`
- [ ] ❌ Lógica baseada em stack de navegação
- [ ] ❌ Exceções hardcoded por rota específica

---

## 🔍 FASE 4: AUDITORIA DE NAVEGAÇÃO

### 4.1. Navegação Declarativa
Verificar em **todos os arquivos de navegação**:

- [ ] Usa `context.go()` para navegação principal
- [ ] Usa `context.push()` apenas para modais/overlays (se aplicável)
- [ ] Nunca usa `Navigator.push()`
- [ ] Nunca usa rotas nomeadas antigas (`pushNamed`)

### 4.2. Rotas Públicas
- [ ] `/public-map` não renderiza SideMenu
- [ ] `/login` não renderiza SideMenu
- [ ] `/signup` não renderiza SideMenu
- [ ] SmartButton em rotas públicas mostra CTA de login

### 4.3. Deep Links
- [ ] App suporta navegação direta para qualquer rota
- [ ] SmartButton detecta namespace corretamente após deep link
- [ ] Não há dependência de histórico de navegação

---

## 🔍 FASE 5: VALIDAÇÃO TÉCNICA

### 5.1. Imports e Dependências
- [ ] `smart_button.dart` importa `go_router`
- [ ] `smart_button.dart` importa `app_routes.dart`
- [ ] `side_menu.dart` importa `go_router`
- [ ] `side_menu.dart` importa `app_routes.dart`
- [ ] Nenhum arquivo importa `Navigator` diretamente

### 5.2. Análise Estática
Executar:
```bash
flutter analyze
```

- [ ] Nenhum erro relacionado a navegação
- [ ] Nenhum warning de `deprecated_member_use` em navegação
- [ ] Código compila sem erros

### 5.3. Testes de Build
- [ ] `flutter build --debug` completa sem erros
- [ ] Hot reload funciona após mudanças no SmartButton
- [ ] Hot restart não quebra detecção de namespace

---

## 📊 TABELA VERDADE — VALIDAÇÃO ESPERADA

Use esta tabela para validação manual ou automatizada:

| Rota | SideMenu Existe? | SmartButton | Acessível via ☰? | Ação do Botão |
|------|------------------|-------------|------------------|---------------|
| `/public-map` | ❌ | CTA Login | ❌ | Ir para `/login` |
| `/login` | ❌ | CTA Login | ❌ | Ir para `/login` |
| `/dashboard` | ✅ | ☰ | ✅ | Abrir SideMenu |
| `/dashboard/mapa-tecnico` | ✅ | ☰ | ✅ | Abrir SideMenu |
| `/consultoria/relatorios` | ✅ | ← | ❌ | Ir para `/dashboard` |
| `/consultoria/clientes/123` | ✅ | ← | ❌ | Ir para `/dashboard` |
| `/settings` | ✅ | ← | ❌ | Ir para `/dashboard` |
| `/agenda` | ✅ | ← | ❌ | Ir para `/dashboard` |

**Validação:**
- [ ] Todos os comportamentos acima estão corretos

---

## ✅ CHECKLIST FINAL DE CONFORMIDADE

### Contratos Arquiteturais
- [ ] O SmartButton depende **exclusivamente** de namespace (não de stack)
- [ ] O SideMenu está disponível em **todas as rotas autenticadas**
- [ ] O SideMenu é **acessível apenas via ☰** no `/dashboard`
- [ ] Navegação é **100% declarativa** (`context.go()`)
- [ ] Não há **exceções hardcoded** por rota

### Códigos Verificados
- [ ] `lib/ui/components/smart_button.dart`
- [ ] `lib/ui/components/side_menu.dart`
- [ ] `lib/ui/components/app_shell.dart`
- [ ] `lib/core/router/app_routes.dart`
- [ ] `lib/core/router/app_router.dart`

### Documentação
- [ ] `docs/arquitetura-navegacao.md` está atualizado
- [ ] `docs/arquitetura-sidemenu.md` está atualizado
- [ ] `docs/indice-rotas.md` cobre 100% das rotas
- [ ] `docs/validation_smartbutton_dashboard_namespace.md` está válido

---

## 📝 FORMATO DE SAÍDA DA AUDITORIA

Ao executar esta auditoria, usar o seguinte formato de relatório:

```
═══════════════════════════════════════════════════════
AUDITORIA: SIDEMENU + SMARTBUTTON
Data: [DD/MM/YYYY]
Executor: [Nome do Engenheiro ou Agente IA]
═══════════════════════════════════════════════════════

STATUS GERAL: [✅ APROVADO | ⚠️ APROVADO COM RESSALVAS | ❌ REPROVADO]

─────────────────────────────────────────────────────
FASE 1: AUDITORIA DE ROTAS
─────────────────────────────────────────────────────
✅ Cobertura do índice: 100%
✅ Rotas usam AppRoutes: Sim
❌ Rotas fantasma encontradas: [listar se houver]

─────────────────────────────────────────────────────
FASE 2: AUDITORIA DO SIDEMENU
─────────────────────────────────────────────────────
✅ SideMenu é singleton: Sim
✅ Conteúdo é fixo: Sim
✅ Usa navegação declarativa: Sim
✅ Lógica de namespace correta: Sim

─────────────────────────────────────────────────────
FASE 3: AUDITORIA DO SMARTBUTTON
─────────────────────────────────────────────────────
✅ Detecta namespace corretamente: Sim
✅ Não usa Navigator.pop(): Confirmado
✅ Comportamento conforme tabela verdade: Sim

─────────────────────────────────────────────────────
FASE 4: AUDITORIA DE NAVEGAÇÃO
─────────────────────────────────────────────────────
✅ Navegação declarativa: Sim
✅ Deep links funcionam: Sim
✅ Rotas públicas sem SideMenu: Sim

─────────────────────────────────────────────────────
FASE 5: VALIDAÇÃO TÉCNICA
─────────────────────────────────────────────────────
✅ flutter analyze: Sem erros críticos
✅ Build completa: Sim
✅ Hot reload funciona: Sim

─────────────────────────────────────────────────────
FALHAS ENCONTRADAS
─────────────────────────────────────────────────────
[Listar cada falha com localização exata]
- [Nenhuma] OU
- Arquivo: [path]
  Linha: [número]
  Descrição: [problema]
  Severidade: [CRÍTICA | MÉDIA | BAIXA]

─────────────────────────────────────────────────────
ARQUIVOS IMPACTADOS
─────────────────────────────────────────────────────
[Listar arquivos que precisam de correção]

─────────────────────────────────────────────────────
CONTRATOS VIOLADOS
─────────────────────────────────────────────────────
[Listar contratos violados, se houver]
- [Nenhum] OU
- docs/arquitetura-navegacao.md (seção X)
- docs/arquitetura-namespaces-rotas.md (regra Y)

─────────────────────────────────────────────────────
RECOMENDAÇÕES
─────────────────────────────────────────────────────
[Ação objetiva e específica]
- [Nenhuma ação necessária] OU
- Corrigir arquivo X, linha Y
- Atualizar contrato Z
- Adicionar rota W ao índice

═══════════════════════════════════════════════════════
FIM DO RELATÓRIO
═══════════════════════════════════════════════════════
```

---

## 🤖 USO POR AGENTES IA

Ao receber uma tarefa de modificação de navegação:

1. **Antes de Implementar:**
   - Executar Fases 1-5 desta auditoria
   - Gerar relatório de estado atual
   - Identificar pontos de impacto

2. **Após Implementar:**
   - Re-executar Fases 1-5
   - Comparar com estado anterior
   - Confirmar que nenhum contrato foi violado

3. **Se Falhas Forem Detectadas:**
   - **PARAR** imediatamente
   - **NÃO** implementar a mudança
   - **RELATAR** ao usuário
   - **AGUARDAR** confirmação

---

## ⚠️ QUANDO EXECUTAR ESTA AUDITORIA

Execute esta auditoria:

- ✅ Antes de adicionar nova rota
- ✅ Antes de modificar SmartButton
- ✅ Antes de alterar SideMenu
- ✅ Antes de mudar AppShell
- ✅ Antes de adicionar novo namespace
- ✅ Após merge de branch de navegação
- ✅ Antes de release de versão
- ✅ Quando houver regressão reportada

---

**FIM DA AUDITORIA AUTOMÁTICA**
