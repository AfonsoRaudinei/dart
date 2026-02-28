# PROMPT — PASSO 1: Providers Riverpod
# Agente: GitHub Copilot / Antigravity / Cursor
# Módulo: consultoria
# Tipo: feature
# Bounded context: consultoria (sem nova fronteira)
# arch_check.sh: deve continuar passando — nenhum import proibido

---

## CONTEXTO

O projeto já possui (ADR-009 implementado):
- `lib/modules/consultoria/relatorios/repositories/i_relatorio_repository.dart`
- `lib/modules/consultoria/relatorios/repositories/relatorio_repository_impl.dart`
- `lib/modules/consultoria/relatorios/models/relatorio_tecnico.dart`
- `lib/modules/consultoria/relatorios/models/relatorio_status.dart`
- `lib/modules/consultoria/publicacoes/repositories/i_publicacao_repository.dart`
- `lib/modules/consultoria/publicacoes/repositories/publicacao_repository_impl.dart`
- `lib/modules/consultoria/publicacoes/providers/publicacao_repository_provider.dart`
- `lib/modules/consultoria/publicacoes/models/publicacao_tecnica.dart`
- `lib/modules/consultoria/publicacoes/models/publicacao_tema.dart`
- `lib/modules/consultoria/publicacoes/use_cases/create_publicacao_use_case.dart`

---

## OBJETIVO

Criar dois arquivos de providers Riverpod seguindo ADR-008 (padrão @riverpod canônico).

---

## ARQUIVO 1

**Destino:** `lib/modules/consultoria/relatorios/providers/relatorio_providers.dart`

**Regras:**
- Usar `@Riverpod(keepAlive: true)` para o repository provider
- Usar `@riverpod` (autoDispose) para os providers de lista e detalhe
- NÃO criar StateNotifier nem ChangeNotifier
- Seguir exatamente o padrão de `publicacao_repository_provider.dart` já existente

**Providers a criar:**

```
relatorioRepositoryProvider → IRelatorioRepository
  keepAlive: true
  retorna: RelatorioRepositoryImpl()

relatoriosListProvider(String clientId) → Future<List<RelatorioTecnico>>
  autoDispose
  chama: ref.watch(relatorioRepositoryProvider).listByClient(clientId)

relatorioDetailProvider(String id) → Future<RelatorioTecnico?>
  autoDispose
  chama: ref.watch(relatorioRepositoryProvider).findById(id)
```

---

## ARQUIVO 2

**Destino:** `lib/modules/consultoria/publicacoes/providers/publicacao_providers.dart`

**Regras:**
- NÃO recriar `publicacaoRepositoryProvider` — já existe em `publicacao_repository_provider.dart`
- Importar de lá
- Usar `@riverpod` para lista e detalhe
- Criar `PublicacaoFormNotifier` com `@riverpod` para estado efêmero do formulário

**Providers a criar:**

```
publicacoesListProvider(PublicacaoTema? tema) → Future<List<PublicacaoTecnica>>
  autoDispose
  chama: ref.watch(publicacaoRepositoryProvider).listPublicas(tema: tema)

publicacaoDetailProvider(String id) → Future<PublicacaoTecnica?>
  autoDispose
  chama: ref.watch(publicacaoRepositoryProvider).findById(id)

PublicacaoFormNotifier → @riverpod class
  autoDispose
  state: PublicacaoFormState (classe imutável com copyWith)
  métodos: setTema, setTitulo, setConteudo, addFoto, removeFoto, setTalhaoRef, setSafra
  getter: bool isValid (titulo e conteudo não vazios + tema não nulo)
```

**PublicacaoFormState campos:**
```dart
PublicacaoTema? tema
String titulo = ''
String conteudo = ''
List<String> fotoPaths = []
String? talhaoRef
String? safra
bool isSubmitting = false
String? errorMessage
```

---

## APÓS CRIAR OS ARQUIVOS

Executar:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Verificar que não há erros de compilação antes de prosseguir para o PASSO 2.

---

## VALIDAÇÃO FINAL

- [ ] Nenhum módulo além de `consultoria` foi alterado
- [ ] Nenhum provider global existente foi modificado
- [ ] ADR-008 respeitado (sem StateNotifier novo, sem ChangeNotifier novo)
- [ ] `arch_check.sh` passaria: nenhum import de `operacao/` ou `drawing/` em `consultoria/`
