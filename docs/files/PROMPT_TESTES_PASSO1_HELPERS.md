# PROMPT — TESTES PASSO 1: Fake Repositories e Helpers
# Executar em: Antigravity / Cursor / Copilot
# Módulo alvo: test/modules/consultoria/helpers/
# Tipo: infraestrutura de testes — NÃO alterar código de produção
# Pré-requisito: nenhum
# Padrão a seguir: test/modules/agenda/helpers/fake_agenda_repository.dart

---

## CONTEXTO

O projeto usa `FakeRepository` em memória como padrão de teste (não mocks).
Referência de padrão: `test/modules/agenda/helpers/fake_agenda_repository.dart`
- Implementa a interface completa
- Usa `Map<String, T>` em memória
- Tem flag `throwOnNextWrite` para simular falha de escrita
- Tem helpers `seedXxx()` para pré-popular estado

---

## OBJETIVO

Criar 3 arquivos de infraestrutura de teste. NÃO criar testes ainda.

---

## ARQUIVO 1

**Criar em:**
`test/modules/consultoria/helpers/fake_relatorio_repository.dart`

**O que fazer:**
Implementar `IRelatorioRepository` completamente em memória.

**Interface a implementar** (todos os métodos):
```
save(RelatorioTecnico) → Future<void>
update(RelatorioTecnico) → Future<void>  ← injeta updatedAt = DateTime.now()
getById(String id) → Future<RelatorioTecnico?>
getAll() → Future<List<RelatorioTecnico>>  ← exclui softDeleted
getByClientId(String) → Future<List<RelatorioTecnico>>
getByAgronomistId(String) → Future<List<RelatorioTecnico>>
getByStatus(RelatorioStatus) → Future<List<RelatorioTecnico>>
getPendingSync() → Future<List<RelatorioTecnico>>  ← local_only + pending_sync + deleted_local
softDelete(String id) → Future<void>  ← preenche deletedAt, não remove do Map
markAsSynced(String id) → Future<void>
markAsPendingSync(String id) → Future<void>
```

**Campos internos:**
```dart
final Map<String, RelatorioTecnico> _store = {};
bool throwOnNextWrite = false;  // simula falha de escrita SQLite
```

**Helpers públicos:**
```dart
// Pré-popula o repositório para setup de testes
void seed(List<RelatorioTecnico> relatorios)

// Acesso direto por ID (para assertions)
RelatorioTecnico? get(String id) => _store[id];

// Conta total incluindo deletados
int get count => _store.length;

// Limpa tudo
void clear() => _store.clear();
```

**throwOnNextWrite:**
Se `true`, o próximo método de escrita (`save`, `update`, `softDelete`,
`markAsSynced`, `markAsPendingSync`) deve lançar `Exception('Simulated write error')`
e resetar `throwOnNextWrite = false`.

---

## ARQUIVO 2

**Criar em:**
`test/modules/consultoria/helpers/fake_publicacao_repository.dart`

**O que fazer:**
Implementar `IPublicacaoRepository` completamente em memória.
Seguir o mesmo padrão do ARQUIVO 1.

**Interface a implementar** (todos os métodos):
```
save(PublicacaoTecnica) → Future<void>
update(PublicacaoTecnica) → Future<void>  ← injeta updatedAt = DateTime.now()
getById(String id) → Future<PublicacaoTecnica?>
getAll() → Future<List<PublicacaoTecnica>>  ← exclui softDeleted
getByAuthorId(String) → Future<List<PublicacaoTecnica>>
getByTema(PublicacaoTema) → Future<List<PublicacaoTecnica>>
getPublicas() → Future<List<PublicacaoTecnica>>  ← visibility == publica
getPendingSync() → Future<List<PublicacaoTecnica>>
softDelete(String id) → Future<void>
markAsSynced(String id) → Future<void>
markAsPendingSync(String id) → Future<void>
```

**Mesmos campos e helpers do ARQUIVO 1** (adaptados para `PublicacaoTecnica`).

---

## ARQUIVO 3

**Criar em:**
`test/modules/consultoria/helpers/consultoria_test_factories.dart`

**O que fazer:**
Criar funções factory para construir objetos de teste com valores padrão.
Seguir padrão de `makeEvent()` e `makeSession()` do `fake_agenda_repository.dart`.

**Factories a criar:**

```dart
// VisitSessionSnapshot com valores válidos e completos
VisitSessionSnapshot makeSnapshot({
  String? sessionId,
  String? clientId,
  String? agronomistId,
  String? farmName,
  DateTime? startedAt,
  DateTime? finishedAt,
  List<OcorrenciaSnapshot>? ocorrencias,
  List<TalhaoVisitado>? talhoes,
})

// RelatorioTecnico com status pendente_revisao por padrão
RelatorioTecnico makeRelatorio({
  String? id,
  String? clientId,
  String? agronomistId,
  String? farmName,
  RelatorioStatus? status,
  RelatorioSyncStatus? syncStatus,
  DateTime? createdAt,
})

// PublicacaoTecnica com dados válidos por padrão
PublicacaoTecnica makePublicacao({
  String? id,
  String? authorId,
  PublicacaoTema? tema,
  String? titulo,
  String? conteudo,
  String? safra,
})
```

Valores padrão devem ser sempre válidos e não-nulos onde o tipo exige.
Usar `const` onde possível.

---

## VALIDAÇÃO FINAL

- [ ] Os 3 arquivos criados em `test/modules/consultoria/helpers/`
- [ ] `FakeRelatorioRepository` implementa todos os 11 métodos de `IRelatorioRepository`
- [ ] `FakePublicacaoRepository` implementa todos os 11 métodos de `IPublicacaoRepository`
- [ ] `throwOnNextWrite` funciona e reseta após uso
- [ ] `dart analyze test/modules/consultoria/helpers/` → 0 erros
- [ ] Nenhum arquivo de produção alterado
