# PROMPT — SoloForte: Criar tabela `relatorios` — Migration v32

## Agente
Engenheiro Sênior Flutter/Dart — Especialista em SQLite/sqflite

## Passo 0 — Obrigatório antes de qualquer ação
```bash
find lib/ -name "database_helper.dart"
grep -n "CREATE TABLE IF NOT EXISTS" lib/core/database/database_helper.dart
grep -n "version:\|onUpgrade\|_migrateToV" lib/core/database/database_helper.dart | head -30
```
Mostre o output ao humano antes de qualquer edição.

## Objetivo
Criar a tabela `relatorios` via `_migrateToV32` em `database_helper.dart`.
Incrementar versão de 31 para 32.

## Contexto confirmado
- Tabela `relatorios` não existe (confirmado por grep)
- `generate_relatorio_use_case.dart` já chama `IRelatorioRepository.save()` — falha silenciosamente por ausência da tabela
- Padrão do projeto: `_onCreate()` chama todas as migrations em sequência — **não duplicar SQL**

## Módulo
`lib/core/database/database_helper.dart` — único arquivo a ser tocado

## Escopo — Proibido alterar
❌ Qualquer outro arquivo
❌ Tabelas existentes
❌ Lógica de migrations anteriores

## Implementação — 3 passos exatos

### Passo 1 — Criar `_migrateToV32`
```dart
Future<void> _migrateToV32(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS relatorios (
      id TEXT PRIMARY KEY NOT NULL,
      session_id TEXT NOT NULL,
      client_id TEXT NOT NULL,
      agronomist_id TEXT NOT NULL,
      farm_name TEXT NOT NULL,
      talhao_id TEXT,
      talhao_name TEXT,
      started_at TEXT NOT NULL,
      finished_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pendente_revisao',
      sync_status TEXT NOT NULL DEFAULT 'local_only',
      title TEXT,
      custom_notes TEXT,
      occurrences_json TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      user_id TEXT NOT NULL
    )
  ''');
}
```

### Passo 2 — Registrar no `onUpgrade` switch
Seguindo o padrão exato das migrations anteriores:
```dart
case 32:
  await _migrateToV32(db);
  break;
```

### Passo 3 — Registrar em `_onCreate`
Seguindo o padrão do projeto onde `_onCreate` chama migrations em sequência:
```dart
await _migrateToV32(db);
```
**Não duplicar o SQL — apenas chamar o método.**

### Passo 4 — Incrementar versão
```dart
version: 32,
```

## Sugestão ao agente
Antes de editar, mostre:
- Trecho atual do `_onCreate` (últimas 3 chamadas de migration)
- Trecho atual do `onUpgrade` switch (últimos 3 cases)

Aguarde aprovação do humano antes de gravar qualquer alteração.

## Validação final
- [ ] `version: 32` no `openDatabase`?
- [ ] `_migrateToV32` criado com `CREATE TABLE IF NOT EXISTS relatorios`?
- [ ] `case 32` registrado no `onUpgrade`?
- [ ] `_migrateToV32` chamado em `_onCreate`?
- [ ] SQL **não** duplicado em `_onCreate`?
- [ ] Nenhum outro arquivo tocado?
- [ ] `flutter analyze` sem novos erros?

## Encerramento
O módulo `core/database` foi ajustado conforme solicitado.
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.
