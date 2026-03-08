# PRD — Correção ENV=development no Build TestFlight
## SoloForte App · Bugfix · Prioridade: CRÍTICA

---

## DECLARAÇÃO OBRIGATÓRIA

| Campo | Valor |
|---|---|
| Módulo alvo | `core` (infraestrutura — build scripts) |
| Bounded context | `core` |
| Tipo | bugfix |
| Arquivo(s) tocado(s) | `build_testflight.sh` |
| Altera contrato? | NÃO |
| Altera fronteira entre módulos? | NÃO |
| Risco | Baixo — mudança restrita ao script de build |

---

## OBJETIVO

Corrigir `build_testflight.sh` trocando `--dart-define=ENV=development`
por `--dart-define=ENV=production`, executar `flutter clean` obrigatório,
e fazer rebuild limpo para TestFlight.

---

## CAUSA RAIZ CONFIRMADA

O script `build_testflight.sh` está passando:

```bash
--dart-define=ENV=development   # ❌ ERRADO para TestFlight
```

O `AppConfig` lê `ENV` via `String.fromEnvironment('ENV')` e quando
o valor é `development`, pode estar ativando um caminho de código
diferente — incluindo possivelmente ignorar as chaves de produção ou
usar valores padrão vazios esperando um `.env` local que não existe
no device.

---

## PASSO 1 — Abrir e verificar o script atual

```bash
cat build_testflight.sh
```

Localizar a linha com `--dart-define=ENV=` e confirmar que está
`development`.

---

## PASSO 2 — Corrigir `build_testflight.sh`

Localizar a linha:

```bash
--dart-define=ENV=development \
```

Substituir por:

```bash
--dart-define=ENV=production \
```

O bloco de `flutter build ipa` deve ficar assim:

```bash
flutter build ipa \
  --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENV=production
```

> ❌ NÃO alterar nenhuma outra linha do script.
> ❌ NÃO mover o arquivo.
> ❌ NÃO refatorar lógica existente.

---

## PASSO 3 — Limpar cache (OBRIGATÓRIO)

Após qualquer mudança em `--dart-define`, os valores são compilados
no binário. O cache do Flutter precisa ser descartado:

```bash
flutter clean
flutter pub get
```

Sem este passo o build novo pode empacotar os valores antigos
(`development`) mesmo com o script corrigido.

---

## PASSO 4 — Executar o build corrigido

```bash
./build_testflight.sh
```

Aguardar conclusão. O build deve finalizar sem erro de inicialização.

---

## PASSO 5 — Validação local antes do upload

```bash
flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENV=production
```

Confirmar que o app inicializa sem tela preta e sem o erro
`SUPABASE_URL não configurada`.

---

## PASSO 6 — Upload para TestFlight via Apple Transporter

Após build bem-sucedido:

```bash
ls build/ios/ipa/
```

Fazer upload pelo Apple Transporter conforme fluxo já estabelecido.

---

## CONTRATO DE DADOS

| Campo | Valor |
|---|---|
| Entidade | `AppConfig` |
| Campos | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ENV` |
| Valor correto de `ENV` para TestFlight | `production` |
| Valor correto de `ENV` para dev local | `development` |
| Fonte da verdade | `build_testflight.sh` para prod, `run_dev.sh` para dev |
| Impacto retrocompatível | SIM |

---

## VALIDAÇÃO FINAL

| Pergunta | Resposta esperada |
|---|---|
| Dashboard alterado? | NÃO |
| Outros módulos alterados? | NÃO |
| Navegação mudou? | NÃO |
| Tema mudou? | NÃO |
| Contrato de módulo alterado? | NÃO |
| Apenas `build_testflight.sh` foi tocado? | SIM |

---

## ENCERRAMENTO PADRÃO

O script `build_testflight.sh` foi corrigido: `ENV=development` →
`ENV=production`. Nenhum outro módulo, rota, estado ou contrato do
SoloForte foi alterado.

---

*SoloForte App · Baseline v1.2 · DB Schema v12 · 27/02/2026*
