# Cases e dados pagos

**Status:** regra de produto fechada em 14/11/2026, 13:37 (America/Araguaina)  
**Este arquivo é o lugar único dos dados pagos:** preço, cota, metal da publicação, quem vê o pin, vínculo e ocorrência.  
**Bounded contexts:** `planos/` · `marketing/` · vínculo do produtor · ocorrências  
A arquitetura continua em ADR-012 e ADR-011. Ocorrência no vínculo (Bronze+) entrou no app em 14/11/2026.

Um ponto segue em aberto, no final: se o produtor também precisa de plano para ver a ocorrência compartilhada.

---

## Preço

O valor cobrado é o cadastrado na App Store ou na Google Play. Estes são os preços de referência para cadastrar. Prazo fixo, sem renovação automática. Troca de plano começa um prazo novo. O app só mostra o preço quando a loja devolve o produto.

| Plano | Preço | Prazo | Produto |
|---|---|---|---|
| Bronze | R$ 30 por mês (R$ 90 à vista, 3 meses) | 3 meses | `soloforte_plano_bronze` |
| Prata | R$ 50 por mês (R$ 300 à vista, 6 meses) | 6 meses | `soloforte_plano_prata` |
| Ouro | R$ 80 por mês (R$ 960 à vista, 12 meses) | 12 meses | `soloforte_plano_ouro` |

A tela Meu Plano mostra essas vantagens no menu Grátis, Bronze, Prata e Ouro. O valor cobrado continua sendo o da loja.

Compra no binário: StoreKit no iOS e Play Billing no Android. A Edge `loja-verificar-compra` grava `user_plans` depois de validar o recibo. O aparelho não concede plano.

Referência antiga do Mercado Pago, fora do funil do app: Bronze R$ 49,90 em 3 meses, Prata R$ 79,90 em 5 meses, Ouro R$ 119,90 em 8 meses.

---

## Cota da conta

Cada publicação gasta a cota do metal escolhido. Ouro não é ilimitado.

| Plano da conta | Cases Bronze | Cases Prata | Cases Ouro |
|---|---|---|---|
| Sem plano pago | 0 | 0 | 0 |
| Bronze | 5 | 0 | 0 |
| Prata | 5 | 5 | 0 |
| Ouro | 5 | 5 | 10 |

Admin continua ilimitado, como no código de hoje.

---

## Metal da publicação

O seletor **Visibilidade** escolhe o metal **daquela publicação**: Ouro, Prata ou Bronze. Não é um filtro “o plano da conta e os inferiores”.

Sem plano pago o seletor fica visível e travado. Nenhum metal é escolhido. O case fica no mapa só do autor.

Com plano pago, o autor escolhe um metal que ainda tenha cota:

- Plano Bronze escolhe Bronze.
- Plano Prata escolhe Bronze ou Prata.
- Plano Ouro escolhe Bronze, Prata ou Ouro.

Case que já existia sem metal continua privado até alguém escolher o metal. Comprar o plano não escolhe o metal sozinho.

Tipos de conteúdo do mesmo case: Resultado, Antes/Depois e Avaliação. O lado a lado segue o metal da publicação.

---

## Quem vê o pin

Direção do vínculo: perfil consultor para perfil produtor.

| Metal da publicação | Quem vê | Zoom mínimo no mapa |
|---|---|---|
| Ouro | Todos, inclusive quem não está logado | 8 |
| Prata | Todos os usuários logados | 12 |
| Bronze | O autor e o produtor do vínculo | 14 |
| Sem metal | Só o autor | — |

Ouro e Prata podem ser compartilhados no vínculo. No Ouro, o produtor vinculado também pode publicar o case com o pin dele.

Tamanho do pin no código (`MarketingCaseMarker`), zoom &lt; 15: Ouro 120×100, Prata 100×84, Bronze 84×70. A partir do zoom 15 a leitura fica igual nos três, largura 184.

Janela pública já no banco, contada de `liberado_em` até `publico_ate`: Ouro 6 meses, Prata 4 meses, Bronze 2 meses. Expirar esconde. O registro permanece.

