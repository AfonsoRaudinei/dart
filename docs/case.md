# Cases e dados pagos

**Status:** regra de produto fechada em 14/11/2026, 13:02 (America/Araguaina)  
**Bounded contexts:** `planos/` · `marketing/` · vínculo do produtor · ocorrências  
**Esta ficha é o lugar dos dados pagos e de quem vê o quê.** A arquitetura continua em ADR-012 e ADR-011. O app ainda não aplica esta regra.

Um ponto segue em aberto, no final: se o produtor também precisa de plano para ver a ocorrência que o consultor compartilhou.

---

## Onde isso já estava escrito

| Arquivo | O que cobre |
|---|---|
| `docs/02_ARQUITETURA_ATIVA/ADR-012-MODULO-PLANOS.md` | Módulo `planos/`, loja, indicações |
| `docs/02_ARQUITETURA_ATIVA/ADR-011-MARKETING-CASES.md` | Case no mapa |
| `docs/02_ARQUITETURA_ATIVA/MARKETING_REGRAS_VISIBILIDADE_OURO_PRATA_BRONZE.md` | Tamanho do pin, zoom e prazo público |
| `lib/modules/planos/AGENTS.md` | Compra só pela App Store / Google Play |
| `lib/modules/marketing/AGENTS.md` | Case ligado ao plano ativo |

---

## Plano da conta

| Conta | O que destrava |
|---|---|
| Sem plano pago | Case no mapa, só o autor vê. Seletor de metal visível e travado. |
| Bronze | Ocorrência compartilhada. Metal Bronze no case. |
| Prata | Tudo do Bronze. Case visível para o produtor vinculado. Metais Prata e Bronze. |
| Ouro | Tudo da Prata. Case no mapa de quem não está logado. Metal Ouro. NDVI refinado. |

Compra: StoreKit no iOS e Play Billing no Android. Prazo fixo, sem renovação automática. Troca de plano começa um prazo novo. O preço é o cadastrado na loja. O app só mostra preço quando a loja devolve o produto.

| Plano | Produto | Prazo |
|---|---|---|
| Bronze | `soloforte_plano_bronze` | 3 meses |
| Prata | `soloforte_plano_prata` | 6 meses |
| Ouro | `soloforte_plano_ouro` | 12 meses |

A Edge `loja-verificar-compra` grava `user_plans` depois de validar o recibo. O aparelho não concede plano.

Referência antiga do Mercado Pago, fora do funil do app: Bronze R$ 49,90 em 3 meses, Prata R$ 79,90 em 5 meses, Ouro R$ 119,90 em 8 meses.

---

## Seletor do case (Ouro, Prata, Bronze)

O seletor **Visibilidade** no sheet do case escolhe o metal com que o case é publicado. Os três são cases pagos.

Sem plano pago o seletor fica **visível e travado**. Nenhum metal é escolhido.

Com plano pago, a conta escolhe o próprio metal e os inferiores:

| Plano da conta | Metais que aceitam toque |
|---|---|
| Sem plano | nenhum |
| Bronze | Bronze |
| Prata | Prata e Bronze |
| Ouro | Ouro, Prata e Bronze |

Case que já existia sem metal continua privado até alguém escolher o metal. Comprar o plano não escolhe o metal sozinho.

Quantidade: o autor pode publicar vários cases por enquanto. Esta ficha não fixa um teto.

---

## Quem vê o pin

Direção do vínculo: perfil consultor para perfil produtor.

| Pin | Quem vê |
|---|---|
| Case sem metal | Só o autor, no mapa dele. |
| Case com metal, conta abaixo de Prata | Só o autor. |
| Case com metal, conta Prata ou Ouro | O autor e o produtor vinculado. |
| Case Ouro | Também quem não está logado. |
| Ocorrência | O autor sempre. O produtor vinculado a partir do plano Bronze. |

O lado a lado (Antes/Depois) é case. O produtor vê esse conteúdo a partir do plano Prata, junto com Resultado e Avaliação. Antes disso o produtor não vê o case.

Mapa de quem não está logado: só o case Ouro. Prata e Bronze não entram nesse mapa.

Janela pública já descrita no código, para o case que está no mapa de terceiros: Ouro 6 meses, Prata 4 meses, Bronze 2 meses, contados de `liberado_em` até `publico_ate`. Expirar esconde. O registro permanece.

Tamanho do pin no código (`MarketingCaseMarker`):

| | Ouro | Prata | Bronze |
|---|---|---|---|
| Compacto, zoom &lt; 15 | 120×100 | 100×84 | 84×70 |
| Zoom mínimo | 10 | 12 | 14 |
| Leitura, zoom ≥ 15 | largura 184, igual nos três | igual | igual |

---

## Vínculo consultor → produtor

A regra vale para todos os vínculos, inclusive os já aceitos.

O vínculo leva:

- fazenda
- talhões
- mapa
- desenhos no mapa

Ocorrência entra no vínculo só com plano Bronze ou superior. Sem esse plano o produtor não vê a ocorrência.

O consultor cria ocorrência sem plano pago. Compartilhar a ocorrência exige o plano mínimo dela, Bronze.

Case entra na visão do produtor a partir do plano Prata, e só depois que o metal do case foi escolhido.

---

## Indicações

| Conta | Meta | Sobe para | Prazo do upgrade na loja |
|---|---|---|---|
| Bronze pago | 5 indicações validadas | Prata | 6 meses |
| Prata pago | 10 indicações validadas | Ouro | 12 meses |

Indicação válida: cadastro com o código e pagamento de um plano em até 30 dias. Ao subir, a contagem zera. Bronze não pula para Ouro. Sem Bronze pago a cadeia não começa.

Fonte: `supabase/functions/loja-verificar-compra/apply_store_referral.ts`.

---

## NDVI

NDVI refinado só no Ouro pago, ativo e dentro do prazo. Admin não ganha NDVI refinado automático.

Fonte: `ndviRefinedEnabledForUserPlan`.

---

## O que o app faz hoje

Isto ainda não é a regra acima.

- `UserPlan.free` (`id = free`) aparece como “Sem plano pago” e, por dentro, está marcado como Bronze sem expiração.
- A tela Meu Plano mostra “5 cases” e “0/5 para Prata” nessa conta.
- O seletor Ouro / Prata / Bronze aceita toque sem plano pago. O sheet novo começa em Prata.
- `PlanoTipo.limiteCases`: Bronze 5, Prata 5, Ouro ilimitado, admin ilimitado. O ADR-012 ainda cita Bronze com 3.
- Publicar case não exige compra. O bloqueio atual é o limite de 5.
- O produtor vê case do cliente vinculado e qualquer Ouro público (`MarketingCaseVisibility`).
- Mapa sem login lê Ouro com `publico_ate` ainda válido.
- O convite do produtor oferece Fazendas, Talhões e mapa, Ocorrências e Relatórios, todos ligados por padrão, código válido por 7 dias.
- Ocorrência não consulta plano.
- NDVI refinado já segue Ouro pago.

---

## Ainda em aberto

O consultor cria a ocorrência sem plano e só compartilha a partir de Bronze.

Falta decidir se o produtor, para ver essa ocorrência compartilhada, também precisa de um plano pago. Os dois lados ainda serão pensados.
