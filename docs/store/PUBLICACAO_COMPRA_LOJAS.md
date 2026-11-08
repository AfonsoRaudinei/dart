# Publicação — compra de planos nas lojas

Data: 2026-11-08  
Código na `main`: compra nativa (PR #431). Ordem: **iOS primeiro**, **Android depois**.

Este guia separa o que já está no repositório do que só você faz nas consoles e no Supabase.

---

## Parte A — já entregue no código (não repetir no app)

- [x] `in_app_purchase` + tela `/planos` com preço só quando a loja devolve produto
- [x] Compra e “Restaurar compras”
- [x] Edge `loja-verificar-compra` (Apple + Google, indicações, idempotência por `payment_id`)
- [x] Prazos 3 / 6 / 12 meses (Apple não aceita 5 nem 8 em não renovável)
- [x] IDs: `soloforte_plano_bronze`, `soloforte_plano_prata`, `soloforte_plano_ouro`
- [x] Mercado Pago bloqueado no app
- [x] Testes Flutter (`test/modules/planos/`) e Deno da Edge

Bundles: iOS `com.soloforte.soloforteApp` · Android `com.soloforte.app`.

Detalhe dos produtos (texto para colar): [`PRODUTOS_IAP_LOJAS.md`](PRODUTOS_IAP_LOJAS.md).

---

## Parte B — você: Supabase (obrigatório antes de testar compra)

Sem isto, a loja pode cobrar e o plano **não** aparece na conta.

1. Fazer login e link do projeto (se ainda não): `supabase link`
2. Definir secrets (Dashboard → Edge Functions → Secrets ou CLI):

| Secret | Uso |
|---|---|
| `APPLE_IAP_ISSUER_ID` | App Store Connect → Users and Access → Keys → Issuer ID |
| `APPLE_IAP_KEY_ID` | ID da chave In-App Purchase |
| `APPLE_IAP_PRIVATE_KEY` | Conteúdo `.p8` (quebras de linha ok) |
| `APPLE_BUNDLE_ID` | Opcional; padrão `com.soloforte.soloforteApp` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | JSON inteiro da conta de serviço com acesso Android Publisher |
| `GOOGLE_PLAY_PACKAGE_NAME` | Opcional; padrão `com.soloforte.app` |

`SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SUPABASE_SERVICE_ROLE_KEY` já são padrão do projeto.

3. Publicar a função (no Mac, na pasta do repo):

```bash
./tool/deploy_loja_verificar_compra.sh
```

4. Smoke da Edge (com JWT **válido** de usuário de teste no Supabase):

```bash
# Antes de configurar secrets Apple/Google: espere HTTP 503 (apple_not_configured / google_not_configured).
# JWT inválido ou ausente: 401. Rota inexistente: 404 — não deve ocorrer nesta função.
# Com secret Apple configurado, transactionId/verificationData falsos tendem a 502 — não use isso como smoke.
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer SEU_JWT_VALIDO" \
  -H "Content-Type: application/json" \
  -d '{"platform":"ios","productId":"soloforte_plano_bronze","transactionId":"skip-smoke","verificationData":""}' \
  "$SUPABASE_URL/functions/v1/loja-verificar-compra"
```

---

## Parte C — você: iOS (enviar primeiro)

### C.1 App Store Connect — contrato e produtos

- [ ] Acordo **Paid Applications** ativo
- [ ] Banco e fiscal preenchidos
- [ ] Três assinaturas **não renováveis** (Subscription → Non-Renewing), IDs e prazos em [`PRODUTOS_IAP_LOJAS.md`](PRODUTOS_IAP_LOJAS.md)
- [ ] Preços em BRL (referência R$ 49,90 / 79,90 / 119,90)
- [ ] Associar os três produtos à **versão** que vai para revisão (obrigatório se o app oferece compra)

### C.2 Build e TestFlight

- [ ] `./tool/release_store_check.sh` e `./tool/arch_check.sh` → Exit 0
- [ ] `flutter test test/modules/planos/`
- [ ] Subir **build number** no `pubspec.yaml` (maior que o último aceito na Connect)
- [ ] Gerar IPA com `SUPABASE_URL` e `SUPABASE_ANON_KEY` de produção (`docs/BUILD_RELEASE.md`)
- [ ] Upload (Transporter ou Xcode)

### C.3 Sandbox (antes de “Submit for Review”)

- [ ] Usuário Sandbox em App Store Connect
- [ ] No iPhone: login Sandbox em Ajustes → App Store
- [ ] Comprar Bronze em `/planos` → mensagem de confirmação → plano na conta (Supabase `user_plans`)
- [ ] Repetir “Restaurar compras” se necessário

### C.4 Revisão Apple

- [ ] Ficha: [`APP_STORE_CONNECT.md`](APP_STORE_CONNECT.md)
- [ ] Nota ao revisor: trecho “Nota sugerida ao revisor” em [`APP_STORE_MONETIZATION_REVIEW_NOTES.md`](../APP_STORE_MONETIZATION_REVIEW_NOTES.md)
- [ ] App Review: conta demo — [`CONTA_DEMO_REVIEW.md`](CONTA_DEMO_REVIEW.md)

---

## Parte D — você: Android (depois do iOS em revisão ou publicado)

### D.1 Play Console — produtos

- [ ] Mesmos três IDs como **produto único** (consumível)
- [ ] Preços BRL alinhados
- [ ] Conta de serviço JSON com permissão no app `com.soloforte.app` → secret no Supabase

### D.2 Build

- [ ] Novo `versionCode` / AAB assinado (`docs/store/PLAY_CONSOLE.md`)
- [ ] Trilha **teste fechado** ou interno: 1 compra com licença de teste
- [ ] Confirmar plano em `user_plans` após compra

### D.3 Ficha Play

- [ ] Data safety — IAP: ver `DATA_SAFETY_GOOGLE_PLAY.md` (purchase history / compras in-app se o formulário pedir; não marcar cartão)
- [ ] Demais itens de [`PLAY_CONSOLE.md`](PLAY_CONSOLE.md) e [`GUIA_SUBMISSAO.md`](GUIA_SUBMISSAO.md)

---

## Parte E — checklist rápido “pronto para loja?”

| Pergunta | iOS | Android |
|---|---|---|
| Produtos criados com IDs corretos? | | |
| Secrets Apple/Google no Supabase? | Apple | Google |
| Edge `loja-verificar-compra` deployada? | | |
| Compra sandbox/internal testou OK? | | |
| Binário novo enviado com este código? | | |

Se qualquer “não” na linha de compra, **não promova** compra ao usuário final.

---

## Referências

- ADR-012 Adendo 2 — `docs/02_ARQUITETURA_ATIVA/ADR-012-MODULO-PLANOS.md`
- Edge — `supabase/functions/loja-verificar-compra/README.md`
