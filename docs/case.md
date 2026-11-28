# Cases e dados pagos

**Status:** regra de produto fechada em 14/11/2026, 13:37 (America/Araguaina)  
**Este arquivo é o lugar único dos dados pagos:** preço, cota, metal da publicação, quem vê o pin, vínculo e ocorrência.  
**Bounded contexts:** `planos/` · `marketing/` · vínculo do produtor · ocorrências  
A arquitetura continua em ADR-012 e ADR-011. Ocorrência no vínculo (Bronze+) entrou no app em 14/11/2026.

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

Cada publicação para outros usuários gasta a cota do metal escolhido. Ouro não é ilimitado. O número 0 é a cota de publicação para outros usuários. Criar o case privado não gasta essa cota e não exige plano pago.

| Plano da conta | Cases Bronze | Cases Prata | Cases Ouro |
|---|---|---|---|
| Sem plano pago | 0 | 0 | 0 |
| Bronze | 5 | 0 | 0 |
| Prata | 5 | 5 | 0 |
| Ouro | 5 | 5 | 10 |

Admin continua ilimitado, como no código de hoje.

---

## Talhões sincronizados na nuvem (Desenho)

Limite de talhões do módulo Desenho que a conta pode manter sincronizados na nuvem. Sem plano pago o desenho fica só no aparelho.

| Plano da conta | Talhões sincronizados na nuvem |
|---|---|
| Sem plano pago | 0 (só no aparelho) |
| Bronze | 150 |
| Prata | 500 |
| Ouro | Sem limite |

- Plano pago expirado ou inativo conta como sem plano pago: 0.
- Sem limite é `null` no código. Nenhum número fixo representa ilimitado, ao contrário do `999999` que `limiteCases` devolve para admin.
- Admin é ilimitado (`null`), independente do plano, como no ADR-012. Isso vale também para admin sem plano pago ou com plano expirado.
- Plano indisponível ou inválido não vira 0: o consumidor do limite deve manter o último limite conhecido e nunca apagar da nuvem talhões já sincronizados.
- Fonte no código: `PlanoTipo.limiteTalhoesSincronizados` (tabela por plano) e `UserPlan.limiteTalhoesSincronizados` (conta efetiva).

---

## Metal da publicação

O seletor **Visibilidade** escolhe o metal **daquela publicação**: Ouro, Prata ou Bronze. Não é um filtro “o plano da conta e os inferiores”.

Sem plano pago o usuário cria o case. O seletor continua visível e travado. Nenhum metal é escolhido. O pin fica só no mapa do autor. Outros usuários não veem.

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
| Bronze | O autor e o produtor do vínculo, se o **consultor** do vínculo tem Bronze+ ativo (o produtor não precisa de plano pago) | 14 |
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

O vínculo leva fazenda, talhões, mapa e desenhos no mapa (sem plano do produtor).

Pin Bronze do consultor no mapa: produtor com vínculo ativo vê se o **consultor** que gerou o convite tem Bronze+ ativo; consultor sem plano pago ou expirado não compartilha pin Bronze com o produtor.

Ocorrência entra no vínculo só com plano Bronze ou superior ativo em **consultor e produtor**. O consultor cria ocorrência sem plano pago; **compartilhar** no convite exige Bronze+ do consultor. O produtor **vê** ocorrências compartilhadas só com Bronze+ próprio — vínculo com `share_occurrences` não basta sem plano do produtor.

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

Parcial em relação à regra acima (atualizado 28/11/2026).

