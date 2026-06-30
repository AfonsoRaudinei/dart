# PRD — Correção SUPABASE_URL no TestFlight
## SoloForte App · Bugfix · Prioridade: CRÍTICA

---

## DECLARAÇÃO OBRIGATÓRIA

| Campo | Valor |
|---|---|
| Módulo alvo | `core` (infraestrutura — AppConfig + build scripts) |
| Bounded context | `core` |
| Tipo | bugfix |
| Arquivo(s) tocado(s) | `build_testflight.sh`, `lib/core/config/app_config.dart` |
| Altera contrato? | NÃO |
| Altera fronteira entre módulos? | NÃO |
| Risco | Baixo — mudança restrita à camada de configuração |

---

## OBJETIVO

Garantir que `SUPABASE_URL` e `SUPABASE_ANON_KEY` sejam corretamente
injetados via `--dart-define` durante o build do TestFlight, eliminando
o erro `Bad state: [AppConfig] SUPABASE_URL não configurada`.

---

## DIAGNÓSTICO DO PROBLEMA

O erro ocorre em `lib/core/config/app_config.dart` (ou equivalente),
onde a leitura das variáveis via `String.fromEnvironment()` retorna
string vazia porque o `flutter build ipa` foi executado **sem** os
flags `--dart-define`.

**Causa raiz:** `build_testflight.sh` não está passando os
`--dart-define` corretamente, ou as variáveis de ambiente do shell
não estão populadas no momento do build.

---

## PASSO 1 — DIAGNÓSTICO (EXECUTAR PRIMEIRO)

Antes de alterar qualquer arquivo, execute no terminal:

```bash
# Verificar o conteúdo atual do script
cat build_testflight.sh

# Verificar se as variáveis estão disponíveis no shell
echo "SUPABASE_URL: $SUPABASE_URL"
echo "SUPABASE_ANON_KEY: $SUPABASE_ANON_KEY"
```

**Identifique qual cenário se aplica:**

- **Cenário A:** O script não tem `--dart-define` algum → ir para PASSO 2A
- **Cenário B:** O script tem `--dart-define` mas as variáveis estão vazias → ir para PASSO 2B
- **Cenário C:** O script tem tudo correto mas o build falha → ir para PASSO 2C

---

## PASSO 2A — Corrigir `build_testflight.sh` (sem dart-define)

Substitua o conteúdo de `build_testflight.sh` por:

```bash
#!/bin/bash
set -e

# ============================================================
# SoloForte — Build TestFlight
# Variáveis obrigatórias (definir antes de executar):
#   export SUPABASE_URL=https://SEU_PROJETO.supabase.co
#   export SUPABASE_ANON_KEY=SUA_CHAVE_ANON
# ============================================================

# Validação de variáveis obrigatórias
if [ -z "$SUPABASE_URL" ]; then
  echo "❌ ERRO: SUPABASE_URL não definida."
  echo "Execute: export SUPABASE_URL=https://SEU_PROJETO.supabase.co"
  exit 1
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ ERRO: SUPABASE_ANON_KEY não definida."
  echo "Execute: export SUPABASE_ANON_KEY=SUA_CHAVE"
  exit 1
fi

echo "✅ SUPABASE_URL: $SUPABASE_URL"
echo "✅ SUPABASE_ANON_KEY: [configurada]"
echo ""
echo "🔨 Iniciando build IPA para TestFlight..."

flutter build ipa \
  --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo ""
echo "✅ Build concluído com sucesso."
echo "📦 Arquivo: build/ios/ipa/*.ipa"
```

Torne o script executável:

```bash
chmod +x build_testflight.sh
```

---

## PASSO 2B — Definir variáveis antes de executar o build

As variáveis precisam estar no ambiente **antes** de chamar o script.
Execute no terminal (substitua pelos valores reais):

```bash
export SUPABASE_URL=https://SEU_PROJETO.supabase.co
export SUPABASE_ANON_KEY=SUA_CHAVE_ANON_AQUI

./build_testflight.sh
```

**Alternativa permanente** — criar um arquivo `.env.local` (nunca
commitar no git):

```bash
# .env.local (adicionar ao .gitignore)
export SUPABASE_URL=https://SEU_PROJETO.supabase.co
export SUPABASE_ANON_KEY=SUA_CHAVE_ANON_AQUI
```

E no topo do `build_testflight.sh`, antes de tudo:

```bash
# Carregar variáveis locais se existirem
if [ -f ".env.local" ]; then
  source .env.local
  echo "📋 Variáveis carregadas de .env.local"
fi
```

---

## PASSO 2C — Verificar `app_config.dart`

Abra `lib/core/config/app_config.dart` e confirme que a leitura está
correta:

```dart
// ✅ CORRETO — leitura via dart-define
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);
```

Se houver `defaultValue` apontando para uma URL hardcoded (ex:
`defaultValue: 'https://...'`), isso mascara o erro em dev mas falha
em prod. Mantenha `defaultValue: ''` e deixe a validação acontecer.

---

## PASSO 3 — Verificar `.gitignore`

Confirme que as chaves nunca entram no repositório:

```bash
# Verificar se .env.local está ignorado
cat .gitignore | grep env

# Se não estiver, adicionar:
echo ".env.local" >> .gitignore
echo "*.env" >> .gitignore
```

---

## PASSO 4 — Executar o build corrigido

```bash
# 1. Definir variáveis (se não usar .env.local)
export SUPABASE_URL=https://SEU_PROJETO.supabase.co
export SUPABASE_ANON_KEY=SUA_CHAVE_ANON_AQUI

# 2. Limpar build anterior (recomendado após mudar dart-define)
flutter clean

# 3. Buscar dependências
flutter pub get

# 4. Executar o build
./build_testflight.sh
```

> ⚠️ IMPORTANTE: Sempre execute `flutter clean` depois de alterar
> `--dart-define`. Os valores são compilados no binário e o cache
> pode manter os valores antigos (vazios).

---

## PASSO 5 — Validação local antes do upload

Execute o app localmente com os defines para confirmar que não há erro:

```bash
flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

O app deve inicializar sem a tela preta de erro.

---

## PASSO 6 — Upload para TestFlight

Após build bem-sucedido:

```bash
# Verificar se o IPA foi gerado
ls build/ios/ipa/

# Usar Apple Transporter ou Xcode Organizer para upload
# (conforme fluxo já estabelecido no projeto)
```

---

## CONTRATO DE DADOS

| Campo | Valor |
|---|---|
| Entidade | `AppConfig` (configuração de inicialização) |
| Campos obrigatórios | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| Campos opcionais | Nenhum |
| Validação | Fail-fast no startup: lançar erro se string vazia |
| Fonte da verdade | Variáveis de ambiente do shell no momento do build |
| Impacto retrocompatível | SIM — nenhuma interface de domínio alterada |

---

## VALIDAÇÃO FINAL

Responda NÃO para todas:

| Pergunta | Resposta esperada |
|---|---|
| Dashboard alterado? | NÃO |
| Outros módulos alterados? | NÃO |
| Navegação mudou? | NÃO |
| Tema mudou? | NÃO |
| Contrato de módulo alterado? | NÃO |
| Apenas `core/config` e `build_testflight.sh` foram tocados? | SIM |

Se qualquer resposta divergir → rollback imediato.

---

## ENCERRAMENTO PADRÃO

O módulo `core` (camada de configuração) foi corrigido conforme
solicitado. Nenhum outro módulo, rota, estado ou contrato do SoloForte
foi alterado.

---

*SoloForte App · Baseline v1.2 · DB Schema v12 · 27/02/2026*
