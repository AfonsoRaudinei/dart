# PROMPT — TESTES PASSO 2: Use Cases de Relatórios
# Executar em: Antigravity / Cursor / Copilot
# Módulo alvo: test/modules/consultoria/relatorios/use_cases/
# Tipo: testes de domínio
# Pré-requisito: PASSO 1 concluído (helpers disponíveis)
# Padrão: seguir complete_event_use_case_test.dart de agenda/

---

## CONTEXTO

Use cases a testar:
- `GenerateRelatorioUseCase` — gera relatório a partir de snapshot
- `PublishRelatorioUseCase` — publica relatório pendente

Padrão obrigatório:
- `flutter_test` (não `dart:test`)
- `FakeRelatorioRepository` (sem mocks, sem sqflite_ffi)
- `setUp()` recria instâncias antes de cada teste
- `group()` aninhados por cenário
- Sem `ProviderContainer` — use cases recebem repositório via construtor

---

## ARQUIVO 1

**Criar em:**
`test/modules/consultoria/relatorios/use_cases/generate_relatorio_use_case_test.dart`

**Setup:**
```dart
late FakeRelatorioRepository repo;
late GenerateRelatorioUseCase useCase;

setUp(() {
  repo = FakeRelatorioRepository();
  useCase = GenerateRelatorioUseCase(repository: repo);
});
```

**Grupos e cenários a cobrir:**

### group('Happy Path')
```
✅ gera relatorio com status pendente_revisao
✅ gera relatorio com syncStatus local_only
✅ relatorio.id é UUID v4 não vazio
✅ relatorio.clientId == snapshot.clientId
✅ relatorio.agronomistId == snapshot.agronomistId
✅ relatorio.farmName == snapshot.farmName
✅ relatorio.periodStart == snapshot.startedAt
✅ relatorio.periodEnd == snapshot.finishedAt
✅ relatorio persiste no repositório (repo.get(id) != null)
✅ relatorio.ocorrencias == snapshot.ocorrencias
✅ relatorio.talhoes == snapshot.talhoes
```

### group('Snapshot com campos mínimos')
```
✅ ocorrencias vazia → relatorio.ocorrencias == []
✅ talhoes vazia → relatorio.talhoes == []
✅ fotos vazia → relatorio.fotos == []
```

### group('Invariantes')
```
✅ dois snapshots diferentes geram IDs diferentes
✅ snapshot idêntico chamado duas vezes gera dois relatórios distintos (IDs diferentes)
✅ createdAt e updatedAt são preenchidos na geração
```

### group('Falha de persistência')
```
✅ se repo.throwOnNextWrite = true → lança Exception
✅ repositório permanece sem o relatório após falha
```

---

## ARQUIVO 2

**Criar em:**
`test/modules/consultoria/relatorios/use_cases/publish_relatorio_use_case_test.dart`

**Setup:**
```dart
late FakeRelatorioRepository repo;
late PublishRelatorioUseCase useCase;

setUp(() {
  repo = FakeRelatorioRepository();
  useCase = PublishRelatorioUseCase(repository: repo);
});
```

**Grupos e cenários a cobrir:**

### group('Happy Path')
```
✅ relatório pendente_revisao → publicado com sucesso
✅ retorna RelatorioTecnico com status == publicado
✅ syncStatus muda para pending_sync após publicação
✅ relatório persiste no repositório com novo status
```

### group('Idempotência')
```
✅ relatório já publicado → retorna sem lançar erro
✅ relatório já publicado → status permanece publicado (não regride)
✅ relatório já publicado → não chama update() no repositório
   (repo deve ter count de escritas = 0 após segunda chamada)
```

### group('Validações — erros esperados')
```
✅ id inexistente → lança ArgumentError
✅ relatório arquivado → lança StateError
✅ mensagem do StateError menciona 'arquivado'
```

### group('Invariantes')
```
✅ publishedAt é preenchido na publicação (se o campo existir)
✅ updatedAt é renovado após publicação
✅ clientId e agronomistId não mudam após publicação
```

### group('Falha de persistência')
```
✅ repo.throwOnNextWrite = true → lança Exception
✅ status do relatório não muda após falha (ainda pendente_revisao)
```

---

## VALIDAÇÃO FINAL

- [ ] Todos os grupos e cenários acima implementados
- [ ] Cada teste tem no máximo 1 `expect` por linha (exceto setup)
- [ ] Nenhum teste usa `sqflite_ffi` ou banco real
- [ ] `flutter test test/modules/consultoria/relatorios/` → todos verdes
- [ ] Nenhum arquivo de produção alterado