- `UserPlan.free` (`id = free`) aparece como “Sem plano pago” e, por dentro, está marcado como Bronze sem expiração. A tela mostra “5 cases” e “0/5 para Prata”.
- Cota por metal na publicação (Bronze 5 / Prata 5+5 / Ouro 5+5+10 conforme plano pago; free e expirado = 0 em todos; admin ilimitado).
- Seletor **Visibilidade** travado sem plano pago; com plano, só metais permitidos pela conta são tocáveis; caso novo inicia no primeiro metal permitido.
- Criar o case privado não exige plano pago. Sem plano pago (e plano expirado/inativo, seletor travado) criar grava `status = published` sem `liberado_em` e sem `publico_ate`. O pin fica só no mapa do autor. Publicar um rascunho «Não gerado» para outros usuários continua bloqueado quando a cota do metal é 0.
- Publicar para outros usuários aplica a cota do metal escolhido (`visibilidade`); cota 0 bloqueia essa publicação. Não há teto único somando metais. Cota paga e admin permanecem como na tabela.
- **`liberado_em` nulo:** pin só do autor (`ownerUserId`); produtor vinculado e mapa anônimo não veem, mesmo com metal Ouro. Rascunho ou publish bloqueado mantém `liberado_em` nulo. Fail-open de plano no notifier (`skipPlanLimit`) não grava `liberado_em` localmente.
- Ao publicar com plano pago, metal válido e cota ok: o app grava `liberado_em` (UTC) e `publico_ate` (Ouro 6m, Prata 4m, Bronze 2m), alinhado à migration Supabase.
- Pin no mapa (`MarketingCaseVisibility`): dono sempre vê o próprio `published`; sem `liberado_em` só o autor. Ouro liberado + janela ativa → todos (anônimo só Ouro via `isVisibleOnMapForAnonymous`). Prata + janela ativa → consultor e produtor logados; expirada só autor. Bronze + janela ativa → autor ou produtor com vínculo no `client_id` **e** consultor do vínculo Bronze+ (`list_bronze_pin_client_ids_for_producer`); consultor não vê bronze de terceiros. Grupos por `source_case_id`: no mapa só o pin do metal mais alto (`deduplicateHighestMetalPerGroup`).
- Mapa sem login: `isVisibleOnMapForAnonymous` (Ouro liberado, janela ativa). Prata exige login.
- O convite oferece Fazendas, Talhões e mapa, Ocorrências e Relatórios; Fazendas/Talhões/Relatórios ligados por padrão. **Ocorrências** só pode ser marcada com plano Bronze+ ativo (checkbox desligado e desabilitado sem plano; `createInvite` valida no app; RLS + RPC no Supabase).
- Produtor lê ocorrências compartilhadas quando consultor **e** produtor passam `consultor_pode_compartilhar_ocorrencias` (Bronze+/admin ativo) — app checa plano do produtor antes do RPC; Supabase repete no RPC e na policy `occurrences_select_authorized`.
- `ProducerLinkOccurrencePolicy.usuarioPodeAcessarOcorrenciasNoVinculo` / `assertProdutorPodeVerOcorrenciasCompartilhadas` no app; consultor usa o mesmo gate ao compartilhar.
- NDVI refinado já segue Ouro pago.
- **Talhões sincronizados na nuvem:** o limite existe como dado (`PlanoTipo.limiteTalhoesSincronizados`, `UserPlan.limiteTalhoesSincronizados`) e aparece como último bullet de cada card em **Meu Plano** (`meu_plano_vantagens.dart`), com o número lido do dado. **Ainda não é aplicado no sync do Desenho:** `drawing/` não importa `planos/` e `DrawingSyncService` não consulta nenhum limite. Aplicar exige contrato em `core/contracts/` e ADR novo.
- **Plano desconhecido:** `PlanoTipo.fromString` lança `ArgumentError` para um valor fora de bronze/prata/ouro, e `UserPlan.fromJson` herda isso. É intencional: não vira “sem plano pago”. O `planoAtivoProvider` serve o plano em cache (TTL 24h) e, sem cache válido, lança `PlanoCacheUnavailableException` com log de “falha de parse”.
- **Meu Plano** (`/planos/meu-plano`) e **Planos** (`/planos`) mostram preço só quando a loja devolve o produto (`LojaProduto.preco`). Sem produto na vitrine, o menu de vantagens usa só o prazo do catálogo (`store_plan_catalog.dart`) e o texto «preço na loja ao comprar» — sem BRL fictício no app. Valores de referência para cadastro na App Store / Play Console: **R$ 90 / R$ 300 / R$ 960** (`docs/store/PRODUTOS_IAP_LOJAS.md`, alinhado à tabela Preço acima).

