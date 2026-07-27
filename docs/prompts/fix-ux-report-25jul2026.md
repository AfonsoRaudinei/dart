# Prompt de Correção — Relatório de UX · SoloForte
**Sessão de teste:** 25/07/2026  
**Branch base:** `cursor/fix-relatorios-midia-pins-71cf`  
**Device:** iPhone 17 Simulator (iOS)  
**Workflow testado:** Clientes → Carteira (Categorias, Metas, Mercado) → Agenda (criar visita 27/07)

---

## Como usar este prompt

Copie e entregue ao agente de código (Cursor, Claude Code, etc.) cada seção individualmente, ou entregue todas de uma vez com prioridade `CRÍTICO → MODERADO → MELHORIA`.  
Cada item inclui: **arquivo exato**, **linha de referência**, **diagnóstico**, **solução sugerida** e **como verificar**.

---

## 🔴 BUGS CRÍTICOS

---

### B10 — Botão "Salvar" do Valor do Grão inacessível

**Arquivo:** `lib/modules/carteira/presentation/widgets/carteira_metas_tab.dart`  
**Linha de referência:** ~102–135 (widget `Row` com `TextField` + `FilledButton`)

**Diagnóstico:**  
O layout usa `Row` com `Expanded(child: TextField(...))` seguido de `FilledButton`. Quando o teclado virtual sobe, o `FilledButton` fica fora da área visível ou é sobreposto pela área de toque do `TextField` expandido. Na prática, qualquer toque na metade inferior da tela foca o `TextField` em vez de acionar o botão.

**Código atual (trecho):**
```dart
return Row(
  children: [
    Expanded(
      child: TextField(
        controller: _valorGraoController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          prefixText: 'R\$ ',
          hintText: '0,00',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    ),
    const SizedBox(width: 8),
    FilledButton(
      onPressed: _salvandoGrao ? null : _salvarValorGrao,
      child: ...,
    ),
  ],
);
```

**Solução sugerida:**  
1. Adicionar `onFieldSubmitted` no `TextField` para chamar `_salvarValorGrao` ao pressionar "Done" no teclado:
   ```dart
   onFieldSubmitted: (_) => _salvandoGrao ? null : _salvarValorGrao(),
   textInputAction: TextInputAction.done,
   ```
2. Adicionalmente, envolver o `Row` em `Padding` com `bottom` suficiente para garantir que o botão não seja coberto pelo teclado. Ou usar `ResizeToAvoidBottomInset: true` na tela pai.
3. Alternativa mais robusta: mover o botão para baixo do `TextField` (layout `Column`) em vez de ao lado.

**Como verificar:**  
Abrir Carteira → Metas → campo "Valor do grão" → digitar um valor → teclar "Done" ou tocar "Salvar" → deve exibir SnackBar "Valor do grão atualizado".

---

### B11 — Tela Oportunidades (Mercado) é somente leitura

**Arquivo:** `lib/modules/carteira/presentation/screens/carteira_screen.dart`  
**Linha de referência:** ~338+ (classe `_OportunidadesTab`, `_OportunidadesClientesList`)  
**Arquivo relacionado:** `lib/modules/carteira/presentation/screens/oportunidades_detalhe_screen.dart`

**Diagnóstico:**  
A aba "Oportunidades" exibe apenas a lista de clientes e navega para `OportunidadesDetalheScreen` ao tocar. Não há nenhum `FloatingActionButton`, `IconButton` ou gesto para inserir valores de mercado (lançamentos). A tela de detalhe também não exibe opção de adicionar lançamento de forma clara.

**Solução sugerida:**  
1. Em `OportunidadesDetalheScreen`, adicionar um `FloatingActionButton` que abre o `LancamentoFormDialog` (já existente em `lib/modules/carteira/presentation/widgets/lancamento_form_dialog.dart`).
2. Na aba `_OportunidadesTab`, considerar um botão de ação rápida ou instrução visual ("Toque em um cliente para registrar valores de mercado").

**Como verificar:**  
Carteira → Oportunidades → tocar em cliente → deve haver botão para adicionar lançamento → preencher e salvar → valor deve aparecer no card de Oportunidades.

