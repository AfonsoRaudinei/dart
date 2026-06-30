# AUDIT — marketing/ — Foto e Publicação
**Agente:** Engenheiro Sênior Flutter/Dart — Clean Architecture Riverpod
**Sessão:** READ-ONLY completa antes de qualquer alteração
**Objetivo:** Mapear causa raiz do bloqueio em foto (image_picker) e publicação (publishCase) no NovoCaseSheet

---

## STEP 0 — Localizar todos os arquivos relevantes

```bash
find lib/ -name "novo_case_sheet.dart"
find lib/ -name "marketing_case.dart"
find lib/ -name "marketing_providers.dart"
find lib/ -name "marketing_repository*.dart"
find lib/ -name "marketing_case_repository*.dart"
find lib/ -name "i_marketing*.dart"
find lib/ -name "marketing_database*.dart"
find lib/ -name "marketing_supabase*.dart"
find lib/ -name "marketing_remote*.dart"
```

Copie o resultado completo antes de avançar.

---

## STEP 1 — Ler NovoCaseSheet completo

Leia `novo_case_sheet.dart` inteiro. Identifique:

### 1A — Bloco de foto
- Qual método é chamado ao tocar na área de foto?
- `image_picker` está sendo instanciado diretamente ou via interface?
- O resultado do picker é armazenado em `setState` local ou em provider?
- Existe tratamento de `null` quando o usuário cancela o picker?
- O path da foto é passado para o `MarketingCase` antes de chamar `onPublicar`?
- Existe validação que bloqueia publicação se `fotos` está vazio?

### 1B — Botão Publicar
- O botão "Publicar Case" chama `onPublicar(case)` diretamente?
- Existe validação de formulário antes de chamar `onPublicar`?
- Existe `try/catch` ao redor de `onPublicar`?
- O erro é exibido ao usuário ou engolido silenciosamente?
- O `MarketingCase` montado no momento de publicar tem `fotos` preenchido?

### 1C — Estado do formulário
- Os campos obrigatórios (`produtorFazenda`, `produtoUtilizado`, `localizacaoTexto`) estão sendo lidos de `TextEditingController` ou de state?
- Existe dispose correto dos controllers?

---

## STEP 2 — Ler marketing_providers.dart

Leia o arquivo completo. Identifique:

- `publishCase(MarketingCase)` — o que faz exatamente?
- Existe tratamento de erro com feedback para a UI?
- O `syncStatus` é definido como `pending_sync` antes de gravar local?
- O método grava no banco **antes** de tentar o Supabase? (offline-first)
- Existe `retryPendingCases`? Está sendo chamado em algum momento?

---

## STEP 3 — Ler repositório local (database)

Leia o repositório de persistência local do marketing. Identifique:

- O método `insertCase` / `saveCase` existe?
- Ele grava o campo `fotos` (List<String>) corretamente? (JSON encode/decode?)
- Existe migration que cria a tabela `marketing_cases` no `database_helper.dart`?

Execute:
```bash
grep -n "marketing" lib/core/database/database_helper.dart | head -40
grep -n "fotos" lib/modules/marketing/ -r
grep -n "image_picker" lib/modules/marketing/ -r
```

---

## STEP 4 — Verificar permissões e configuração do image_picker

Execute:
```bash
grep -r "image_picker" pubspec.yaml
grep -r "NSPhotoLibraryUsageDescription" ios/Runner/Info.plist
grep -r "NSCameraUsageDescription" ios/Runner/Info.plist
grep -r "photo_library" ios/Runner/Info.plist
```

⚠️ Se as chaves `NSPhotoLibraryUsageDescription` ou `NSCameraUsageDescription` estiverem ausentes no `Info.plist` → **essa é a causa do crash silencioso no iOS.**

---

## STEP 5 — Verificar integração Supabase do marketing

Execute:
```bash
find lib/ -name "*.dart" | xargs grep -l "supabase" | grep -i marketing
find lib/ -name "*.dart" | xargs grep -l "marketing_cases" 2>/dev/null
```

Leia o serviço/repositório remoto. Identifique:
- A tabela `marketing_cases` existe no Supabase?
- O upload de foto está tentando ir para um Supabase Storage bucket?
- O bucket existe e tem RLS configurada?
- O upload retorna erro que está sendo engolido?

---

## STEP 6 — Montar relatório de achados

Ao final da leitura, monte um relatório com este formato exato:
```
ACHADO-01: [arquivo] linha [N] — [descrição do problema]
ACHADO-02: [arquivo] linha [N] — [descrição do problema]
...
```

Classifique cada achado:
- 🔴 BLOQUEANTE — impede foto ou publicação de funcionar
- 🟡 RISCO — pode causar problema em edge case
- 🟢 OK — funcionando corretamente

**NÃO altere nenhum arquivo neste step.**

---

## REGRAS ABSOLUTAS DESTA AUDITORIA

❌ Não alterar nenhum arquivo
❌ Não refatorar nada
❌ Não criar novos providers
❌ Não mover arquivos
✅ Apenas ler, executar greps e reportar achados
✅ Reportar linha exata de cada problema
✅ Se encontrar código que engole exceção (catch vazio ou catch com apenas print) → marcar 🔴

---

## GATE: aguardar aprovação antes de qualquer fix

Após entregar o relatório de achados → PARAR.
Bom revisará cada achado e aprovará os fixes individualmente.
