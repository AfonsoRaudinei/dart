# PROMPT — TESTES PASSO 3: Use Case de Publicações + Modelo Snapshot
# Executar em: Antigravity / Cursor / Copilot
# Módulo alvo: test/modules/consultoria/publicacoes/ e test/modules/consultoria/relatorios/models/
# Tipo: testes de domínio
# Pré-requisito: PASSO 1 concluído (helpers disponíveis)

---

## ARQUIVO 1

**Criar em:**
`test/modules/consultoria/publicacoes/use_cases/create_publicacao_use_case_test.dart`

**Setup:**
```dart
late FakePublicacaoRepository repo;
late CreatePublicacaoUseCase useCase;

setUp(() {
  repo = FakePublicacaoRepository();
  useCase = CreatePublicacaoUseCase(repository: repo);
});
```

**Grupos e cenários a cobrir:**

### group('Happy Path')
```
✅ cria publicação com dados válidos
✅ retorna PublicacaoTecnica com id não vazio
✅ syncStatus == local_only após criação
✅ titulo é salvo com .trim() aplicado
✅ conteudo é salvo com .trim() aplicado
✅ tema é preservado corretamente
✅ safra é preservada quando fornecida
✅ safra é null quando não fornecida
✅ authorId é preservado
✅ publicação persiste no repositório (repo.get(id) != null)
```

### group('Validações — ArgumentError esperado')
```
✅ titulo vazio ('') → lança ArgumentError
✅ titulo só espaços ('   ') → lança ArgumentError
✅ conteudo vazio ('') → lança ArgumentError
✅ conteudo só espaços ('   ') → lança ArgumentError
✅ mensagem do ArgumentError menciona o campo inválido
```

### group('Invariantes')
```
✅ dois inputs idênticos geram IDs diferentes
✅ createdAt é preenchido na criação
✅ updatedAt == createdAt na criação
✅ titulo com espaços nas bordas é salvo sem eles
```

### group('Falha de persistência')
```
✅ repo.throwOnNextWrite = true → lança Exception
✅ repositório permanece vazio após falha
```

---

## ARQUIVO 2

**Criar em:**
`test/modules/consultoria/relatorios/models/visit_session_snapshot_test.dart`

**O que testar:**
O `VisitSessionSnapshot` é um DTO de fronteira (ADR-009).
Deve ser serializado/deserializado sem perda de dados.

**Grupos e cenários a cobrir:**

### group('Serialização — toMap / fromMap round-trip')
```
✅ snapshot completo → toMap() → fromMap() → igual ao original
✅ snapshot com ocorrencias vazias → round-trip preserva lista vazia
✅ snapshot com talhoes vazios → round-trip preserva lista vazia
✅ snapshot com fotos vazias → round-trip preserva lista vazia
✅ datas são preservadas sem perda de precisão
```

### group('Imutabilidade — copyWith')
```
✅ copyWith() sem parâmetros → retorna objeto equivalente
✅ copyWith(farmName: 'x') → farmName muda, resto preservado
✅ copyWith(ocorrencias: [...]) → lista nova, resto preservado
✅ objeto original não é mutado após copyWith
```

### group('Invariantes')
```
✅ sessionId não pode ser vazio (se tiver validação)
✅ finishedAt >= startedAt (se tiver validação)
✅ snapshot com ocorrencias não-vazias preserva todos os campos de cada OcorrenciaSnapshot
```

---

## VALIDAÇÃO FINAL

- [ ] `create_publicacao_use_case_test.dart` — todos os grupos implementados
- [ ] `visit_session_snapshot_test.dart` — round-trip e copyWith cobertos
- [ ] `flutter test test/modules/consultoria/` → todos verdes
- [ ] Nenhum arquivo de produção alterado
- [ ] Cobertura estimada: ≥ 80% dos use cases de consultoria/
