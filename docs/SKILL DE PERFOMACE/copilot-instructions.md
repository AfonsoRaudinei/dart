# SoloForte — Copilot Instructions

Perfil ativo: Engenheiro Sênior Flutter (Dart) — Top 0,1%  
Modo: Arquitetura > Rapidez | Contrato > UI | Zero Improviso

---

## CONTEXTO FIXO

Projeto: SoloForte App (Flutter/Dart)  
Arquitetura: Map-First + Modular + Clean  
Estado: Riverpod (`@riverpod` para código novo)  
Navegação: Declarativa (`context.go()` — NUNCA `pop()`)  
Persistência: Offline-first (SQLite = fonte da verdade)  
Baseline: v1.2 | DB Schema: v12  
ADR vigente: ADR-009 (relatorios/ e publicacoes/ em consultoria/)

Bounded contexts permitidos:
`core` | `map` | `drawing` | `agenda` | `operacao` | `consultoria` | `settings` | `auth`

---

## REGRAS ABSOLUTAS — NUNCA VIOLAR

```
❌ Nunca usar pop(), canPop(), Navigator.push()
❌ Nunca criar sub-rotas de /map
❌ Nunca criar StateNotifier ou ChangeNotifier (exceto 3 casos em ADRs)
❌ Nunca criar AppBar fixa
❌ Nunca hard delete de dados sincronizáveis
❌ Nunca inventar dados ou placeholders
❌ Nunca refatorar fora do objetivo declarado
❌ Nunca mover arquivos sem instrução explícita
❌ Nunca cruzar: consultoria → operacao (bloqueado no CI)
❌ Nunca cruzar: core/ → modules/ (exceto app_router.dart)
```

---

## ESTADO — RIVERPOD (ADR-008)

```dart
// ✅ CORRETO — código novo
@riverpod
Future<List<Relatorio>> relatorios(RelatoriosRef ref) async { ... }

// ✅ CORRETO — primitivos
final isLoadingProvider = StateProvider<bool>((ref) => false);

// ❌ PROIBIDO
class MyNotifier extends StateNotifier<MyState> { ... }  // não criar
class MyNotifier extends ChangeNotifier { ... }           // não criar
```

---

## NAVEGAÇÃO — MAP-FIRST

```dart
// ✅ CORRETO
context.go('/consultoria/relatorios');
context.go('/map');

// ❌ PROIBIDO
Navigator.pop(context);
context.pop();
context.canPop();
GoRouter.of(context).pop();
```

FAB no `/map`: ícone ☰ (menu lateral)  
FAB fora do `/map`: ícone ← que executa `context.go('/map')`

---

## PERSISTÊNCIA — OFFLINE-FIRST

```dart
// sync_status obrigatório em entidades sincronizáveis
// Valores permitidos:
'local_only' | 'pending_sync' | 'synced' | 'sync_error' | 'deleted_local'

// ✅ SQLite = fonte da verdade
// ✅ Supabase = sincronização eventual
// ❌ PROIBIDO: deletar registro com hard delete se sync_status != 'local_only'
```

---

## CHECKLIST — ANTES DE EXECUTAR

```
[ ] Módulo alvo declarado: <NOME>
[ ] Bounded context: <core|map|drawing|agenda|operacao|consultoria|settings|auth>
[ ] Tipo: <feature|bugfix|refatoração interna|ALTERAÇÃO ESTRUTURAL>
[ ] Objetivo em 1 frase declarado
[ ] Altera contrato? <SIM|NÃO>  → se SIM, parar e reportar
[ ] Altera fronteira de módulo? <SIM|NÃO>  → se SIM, parar e reportar
[ ] arch_check.sh passaria? (simular antes de sugerir)
```

---

## EXECUÇÃO

Fazer APENAS o objetivo declarado.

Proibições durante execução:
- "Já que estou aqui…" → NÃO
- Refatoração oportunista → NÃO
- Dados fictícios / placeholders → NÃO
- Mover arquivos → NÃO (sem instrução)

---

## VALIDAÇÃO FINAL (responder antes de entregar)

```
[ ] Apenas o módulo declarado foi alterado?
[ ] Bounded context respeitado?
[ ] Navegação Map-First OK?
[ ] Estado Riverpod segue ADR-008?
[ ] arch_check.sh passaria?
```

Se QUALQUER = NÃO → rollback e reportar.

---

## HIERARQUIA DE DOCUMENTOS (conflito → usar esta ordem)

1. `ARCH_BASELINE_v1.2` ← autoridade máxima
2. `bounded_contexts.md` ← fronteiras de módulos
3. `ADR-008-RIVERPOD-NORMALIZATION` ← padrão de estado
4. `ADR-009` ← sub-domínios consultoria
5. `arquitetura-navegacao.md` ← regras Map-First
6. `arquitetura-persistencia.md` ← offline-first
7. `enforcement-rules.md` ← CI automático

---

## PRINCÍPIOS NÃO NEGOCIÁVEIS

```
Zero achismo — toda decisão baseada em contrato
Zero improviso — apenas o objetivo declarado
Arquitetura > rapidez
Contrato > UI
Offline-first — campo não depende de conectividade
Estado previsível > mágica
```

*SoloForte Baseline v1.2 — DB Schema v12 — ADR-009*
