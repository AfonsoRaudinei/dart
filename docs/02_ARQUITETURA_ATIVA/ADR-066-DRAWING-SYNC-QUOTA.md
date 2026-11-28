# ADR-066 — Cota de talhões sincronizados (Desenho)

**Status:** Aceito (documentação — implementação em fases 2–5)  
**Data:** 28/11/2026  
**Módulos:** `planos/`, `drawing/`, `marketing/`, `produtor/`, `core/contracts/`, Supabase `drawings` · `user_plans` · `marketing_cases` · `producer_client_links`

## Contexto

Os limites por tier já existem como dado de domínio (`PlanoTipo.limiteTalhoesSincronizados`,
`UserPlan.limiteTalhoesSincronizados`) e como copy em **Meu Plano** (`docs/case.md`).
`DrawingSyncService` ainda envia todo `pending_sync` sem consultar plano. `drawing/` não pode
importar `planos/` (fronteira ADR-012). Precedente: `INdviRefinedEntitlement` — contrato em
`core/contracts/`, adapter em `planos/`, registro em `main.dart`.

Grátis / expirado / inativo ⇒ limite efetivo **0** (só local). Ouro e admin ⇒ `null` (ilimitado).
Bronze **150**, Prata **500**.

Risco de regressão: campo de teste do case (ADR-064) e talhões visíveis ao produtor via vínculo
dependem de linhas em `public.drawings`. Cortar sync às cegas quebraria marketing e produtor.

## Decisão

### 1. Contratos neutros (fase 2)

**Limite (planos → drawing, sem import inverso):**

- `IDrawingSyncQuota` em `lib/core/contracts/` com `int? get cloudTalhaoLimit` (`null` = ilimitado).
- Adapter em `planos/infra/` lê `UserPlan.limiteTalhoesSincronizados` **depois** de carimbar
  `isAdmin` com a **mesma regra** já usada em `PlanoRepositoryImpl.getPlanoAtivo` /
  `producer_link_repository` (`perfis.role = admin` ou claim JWT). `user_plans` remoto não traz
  `is_admin`; ignorar o carimbo quebra paridade com o servidor (admin viraria 0 no push).
- `planos/` **não** importa `marketing/` nem `produtor/` (`planos/AGENTS.md`).

**Isenção e ocupação (drawing, sem importar planos):**

- Predicados de isenção e contagem ficam em `drawing/data/` (ou RPC Supabase espelhando o mesmo
  SQL). O sync consulta SQLite local + remoto; **não** embute marketing dentro de `planos/infra/`.
- Opcional: funções SQL `drawing_is_exempt`, `drawing_quota_occupancy` para paridade estrita
  cliente/servidor.

Consumidores: `DrawingSyncService` (push), feedback de sync / UX (fase 5).

### 2. O que conta como “talhão” na cota

Uma linha em `public.drawings` (ou equivalente local prestes a push) com:

- `user_id` = dono do push (consultor que sincroniza);
- `deleted_at IS NULL`;
- `properties->>'ativo'` verdadeiro;
- **não** isenta;
- **não** é espelho read-only do produtor (`vinc_*`, cópia com outro `user_id`, ids só locais
  de `ProducerLinkedDrawingSyncService.insertMirror`).

Talhões que o consultor salvou como polígonos distintos (ids próprios após
`addFeaturesFromGeometry`) contam **um por linha**. Sufixos `__parte_N` em espelhos do produtor
**não** entram na cota do consultor.

### 3. Isenções (decisão de produto — opção **a**)

Estas geometrias do **consultor dono** não entram na ocupação nem são bloqueadas no push:

1. **Case de marketing** — existe linha em `marketing_cases` com `drawing_id = drawings.id`,
   `user_id = drawings.user_id`, `status = 'published'`, `deletado_em IS NULL` (remoto ou cache
   SQLite alinhado a ADR-064). Rascunho / `pending_sync` **não** isenta.
