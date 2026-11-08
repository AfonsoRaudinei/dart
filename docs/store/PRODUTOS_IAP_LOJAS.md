# Produtos IAP — SoloForte

Use os **mesmos Product IDs** na App Store e na Play Console.

| ID | Plano | Prazo na conta | Referência BRL |
|---|---|---|---|
| `soloforte_plano_bronze` | Bronze | 3 meses | R$ 49,90 |
| `soloforte_plano_prata` | Prata | 6 meses | R$ 79,90 |
| `soloforte_plano_ouro` | Ouro | 12 meses | R$ 119,90 |

O preço cobrado é o cadastrado na loja. O app mostra o texto devolvido pela loja (`ProductDetails.price`).

---

## Apple App Store Connect

- App: **SoloForte** · Bundle `com.soloforte.soloforteApp`
- Tipo: **Non-Renewing Subscription** (In-App Purchases — prazo fixo 3/6/12 meses, **sem** renovação automática e **sem** Subscription Group)
- Duração na ficha Apple: 3 meses / 6 meses / 12 meses (escolhas permitidas pela Apple)

**Nome de exibição (sugestão)**

- Bronze — 3 meses de plano SoloForte
- Prata — 6 meses de plano SoloForte
- Ouro — 12 meses de plano SoloForte

**Descrição (sugestão, PT-BR)**

> Libera publicação de cases de marketing no mapa conforme o plano SoloForte, pelo prazo indicado. A validade começa após a confirmação da compra na sua conta.

---

## Google Play Console

- App: `com.soloforte.app`
- Tipo: **Produto único** (in-app product), **consumível** — permite nova compra quando o prazo expirar

**Título e descrição:** iguais às sugestões Apple, adaptadas ao limite de caracteres da Play.

---

## O que o servidor grava

Após recibo válido e mesma conta (`appAccountToken` / `obfuscatedExternalAccountId` = usuário logado):

- `user_plans.plano` = bronze | prata | ouro
- `user_plans.origem` = `pagamento`
- `user_plans.payment_id` = ID da transação Apple ou `orderId` Google
- `user_plans.expira_em` = agora + 3, 6 ou 12 meses (UTC)
