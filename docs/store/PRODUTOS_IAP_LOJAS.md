# Produtos IAP — SoloForte

Use os **mesmos Product IDs** na App Store e na Play Console.

**Fonte canônica dos valores de cadastro:** [`docs/case.md`](../case.md) (seção Preço). O app não grava esses números — só exibe o que a loja devolver.

| ID | Plano | Prazo na conta | Referência BRL (pagamento único) |
|---|---|---|---|
| `soloforte_plano_bronze` | Bronze | 3 meses | R$ 90,00 |
| `soloforte_plano_prata` | Prata | 6 meses | R$ 300,00 |
| `soloforte_plano_ouro` | Ouro | 12 meses | R$ 960,00 |

Equivalente mensal de produto (copy interna): Bronze R$ 30/mês, Prata R$ 50/mês, Ouro R$ 80/mês — ver `docs/case.md`.

O preço cobrado é o cadastrado na loja. O app mostra o texto devolvido pela loja (`ProductDetails.price`).

**Legado (não usar na loja):** Mercado Pago fora do app — Bronze R$ 49,90 (3 meses), Prata R$ 79,90 (5 meses), Ouro R$ 119,90 (8 meses).

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