---

### B9 — "Meu Plano · 2 911 872 dias restantes"

**Arquivo:** `lib/modules/planos/domain/entities/user_plan.dart`  
**Linha de referência:** 48–58

**Diagnóstico:**  
O getter `diasRestantes` é calculado corretamente:
```dart
int get diasRestantes => expiraEm.difference(DateTime.now()).inDays;
```
O problema está no **valor padrão de `expiraEm` para o plano free**:
```dart
expiraEm: DateTime(9999),  // linha 49
```
`DateTime(9999).difference(DateTime.now()).inDays` resulta em ~2 911 872. A tela `MeuPlanoScreen` exibe `plano.diasRestantesLabel` sem checar `isIndefinite` antes.

**Arquivo da tela:** `lib/modules/planos/presentation/screens/meu_plano_screen.dart`  
**Linha de referência:** ~100, ~171

**Solução sugerida:**  
Na tela `MeuPlanoScreen`, checar `plano.isIndefinite` antes de exibir o label:
```dart
// Em vez de:
plano.diasRestantesLabel

// Usar:
plano.isIndefinite ? 'Plano ativo' : plano.diasRestantesLabel
```
Ou adicionar a guarda no próprio getter `diasRestantesLabel` em `user_plan.dart`:
```dart
String get diasRestantesLabel {
  if (isIndefinite) return 'Sem data de expiração';
  if (diasRestantes <= 0) return 'Expira hoje';
  if (diasRestantes == 1) return '1 dia restante';
  return '$diasRestantes dias restantes';
}
```

**Como verificar:**  
Menu lateral → tocar no badge do plano → navegar para Meu Plano → deve exibir "Plano ativo" ou "Sem data de expiração" em vez de milhares de dias.

---

## 🟡 BUGS MODERADOS

---

### B1 — Date picker exibido em inglês

**Arquivo:** `lib/main.dart`  
**Linha de referência:** ~342–352 (widget `MaterialApp.router`)

**Diagnóstico:**  
O `MaterialApp.router` não declara `localizationsDelegates` nem `supportedLocales`. O `initializeDateFormatting('pt_BR', null)` (~linha 119) inicializa o `DateFormat` do Intl, mas **não afeta o date picker nativo do Material** (`showDatePicker`), que depende exclusivamente dos delegates de localização do Flutter.

**Solução:**  
1. Adicionar dependência no `pubspec.yaml` se ainda não existir:
   ```yaml
   flutter_localizations:
     sdk: flutter
   ```
2. No `MaterialApp.router` em `main.dart`:
   ```dart
   import 'package:flutter_localizations/flutter_localizations.dart';
   
   MaterialApp.router(
     // ...
     locale: const Locale('pt', 'BR'),
     supportedLocales: const [
       Locale('pt', 'BR'),
       Locale('en', 'US'),
     ],
     localizationsDelegates: const [
       GlobalMaterialLocalizations.delegate,
       GlobalWidgetsLocalizations.delegate,
       GlobalCupertinoLocalizations.delegate,
     ],
   )
   ```

**Como verificar:**  
Agenda → Nova Visita → tocar no campo de data → date picker deve exibir "Selecionar data", "seg., 27 de jul." em português.

---

### B2 — Date picker abre ao tocar em campos adjacentes

**Arquivo:** `lib/modules/agenda/presentation/widgets/visit_form_dialog.dart`  
(ou o widget de formulário que contém o campo de data)

**Diagnóstico:**  
A área de toque do campo de data captura eventos destinados a campos próximos. Provavelmente o `GestureDetector` ou `InkWell` que envolve o campo de data tem padding/margin excessivo, ou o `TextField` com `readOnly: true` + `onTap` ocupa área visual maior do que aparenta.

**Solução sugerida:**  
1. Garantir que o campo de data use `InputDecoration` com `contentPadding` controlado.
2. Adicionar `SizedBox` ou `Padding` explícito entre o campo de data e os campos adjacentes.
3. Verificar se o `onTap` não está em um container pai que engloba múltiplos campos.

