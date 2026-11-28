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

---

## Checklist: produto aparece no app

O app só mostra preço e botão de compra quando a loja devolve o produto. Se a tela Meu Plano mostrar "Este plano ainda não está disponível na loja", confira esta lista.

### Apple (iOS)

- [ ] **Acordo de Apps Pagos** ativo no App Store Connect, com dados bancários e fiscais aprovados.
- [ ] Os **3 produtos** criados como **Non-Renewing Subscription**, com os IDs exatos: `soloforte_plano_bronze`, `soloforte_plano_prata`, `soloforte_plano_ouro`.
- [ ] Cada produto com **preço** definido e **localização PT-BR** (nome + descrição).
- [ ] Cada produto com **screenshot de revisão** e status **Pronto para Enviar**.
- [ ] Os **primeiros** IAPs precisam ser anexados à versão do app ao enviar para revisão.
- [ ] Bundle `com.soloforte.soloforteApp` com a capability **In-App Purchase** ativa no App ID.
- [ ] Teste com conta **Sandbox** (Ajustes > App Store > Conta Sandbox) ou **TestFlight**.

### Google Play (Android)

- [ ] App `com.soloforte.app` publicado em uma **faixa de teste** (interno, fechado ou aberto).
- [ ] Os 3 produtos (mesmos IDs) como produto único **consumível**, com status **ATIVO**.
- [ ] Teste com **conta licenciada de teste** (Play Console > Configurações > Teste de licença), instalada a partir da faixa de teste.

### Servidor (Edge `loja-verificar-compra`)

- [ ] Secrets configurados no Supabase: `APPLE_IAP_ISSUER_ID`, `APPLE_IAP_KEY_ID`, `APPLE_IAP_PRIVATE_KEY` e `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`.
- [ ] Edge publicada: `./tool/deploy_loja_verificar_compra.sh`.

### Diagnóstico pelo log `LojaCompra`

O app registra a consulta à loja com o nome (tag) `LojaCompra` (Xcode/Console do aparelho em debug/profile, ou DevTools > Logging; em release esses avisos não aparecem):

| Mensagem | O que significa |
|---|---|
| `Loja indisponível neste aparelho (isAvailable=false)` | A loja não respondeu: sem conta da loja, sem rede ou compras bloqueadas no aparelho. |
| `Produtos não encontrados na loja (notFoundIDs): …` | A loja respondeu, mas não conhece esses IDs. Confira ID exato, status do produto, acordo, bundle/pacote e conta de teste. |
| `Consulta de produtos falhou: source=… code=… message=…` | A loja devolveu erro na consulta. Use o código para localizar a causa. |
| `Falha ao consultar a loja: …` | Exceção inesperada na consulta; o app não quebra e oferece "Atualizar planos". |

Depois de corrigir na loja, toque em **Atualizar planos** na tela Meu Plano para consultar de novo, sem reabrir o app. As alterações na loja podem levar alguns minutos para propagar.
