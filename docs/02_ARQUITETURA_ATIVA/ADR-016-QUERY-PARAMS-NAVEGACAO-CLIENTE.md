# ADR-016 — Query Params Oficiais para Navegação com Contexto de Cliente

**Data:** 02/03/2026  
**Status:** APROVADO — pré-requisito para implementação  
**Autor:** Engenheiro Sênior SoloForte  
**Referência PRD:** PRD_INTEGRACAO_MODULO_CLIENTES v1.1  
**Bloqueia:** WS-4, WS-5  
**Baseline afetada:** ARCH_BASELINE_v1.2 + `arquitetura-namespaces-rotas.md`

---

## 1. CONTEXTO

O Hub do Cliente (WS-4) precisa navegação contextual: ao clicar em "Ver Eventos", "Iniciar Visita" ou "Ver Relatórios", o usuário deve ser levado à tela correspondente com o cliente já pré-selecionado.

Isso requer passar `clienteId` como query param via `context.go()`. Porém, as rotas existentes **não declaram** esses query params oficialmente, o que cria:

1. **Contrato implícito** — outro desenvolvedor não sabe que `/map?modo=visita` existe
2. **Sem validação** — parâmetros são silenciosamente ignorados se digitados errado
3. **Inconsistência** — `modo=desenho` já existe (não documentado), mas `modo=visita` ainda não existe

A REGRA OBRIGATÓRIA DE PROCESSO exige que qualquer rota nova ou extensão de comportamento de rota seja documentada em ADR.

---

## 2. PROBLEMA

```
context.go('/map?modo=visita&clienteId=uuid');         // comportamento NOVO — não declarado
context.go('/map?focusClienteId=uuid');                // comportamento NOVO — não declarado
context.go('/agenda?clienteId=uuid');                  // comportamento NOVO — não declarado
context.go('/consultoria/relatorios?clienteId=uuid');  // comportamento NOVO — não declarado
```

Sem este ADR, os WS-4 e WS-5 adicionariam comportamento implícito não documentado.

---

## 3. DECISÃO

### 3.1 Tabela Oficial de Query Params — Estado Completo

#### Rotas existentes com query params já documentados

| Rota | Param | Tipo | Comportamento |
|------|-------|------|---------------|
| `/map` | `modo=desenho` | `String` | Ativa modo desenho ao carregar |
| `/map` | `clienteId` | `String?` | Pré-seleciona cliente no modo ativo |
| `/agenda/day` | `date` | `String` | Navega para data específica (`yyyy-MM-dd`) |
| `/map/publicacao/edit` | `id` | `String` | ID da publicação a editar |

#### Novas extensões declaradas neste ADR

| Rota | Param | Tipo | Comportamento | Módulo |
|------|-------|------|---------------|--------|
| `/map` | `modo=visita` | `String` | Ativa modo visita ao carregar (equivalente a `modo=desenho`) | `map` / `operacao` |
| `/map` | `focusClienteId` | `String?` | Centraliza o mapa na fazenda principal do cliente informado | `map` |
| `/agenda` | `clienteId` | `String?` | Pré-filtra lista de eventos por cliente; `CreateEventDialog` abre com cliente pré-selecionado | `agenda` |
| `/consultoria/relatorios` | `clienteId` | `String?` | Filtra lista de relatórios por cliente; exibe chip de filtro ativo | `consultoria` |

### 3.2 Regras de Comportamento

```
1. Query params são SEMPRE opcionais
   → Sem o param, a tela funciona normalmente (comportamento atual preservado)
   → Nenhuma rota nova é criada — apenas extensão de comportamento

2. Query params são lidos via GoRouterState
   → final clienteId = GoRouterState.of(context).uri.queryParameters['clienteId'];
   → Validação: se param presente mas UUID inválido, ignorar silenciosamente

3. Pré-seleção é comportamento de UI apenas
   → Não altera estado persistido
   → Não altera a URL quando o usuário desfaz a pré-seleção

4. focusClienteId em /map
   → Busca fazenda principal (farms WHERE cliente_id = ? LIMIT 1 ORDER BY created_at)
   → Se cliente sem fazenda, centraliza em coordenadas default (sem erro)
```

