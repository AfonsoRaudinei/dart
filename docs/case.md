# Cases e dados pagos

**Status:** ficha de produto · 14/11/2026 (America/Araguaina)  
**Bounded contexts:** `planos/` · `marketing/` · vínculo do produtor · ocorrências  
**Este arquivo organiza os dados pagos.** A arquitetura continua em ADR-012 e ADR-011. O app ainda não aplica a seção “Regra pedida em 14/11/2026”.

---

## Onde isso já estava escrito

| Arquivo | O que cobre |
|---|---|
| `docs/02_ARQUITETURA_ATIVA/ADR-012-MODULO-PLANOS.md` | Módulo `planos/`, loja, indicações, limite de cases |
| `docs/02_ARQUITETURA_ATIVA/ADR-011-MARKETING-CASES.md` | Case no mapa (pin, publicação) |
| `docs/02_ARQUITETURA_ATIVA/MARKETING_REGRAS_VISIBILIDADE_OURO_PRATA_BRONZE.md` | Tamanho do pin, zoom e prazo público |
| `lib/modules/planos/AGENTS.md` | Compra só pela App Store / Google Play |
| `lib/modules/marketing/AGENTS.md` | Case ligado ao plano ativo |

Não havia um `case.md`. Esta ficha passa a ser o lugar dos dados pagos e da regra de quem vê o case.

---

## Regra pedida em 14/11/2026

O seletor **Visibilidade** (Ouro / Prata / Bronze) no sheet do case escolhe o tipo de plano com que o case é publicado. Esses três níveis são cases pagos: cada um fica vinculado ao plano da conta.

Conta **sem plano pago** (tela Meu Plano: “Sem plano pago”):

- Não precisa escolher Ouro, Prata ou Bronze.
- O case continua no mapa.
- Só o autor vê esse case.
- O produtor vinculado também não vê o lado a lado (Antes/Depois).

Vínculo compartilhado **daqui para frente**: somente o mapa e os desenhos no mapa.

Ocorrência exige plano pago, no mínimo **Bronze**.

O código de hoje não faz isso. Detalhe na seção “No app hoje” e perguntas no final.

---

## Catálogo pago (loja)

Compra dentro do app: StoreKit (iOS) e Play Billing (Android). Prazo fixo, sem renovação automática. Troca de plano começa um prazo novo. O preço cobrado é o cadastrado na loja; o app só mostra preço quando a loja devolve o produto. Na captura de 14/11/2026 a loja respondeu: “A loja não tem planos disponíveis para compra neste momento.”

| Plano | Produto | Prazo na loja | Referência antiga (Mercado Pago, fora do funil do app) |
|---|---|---|---|
| Bronze | `soloforte_plano_bronze` | 3 meses | R$ 49,90 |
| Prata | `soloforte_plano_prata` | 6 meses | R$ 79,90 |
| Ouro | `soloforte_plano_ouro` | 12 meses | R$ 119,90 |

Fonte do prazo vigente: `lib/modules/planos/domain/store_plan_catalog.dart` e `supabase/functions/loja-verificar-compra/store_plan_catalog.ts`. A Edge `loja-verificar-compra` grava `user_plans` depois de validar o recibo. O aparelho não concede plano.

Mercado Pago permanece no repositório e não é o checkout do binário. Nesse fluxo antigo os prazos eram Bronze 3, Prata 5 e Ouro 8 meses (`mercadopago-criar-preferencia`).

Texto da tela Meu Plano: valor definido pela App Store ou Google Play, cobrado à vista na confirmação. O acesso dura o prazo do plano e não renova sozinho.

---

## Indicações

| Conta | Meta | Sobe para | Prazo do upgrade (loja) |
|---|---|---|---|
| Bronze pago | 5 indicações validadas | Prata | 6 meses |
| Prata pago | 10 indicações validadas | Ouro | 12 meses |
| Ouro | — | — | — |

- Indicação válida: cadastro com o código e pagamento de um plano em até 30 dias.
- Ao subir, a contagem zera. Indicações do Bronze não seguem para o Ouro.
- Bronze → Ouro direto por indicação não existe.
- Sem Bronze pago, a cadeia de indicação não começa (ADR-012). A tela mesmo assim mostra “0/5 para Prata” na conta sem plano, porque o plano livre interno está marcado como Bronze. Ver “No app hoje”.

Fonte: `apply_store_referral.ts`, `meu_plano_screen.dart`.

---

## Limite de cases no mapa (código)

| Plano no enum | Cases ativos no mapa |
|---|---|
| Bronze | 5 |
| Prata | 5 |
| Ouro | ilimitado |
| Admin | ilimitado |

`PlanoTipo.limiteCases` em `lib/modules/planos/domain/enums/plano_tipo.dart`.

O ADR-012 ainda cita Bronze com 3 cases. A tela e o enum usam **5**. A captura “Sem plano pago · 5 cases” bate com o enum, não com o 3 do ADR.

