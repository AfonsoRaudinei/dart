# loja-verificar-compra

Valida compra **StoreKit** (iOS) ou **Play Billing** (Android) e grava `user_plans` com service role. O app Flutter só chama esta função após o fluxo nativo da loja.

## Endpoint

`POST /functions/v1/loja-verificar-compra`

Headers: `Authorization: Bearer <supabase_jwt>`

Body JSON:

```json
{
  "platform": "ios",
  "productId": "soloforte_plano_bronze",
  "transactionId": "2000000123456789",
  "verificationData": "<receipt ou purchase token>"
}
```

Android: `platform` = `android`, `verificationData` = purchase token; `transactionId` pode ser placeholder — o servidor usa `orderId` da Play.

## Respostas

| HTTP | status / error | Significado |
|---|---|---|
| 200 | `granted` | Plano inserido |
| 200 | `already_granted` | Mesmo `payment_id`, mesmo usuário |
| 200 | `other_account` | Transação já pertence a outro `user_id` |
| 400 | vários | Recibo inválido, produto errado, conta não bate |
| 401 | — | JWT ausente ou inválido |
| 502 | `apple_http_error` / `google_http_error` | Loja respondeu erro (ex.: transação inexistente) |
| 503 | `apple_not_configured` / `google_not_configured` | Falta secret no projeto |

## Secrets (Supabase)

- `APPLE_IAP_ISSUER_ID`, `APPLE_IAP_KEY_ID`, `APPLE_IAP_PRIVATE_KEY`
- `APPLE_BUNDLE_ID` (opcional, default `com.soloforte.soloforteApp`)
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` — JSON da service account
- `GOOGLE_PLAY_PACKAGE_NAME` (opcional, default `com.soloforte.app`)

## Deploy

Na raiz do repo:

```bash
./tool/deploy_loja_verificar_compra.sh
```

Ou:

```bash
supabase functions deploy loja-verificar-compra
```

## Testes locais

```bash
deno test --allow-env supabase/functions/loja-verificar-compra/process_store_purchase_test.ts
```

## Catálogo

Ver `store_plan_catalog.ts` — prazos 3, 6, 12 meses.
