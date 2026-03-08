# PROMPT — Grupo D: Reserva de Área Exclusiva (kFabSafeArea) + client_detail_screen

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em Layout e UX Mobile
**Tipo:** Correção de Layout + Decisão Arquitetural (client_detail)
**PRD Referência:** PRD_SMART_BUTTON_UNIFICACAO.md — Erro 4, Seção 5.3 — Prioridade 3 Média
**Branch:** release/v1.1

---

## 1. ESCOPO

**Módulos:** `consultoria/clients`, `agenda/`

**Arquivos tocados:**
- `lib/modules/consultoria/clients/presentation/screens/client_detail_screen.dart`
- `lib/modules/agenda/presentation/pages/agenda_month_page.dart` *(apenas verificação de kFabSafeArea — não alterar se já presente)*

🚫 **Proibido alterar:**
- Lógica de negócio, providers, contratos de dados
- Qualquer outro arquivo

---

## 2. OBJETIVO

Resolver dois problemas distintos em `client_detail_screen.dart`: (1) remover o `IconButton` de retorno duplicado, aplicando a solução arquitetural documentada abaixo; (2) adicionar `SizedBox(height: kFabSafeArea)` ao fim do scrollable. Verificar e garantir `kFabSafeArea` em `agenda_month_page.dart` se ausente.

---

## 3. DECISÃO ARQUITETURAL — `client_detail_screen.dart`

**Situação:**
- Botão local: `context.go('/consultoria/clientes')` (volta para lista)
- SmartButton: `context.go(AppRoutes.map)` (vai para mapa)
- Ambos coexistem — dois destinos diferentes

**Decisão (conforme PRD seção 9, Grupo B nota):**

O botão local tem utilidade real: permite voltar à lista de clientes sem passar pelo mapa. Porém não pode coexistir com o SmartButton como botão de **retorno genérico**.

**Solução:** Transformar o botão de retorno em um botão de ação semântica explícita.

```dart
// ANTES — IconButton genérico de "voltar"
IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => context.go('/consultoria/clientes'),
),

// DEPOIS — Botão semântico explícito no body (não no header de navegação)
// Opção A: TextButton no topo do body com label claro
TextButton.icon(
  onPressed: () => context.go('/consultoria/clientes'),
  icon: const Icon(Icons.arrow_back, size: 16),
  label: const Text('Clientes'),
  style: TextButton.styleFrom(
    foregroundColor: Colors.grey,
    padding: EdgeInsets.zero,
  ),
),
```

**Critérios da solução:**
- ✅ Não é um botão de "voltar" genérico — é ação explícita "← Clientes"
- ✅ Não conflita visualmente com o SmartButton (posições distintas)
- ✅ Não usa AppBar leading (sem implication automática)
- ✅ Semântica clara para o usuário

**Posicionamento:** No início do body da tela (acima do nome do cliente), como breadcrumb de navegação. Não no AppBar. Não como FAB.

---

## 4. AÇÕES POR ARQUIVO

### 4.1 `client_detail_screen.dart`

**Passo 1 — Remover o IconButton atual:**
```dart
// Remover:
IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => context.go('/consultoria/clientes'),
),
```

**Passo 2 — Adicionar TextButton semântico no topo do body:**
Adicionar `TextButton.icon` (conforme modelo acima) como primeiro elemento do body/Column/ListView, antes do nome do cliente ou título da tela.

**Passo 3 — Adicionar ao fim do scrollable:**
```dart
SizedBox(height: kFabSafeArea),
```

**Passo 4 — Verificar import de `layout_constants.dart`:**
```dart
import 'package:soloforte/core/constants/layout_constants.dart';
```
Adicionar se ausente.

### 4.2 `agenda_month_page.dart`

**Verificar se `kFabSafeArea` já está presente:**
```bash
grep -n "kFabSafeArea" lib/modules/agenda/presentation/pages/agenda_month_page.dart
```

Se **ausente**: adicionar `SizedBox(height: kFabSafeArea)` ao fim do ListView.
Se **presente**: nenhuma alteração necessária neste arquivo.

---

## 5. CONTRATO DE DADOS

Nenhuma entidade alterada. Nenhum provider alterado.
Mudanças são de UI/layout e navegação local.

**Impacto retrocompatível:** SIM

---

## 6. VALIDAÇÃO FINAL

```bash
flutter analyze
```
Resultado esperado: **0 errors**

```bash
arch_check.sh
```
Resultado esperado: **Exit 0**

**Verificação visual manual:**
- Abrir `ClientDetailScreen` → confirmar botão "← Clientes" no topo do body
- Confirmar que SmartButton (canto inferior direito) não está coberto por conteúdo
- Confirmar que não há dois botões de "voltar" simultâneos

---

## 7. CHECKLIST DE ENCERRAMENTO

- [ ] `client_detail_screen.dart`: `IconButton(arrow_back)` removido
- [ ] `client_detail_screen.dart`: `TextButton.icon` semântico adicionado no topo do body
- [ ] `client_detail_screen.dart`: `SizedBox(height: kFabSafeArea)` adicionado ao fim do scrollable
- [ ] `agenda_month_page.dart`: `kFabSafeArea` verificado (adicionado se ausente)
- [ ] `flutter analyze` → 0 errors
- [ ] `arch_check.sh` → Exit 0

**Dashboard alterado?** NÃO
**Outros módulos alterados?** NÃO
**Navegação mudou?** SIM — botão de retorno virou ação semântica (intencional e documentado)
**Contrato alterado?** NÃO
**Apenas os arquivos alvo foram afetados?** SIM

---

## 8. ENCERRAMENTO PADRÃO

O `client_detail_screen` foi corrigido: botão de retorno genérico substituído por ação semântica "← Clientes" no body da tela.
A área exclusiva do SmartButton foi garantida nos arquivos afetados.
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.