---

## 4. IMPLEMENTAÇÃO — COMO LER OS PARAMS

### `/map` — modo e foco

```dart
// Em PrivateMapScreen ou MapController
class PrivateMapScreen extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final modo = uri.queryParameters['modo'];
      final clienteId = uri.queryParameters['clienteId'];
      final focusClienteId = uri.queryParameters['focusClienteId'];

      if (modo == 'visita') _ativarModoVisita(clienteId: clienteId);
      if (modo == 'desenho') _ativarModoDesenho(clienteId: clienteId);
      if (focusClienteId != null) _centralizarNoCliente(focusClienteId);
    });
  }
}
```

### `/agenda` — filtro por cliente

```dart
// Em AgendaMonthPage
@override
Widget build(BuildContext context) {
  final clienteId = GoRouterState.of(context).uri.queryParameters['clienteId'];
  // Se clienteId != null, filtrar eventos; exibir chip de filtro ativo
}
```

### `/consultoria/relatorios` — filtro por cliente

```dart
// Em RelatoriosScreen
@override
Widget build(BuildContext context) {
  final clienteId = GoRouterState.of(context).uri.queryParameters['clienteId'];
  // Se clienteId != null, aplicar WHERE client_id = ? na query
  // Exibir badge/chip com nome do cliente (via IClientLookup de core/contracts/)
}
```

---

## 5. NAVEGAÇÃO AUTORIZADA DO HUB DO CLIENTE

```dart
// Atalhos em ClientDetailScreen (WS-4)
// ✅ TODOS usam context.go() — Map-First

// + Evento → Agenda com cliente pré-selecionado
context.go('/agenda?clienteId=$clienteId');

// + Visita → Modo visita com cliente
context.go('/map?modo=visita&clienteId=$clienteId');

// + Desenho → Modo desenho com cliente
context.go('/map?modo=desenho&clienteId=$clienteId');

// Ver no Mapa → Centralizar na fazenda principal
context.go('/map?focusClienteId=$clienteId');

// Relatórios → Lista filtrada
context.go('/consultoria/relatorios?clienteId=$clienteId');
```

---

## 6. IMPACTO EM ROTAS E MÓDULOS

| Módulo | Arquivo a alterar | Ação |
|--------|-------------------|------|
| `map` | `PrivateMapScreen` | Ler `modo=visita` e `focusClienteId` |
| `agenda` | `AgendaMonthPage` | Ler `clienteId`, filtrar eventos |
| `consultoria` | `RelatoriosScreen` | Ler `clienteId`, filtrar relatórios |
| `core` | `app_router.dart` | Sem alteração de rotas — apenas comportamento |

**Nenhuma rota nova** é adicionada ao `app_router.dart`. Apenas os handlers das telas existentes passam a consumir os query params opcionais.

---

## 7. CRITÉRIO DE ACEITE

```
[ ] Tabela de query params atualizada em arquitetura-namespaces-rotas.md
[ ] /map responde a modo=visita e focusClienteId
[ ] /agenda filtra por clienteId quando presente
[ ] /consultoria/relatorios filtra por clienteId quando presente
[ ] Sem query param → comportamento atual preservado (zero regressão)
[ ] Validação: param com UUID inválido → ignorado silenciosamente
[ ] arch_check.sh passaria (sem novas rotas, apenas extensão)
```

---

## 8. ALTERNATIVAS REJEITADAS

| Alternativa | Motivo da rejeição |
|-------------|-------------------|
| Rotas dedicadas `/agenda/cliente/:id` | Cria sub-rotas fora do padrão Map-First declarado |
| Estado global (Provider) para "cliente ativo" | Acoplamento silencioso entre telas — rompe previsibilidade |
| Parâmetros de rota (`:clienteId`) nas rotas existentes | Altera contrato de URL — breaking change para deep links existentes |
| Callback via Navigator arguments | Incompatível com go_router declarativo |

---

*SoloForte Baseline v1.2 — ADR-016 — 02/03/2026*