**Como verificar:**  
Formulário de Nova Visita → clicar no campo "Título" → o date picker **não** deve abrir. Apenas clicar diretamente no campo de data deve abrir o picker.

---

### B8 — "Nenhuma categoria ativa" sem botão de ação

**Arquivo:** `lib/modules/carteira/presentation/screens/carteira_cliente_screen.dart`  
**Linha de referência:** ~48–50

**Código atual:**
```dart
if (categorias.isEmpty) {
  return const Center(child: Text('Nenhuma categoria ativa.'));
}
```

**Diagnóstico:**  
O estado vazio não oferece nenhum caminho de ação. O usuário fica preso sem saber como adicionar categorias.

**Solução sugerida:**  
Substituir o estado vazio por um componente com CTA:
```dart
if (categorias.isEmpty) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.category_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('Nenhuma categoria ativa'),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Criar categoria'),
          onPressed: () => context.go(AppRoutes.carteira),
          // ou abrir diretamente o CategoriaFormDialog
        ),
      ],
    ),
  );
}
```

**Como verificar:**  
Carteira → tocar em cliente sem categorias → deve exibir botão "Criar categoria" → tocar leva para tela de criação de categoria.

---

### B13 — Calendário mensal não exibe indicadores em dias com eventos

**Arquivo:** `lib/modules/agenda/presentation/widgets/month_calendar_grid.dart`  
**Linha de referência:** ~7–13 (prop `eventsByDay`), ~117–141 (render de dots)

**Diagnóstico:**  
O widget `MonthCalendarGrid` recebe `eventsByDay` e já tem lógica para renderizar dots. Verificar se a tela `AgendaMonthPage` está passando os eventos corretamente para o grid. O provider de eventos pode não estar populado na view mensal, enquanto a view de Planejamento usa um provider diferente que funciona.

**Arquivo da tela:** `lib/modules/agenda/presentation/pages/agenda_month_page.dart`

**Solução sugerida:**  
1. Em `AgendaMonthPage`, verificar o provider que alimenta `eventsByDay` do `MonthCalendarGrid`.
2. Confirmar que o mesmo provider/filtro usado na view Planejamento (que exibe o badge "0/1" corretamente) é usado também para alimentar o `MonthCalendarGrid`.
3. Se o provider usa um range de datas diferente para o mês, garantir que os eventos criados no mês atual entram no range.

**Como verificar:**  
Após criar uma visita para 27/07 → voltar ao calendário mensal de julho → o dia 27 deve exibir um dot/badge indicando que há evento.

---

### B14 — Tocar no card do dia na view Planejamento navega para /map

**Arquivo:** `lib/modules/agenda/presentation/views/agenda_planejamento_view.dart`  
**Linha de referência:** ~66–68 (`_buildDayCard`), ~366 (`onTap`)

**Diagnóstico:**  
O `SmartButton` de nível L1 (definido em `AppRoutes.level1Routes` — `/agenda` é L1) renderiza um botão de volta para `/map`. Na view Planejamento, tocar no card do dia provavelmente não chama `context.go(AppRoutes.agendaDay(day))`, ou a chamada está sendo interceptada pelo `SmartButton` sobreposto na mesma região da tela.

**Solução sugerida:**  
1. No `_buildDayCard`, garantir que o `onTap` chame explicitamente:
   ```dart
   onTap: () => context.go(AppRoutes.agendaDay(day)),
   ```
2. Verificar se o `FloatingActionButton` ou `SmartButton` está sobrepondo a região do card. Ajustar `padding` inferior da lista de cards para não coincidir com a área do FAB.

**Como verificar:**  
Agenda → view Planejamento → tocar em um dia com evento → deve abrir `AgendaDayPage` com os eventos daquele dia, **não** navegar para /map.

---

### B12 — "R$  0" com duplo espaço em Oportunidades

**Arquivo:** `lib/modules/carteira/presentation/screens/oportunidades_detalhe_screen.dart`  
(ou o widget de valor dentro de `_OportunidadesClientesList`)