---

## Visibilidade do pin (código)

O seletor está em `PlanoMarketingSelector` (`case_selectors_widget.dart`). Cores: Ouro `#FFB800`, Prata `#9EA9B2`, Bronze `#A0522D`. Os três botões aceitam toque sempre. O sheet novo começa em **Prata**.

| | Ouro | Prata | Bronze |
|---|---|---|---|
| Pin compacto (zoom &lt; 15) | 120×100 | 100×84 | 84×70 |
| Zoom mínimo | 10 | 12 | 14 |
| Leitura (zoom ≥ 15) | largura 184, igual nos três | igual | igual |
| Janela pública (`publico_ate`) | 6 meses | 4 meses | 2 meses |
| Mapa sem login | sim, com janela ativa | não | não |

Tipos de case (abas do mesmo sheet, independentes do metal): **Resultado**, **Antes/Depois**, **Avaliação**.

Expirar a janela pública esconde do mapa anônimo. O registro permanece. Renovação de owner está na migration `20260723191000_marketing_cases_public_ttl.sql` (`liberado_em`, `publico_ate`). A ficha antiga de marketing ainda marca parte dessa UI como pendente.

Quem vê no mapa privado hoje (`MarketingCaseVisibility`):

- O autor vê os próprios cases publicados.
- O produtor vê os próprios, os do cliente vinculado e qualquer Ouro público.
- Prata e Bronze de outra pessoa ficam de fora do mapa anônimo.

---

## No app hoje (conta sem plano pago)

`UserPlan.free` usa `id = free`, `plano = bronze`, ativo, sem data real de expiração. A tela mostra “Sem plano pago” quando `id == free`, e ao mesmo tempo:

- “Cases ativos no mapa” usa o limite do Bronze: **5 cases**.
- “Indicações” mostra **0/5 para Prata**, como se a conta já fosse Bronze.
- Publicar case não exige compra. O bloqueio é só o limite de 5 (admin ignora o limite).
- O seletor Ouro / Prata / Bronze aparece e os três podem ser escolhidos.
- O pin do autor aparece no mapa dele. Ouro publicado também entra na leitura anônima, se a janela pública estiver aberta.

Isso diverge da regra de 14/11/2026.

---

## Vínculo com o produtor

Convite atual (`producer_invite_dialog.dart`), tudo ligado por padrão, código vale 7 dias:

| Opção na tela | Campo |
|---|---|
| Fazendas | `share_farms` |
| Talhões e mapa | `share_fields` |
| Ocorrências | `share_occurrences` |
| Relatórios | `share_reports` |

Desenho no mapa não é uma caixa própria. O case (incluindo Antes/Depois) não é uma caixa do convite: o produtor vê case do cliente vinculado e Ouro público pelas regras de `MarketingCaseVisibility`.

Regra pedida para vínculos novos: somente mapa e desenhos no mapa. O produtor desse vínculo não vê o lado a lado.

---

## Ocorrências

Hoje a ocorrência não consulta plano pago. O convite pode incluir “Ocorrências”.

Regra pedida: ocorrência exige plano pago, mínimo Bronze.

NDVI refinado (à parte, já no código): só Ouro pago, ativo e dentro do prazo. Admin não ganha NDVI refinado automático (`ndviRefinedEnabledForUserPlan`).

---

## O que ainda precisa de resposta

1. Sem plano pago, o seletor some por completo, ou fica na tela com Ouro, Prata e Bronze desligados?
2. Com plano pago, o metal do case pode ser só o da conta, ou também os inferiores? (Bronze só Bronze; Prata escolhe Prata e Bronze; Ouro escolhe os três.)
3. Case sem plano: o produtor deixa de ver o pin inteiro, ou vê o pin e só o Antes/Depois fica fechado? Resultado e Avaliação seguem a mesma regra do lado a lado?
4. “Mapa e desenhos” no vínculo novo: entra talhão desenhado no mapa e sai fazenda, ocorrência e relatório. Desenho solto (sem talhão) entra junto?
5. Vínculos já aceitos continuam com fazenda, ocorrência e relatório. A frase “daqui para frente” vale só para convite novo.
6. Ocorrência com Bronze: quem precisa do plano — o consultor que cria, o produtor que lê, ou os dois? Se o vínculo novo não leva ocorrência, a ocorrência paga é só da conta do consultor, fora do convite.
7. Case privado (sem plano) entra em algum limite, ou o autor publica quantos quiser e só ele vê?
8. Quando a conta compra Bronze depois, os cases que já estavam só para o autor continuam privados até alguém escolher o metal, ou passam a Bronze na hora?
9. Prata e Bronze pagos continuam fora do mapa de quem não está logado (só Ouro é público), com a janela de 4 e 2 meses valendo para quem pode ver?
10. NDVI refinado continua exclusivo do Ouro?