---

## O produtor publica de novo

O produtor vinculado pode usar o case com o pin dele e publicar com outro metal, dentro da cota do plano dele.

Exemplo: o consultor Prata compartilhou um case com um produtor Ouro. O produtor publica esse case no metal Ouro. No mapa fica só o pin mais alto. A ordem é Ouro, depois Prata, depois Bronze.

---

## Vínculo

A regra vale para todos os vínculos, inclusive os já aceitos.

O vínculo leva fazenda, talhões, mapa e desenhos no mapa.

Ocorrência entra no vínculo só com plano Bronze ou superior. Sem esse plano o produtor não vê a ocorrência. O consultor cria ocorrência sem plano pago. Compartilhar a ocorrência exige Bronze.

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

Parcial em relação à regra acima (atualizado 14/11/2026).

- `UserPlan.free` (`id = free`) aparece como “Sem plano pago” e, por dentro, está marcado como Bronze sem expiração. A tela mostra “5 cases” e “0/5 para Prata”.
- Cota por metal na publicação (Bronze 5 / Prata 5+5 / Ouro 5+5+10 conforme plano pago; free e expirado = 0 em todos; admin ilimitado).
- Seletor **Visibilidade** travado sem plano pago; com plano, só metais permitidos pela conta são tocáveis; caso novo inicia no primeiro metal permitido.
- Publicar case não exige compra. O bloqueio aplica a cota do metal escolhido (`visibilidade`), não um teto único somando metais.
- **`liberado_em` nulo:** pin só do autor (`ownerUserId`); produtor vinculado e mapa anônimo não veem, mesmo com metal Ouro. Rascunho ou publish bloqueado mantém `liberado_em` nulo. Fail-open de plano no notifier (`skipPlanLimit`) não grava `liberado_em` localmente.
- Ao publicar com plano pago, metal válido e cota ok: o app grava `liberado_em` (UTC) e `publico_ate` (Ouro 6m, Prata 4m, Bronze 2m), alinhado à migration Supabase.
- Pin no mapa (`MarketingCaseVisibility`): dono sempre vê o próprio `published`; sem `liberado_em` só o autor. Ouro liberado + janela ativa → todos (anônimo só Ouro via `isVisibleOnMapForAnonymous`). Prata + janela ativa → consultor e produtor logados; expirada só autor. Bronze + janela ativa → autor ou produtor com vínculo no `client_id`; consultor não vê bronze de terceiros. Grupos por `source_case_id`: no mapa só o pin do metal mais alto (`deduplicateHighestMetalPerGroup`).
- Mapa sem login: `isVisibleOnMapForAnonymous` (Ouro liberado, janela ativa). Prata exige login.
- O convite oferece Fazendas, Talhões e mapa, Ocorrências e Relatórios; Fazendas/Talhões/Relatórios ligados por padrão. **Ocorrências** só pode ser marcada com plano Bronze+ ativo (checkbox desligado e desabilitado sem plano; `createInvite` valida no app; RLS + RPC no Supabase).
- Produtor lê ocorrências compartilhadas só quando `consultor_pode_compartilhar_ocorrencias` (Bronze+/admin ativo) — vínculos antigos com `share_occurrences=true` sem plano do consultor não expõem dados.
- NDVI refinado já segue Ouro pago.
- **Meu Plano** (`/planos/meu-plano`) e **Planos** (`/planos`) mostram preço só quando a loja devolve o produto (`LojaProduto.preco`). Sem produto na vitrine, o menu de vantagens usa só o prazo do catálogo (`store_plan_catalog.dart`) e o texto «preço na loja ao comprar» — sem BRL fictício no app. Valores de referência para cadastro na App Store / Play Console: **R$ 90 / R$ 300 / R$ 960** (`docs/store/PRODUTOS_IAP_LOJAS.md`, alinhado à tabela Preço acima).

---

## Ainda em aberto

O consultor cria a ocorrência sem plano e só compartilha a partir de Bronze.

Falta decidir se o produtor, para ver essa ocorrência compartilhada, também precisa de um plano pago.
