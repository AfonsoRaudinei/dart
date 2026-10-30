# Prompt 6a — Remover sentinela `clientId 'SELF'` (drawing)

**Módulo:** `lib/modules/drawing/`  
**Branch:** `cursor/fix-drawing-client-id-self` (a partir de `origin/main`)  
**ADR/contrato:** não alterar schema; não gravar `cliente_id` fictício.

## PASSO 0

```bash
rg -n "'SELF'" lib/modules/drawing/
find lib/modules/drawing -name 'drawing_sheet*.dart'
```

## Objetivo

Eliminar `'SELF'` nos dois call sites. **Política (Raudinei): bloquear** sem cliente selecionado — **não inventar texto novo**; reutilizar mensagem já usada no sheet:

- `SnackBar(content: Text('Selecione o Cliente primeiro'))` (já em `drawing_sheet_builders_b.dart` ~670)

## Escopo fechado

1. `lib/modules/drawing/presentation/widgets/drawing_sheet.dart` — `_submitReview`: se `_selectedClient?.id == null`, mostrar o SnackBar acima e **return** (não chamar `addFeaturesFromGeometry` com sentinela).
2. `lib/modules/drawing/presentation/widgets/drawing_sheet_builders_b.dart` — diálogo criar fazenda: se `_selectedClient?.id == null`, return com o mesmo SnackBar; **remover** `'SELF'` e TODO.
3. Teste: `test/modules/drawing/drawing_client_self_sentinel_regression_test.dart` (ou estender teste existente) — garante que fluxo documentado não referencia `'SELF'` (`rg` no módulo drawing) e, se viável, widget test mínimo de bloqueio no submit sem cliente.

## Contagem fazendas com `cliente_id = 'SELF'`

No corpo do PR, reportar:

```sql
SELECT COUNT(*) FROM farms WHERE cliente_id = 'SELF' AND deleted_at IS NULL;
```

Executor: buscar no repo testes/fixtures se há seed com SELF; **sem DB do usuário**, escrever no PR: *contagem em dados reais = consulta local no aparelho ou Supabase (leitura) — NÃO VERIFICADO neste PR* se não houver fixture.

## Proibido

- `git add -A` · merge · `pop()` · cross-module consultoria direto · texto de erro novo

## Validação (saída crua)

```bash
flutter analyze --fatal-infos lib/
flutter test test/modules/drawing/
./tool/arch_check.sh
git diff --stat origin/main..HEAD
```

## Entrega

Push branch + `gh pr create` — **não mergear**.