2. **Vínculo produtor** — `properties->>'cliente_id'` do desenho coincide com um
   `producer_client_links` onde `consultor_user_id = drawings.user_id`, `status` ativo,
   `share_fields = true` (todos os talhões daquele cliente no escopo compartilhado, não só campo
   de teste). Predicado espelha a policy `drawings_select_linked_producer`, **visto do consultor
   dono** — não reutilizar `loadAuthorizedClientIdsForDrawings` (API do **produtor**).

Isenções valem no cliente (ordem de push) e no servidor (contagem + trigger).

### 4. Ocupação e sync (cliente — fase 3)

Em `DrawingSyncService.synchronize()`, antes de `_remoteStore.push`:

1. `cloudTalhaoLimit` via `IDrawingSyncQuota`.
2. `null` ⇒ push de todo pendente (respeitando isenções apenas para telemetria).
3. `0` ⇒ nenhum push não isento; `pending_sync` preservado.
4. Limite **N > 0**:
   - **Ocupação** = cardinalidade da **união por `id`**: ids remotos que consomem cota ∪ ids locais
     `synced` ainda não presentes no conjunto remoto. **Não** somar remoto + local do mesmo id.
   - Fila de envio = pendentes não isentos ordenados por `created_at` ascendente.
   - **Vaga nova** só para `id` que ainda não existe em `public.drawings` com `deleted_at` nulo.
     Upsert de id já remoto = correção geométrica, **não** consome vaga e não deve ficar preso em
     `pending_sync` por cota (espelha `DrawingRemoteStore.push` upsert).
5. **Plano indisponível**: fail-closed para **novos** ids; não apagar nuvem; respeitar cache TTL
   24h quando existir (`docs/case.md`).
6. Erro remoto de cota ⇒ sem retry infinito no `SyncRetryRunner`.

**Pull** inalterado.

### 5. Servidor (fase 4)

- `drawing_sync_quota_limit(p_user_id) returns int` — `NULL` = ilimitado (Ouro **e** admin via
  `perfis` / JWT); 0 = grátis/expirado; 150/500 conforme `user_plans`.
- `drawing_is_exempt(p_drawing_id, p_user_id) returns boolean` — predicados §3.
- `drawing_quota_occupancy(p_user_id) returns int` — contagem §2 com isenções.
- Trigger **`BEFORE INSERT`**: se `NOT drawing_is_exempt` e ocupação ≥ limite ⇒ `RAISE`.
  Se `id` já existe para o mesmo `user_id` (upsert vira update) ⇒ **permitir** (não bloquear
  geometria). Reativar tombstone (`deleted_at` → null) = insert novo, consome vaga.

Deploy migration **após** cliente distinguir insert novo vs update (ordem 3 → 4).

### 6. UX quando o teto bloqueia (fase 5 — obrigatória)

Quando o push de **id novo** for omitido ou recusado por cota:

- Mensagem curta; desenhos locais permanecem no aparelho.
- CTA **“Ver planos”** → rota existente (`/planos` / Meu Plano); `context.go` / `context.push`;
  sem FAB local.
- Host: feedback pós-sync do Desenho ou sheet já aberto (sem AppBar fixa).
- Sem jargão de isenção case/produtor.

### 7. Documentação e testes

- `docs/case.md` alinhado a §3 (publicado + isenções).
- Paridade cliente/servidor: 0 / 150 / 500 / `null` e admin ilimitado.
- Testes: ocupação união por id; upsert no teto; isenção case publicado; vínculo `share_fields`;
  admin com limite `null` após carimbo.

## Não-objetivos

- Hard delete na nuvem para “caber” no plano.
- `999999` como ilimitado neste limite.
- `drawing/` importar `planos/`; `planos/` importar `marketing/` ou `produtor/`.
- Cota em espelhos `vinc_*` / `__parte_N` do produtor.

## Consequências

- Fases 2–5 dependem deste ADR; código em `drawing/` exige ok (path crítico).
- Até fase 3, copy em Meu Plano é promessa; sync ainda não corta (`docs/case.md`).

## Referências

- `docs/case.md`, ADR-012, ADR-037, ADR-064
- `INdviRefinedEntitlement`, `DrawingRemoteStore.push` (upsert)
- `producer_client_links`, policy `drawings_select_linked_producer`