**Diagnóstico:**  
O formatador de currency usado retorna "R$ 0" com dois espaços. Isso ocorre quando `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')` é usado sem `decimalDigits` explícito, ou quando há um espaço hardcoded concatenado ao símbolo.

**Solução sugerida:**  
```dart
// Usar formatador consistente:
NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
).format(valor)
// Resultado: "R$0,00" — sem espaço duplo
```
Ou, se o espaço é desejado: `'R\$ ${valor.toStringAsFixed(2)}'` (espaço simples explícito).

**Como verificar:**  
Carteira → Oportunidades → valores devem exibir "R$ 0,00" (um espaço) ou "R$0,00" (sem espaço), nunca "R$  0".

---

## 🔵 MELHORIAS SUGERIDAS

---

### M1 — Máscara de telefone ausente

**Arquivo:** `lib/modules/consultoria/clients/presentation/screens/client_form_screen.dart`  
**Campo:** campo `phone` / `telefone`

**Solução:**  
Adicionar máscara `(xx) xxxxx-xxxx` usando o pacote `mask_text_input_formatter` (já comum em projetos Flutter):
```dart
MaskTextInputFormatter(
  mask: '(##) #####-####',
  filter: {'#': RegExp(r'[0-9]')},
)
```

---

### M2 — Campo de cliente no formulário de visita sem autocomplete

**Arquivo:** `lib/modules/agenda/presentation/widgets/visit_form_dialog.dart`  
**Campo:** busca de cliente

**Solução:**  
Implementar `Autocomplete<ClienteModel>` com debounce de ~300ms, alimentado pelo `filteredClientsProvider` existente.

---

### M3 — _DailySummary exibe "--" permanentemente

**Arquivo:** `lib/ui/components/side_menu_overlay_sections.dart`  
**Linha de referência:** ~237–277 (classe `_SummaryMetric`)

**Diagnóstico:**  
O widget `_SummaryMetric` renderiza hardcoded `'--'` sem consultar nenhum provider.

**Solução:**  
Conectar cada métrica ao provider correspondente, ou **remover o componente** até os dados estarem disponíveis. Um estado vazio permanente confunde o usuário e passa impressão de app quebrado.

---

### M4 — SmartButton L1 vai direto ao mapa sem sub-navegação

**Arquivo:** `lib/core/router/app_routes.dart` + SmartButton widget  
**Contexto:** Rotas L1 (`/agenda`, `/carteira`) têm botão de voltar que vai direto para `/map`.

**Sugestão:**  
Para telas L1 com sub-views (Planejamento, Indicadores, abas de Carteira), considerar um botão de menu hambúrguer ou breadcrumb visual ao invés do botão de voltar ao mapa, para não desorientar o usuário que veio de uma sub-tela.

---

### M5 — Card de evento no Planejamento com corpo vazio

**Arquivo:** `lib/modules/agenda/presentation/widgets/day_event_card.dart`

**Diagnóstico:**  
O card mostra o badge "0/1" mas o corpo (título, cliente, horário) aparece vazio ou não visível na view de Planejamento. Verificar se o `DayEventCard` recebe os dados corretos do evento quando `status == planejado`.

**Solução:**  
Garantir que o `DayEventCard` renderiza `event.titulo`, `event.clienteNome` e `event.dataInicioPlanejada` independente do status do evento.

---

## Ordem de prioridade de implementação

| # | ID | Impacto | Esforço |
|---|-----|---------|---------|
| 1 | B11 | Alto — funcionalidade central bloqueada | Médio |
| 2 | B10 | Alto — dado não pode ser salvo | Baixo |
| 3 | B9  | Alto — dado absurdo visível ao usuário | Baixo |
| 4 | B1  | Médio — UX internacional errada | Baixo |
| 5 | B8  | Médio — usuário preso no estado vazio | Baixo |
| 6 | B14 | Médio — navegação inesperada | Baixo |
| 7 | B13 | Médio — calendário não reflete estado | Médio |
| 8 | B2  | Baixo — toque acidental | Baixo |
| 9 | B12 | Baixo — cosmético | Baixo |
| 10| M3  | Baixo — aparência de bug | Baixo |
