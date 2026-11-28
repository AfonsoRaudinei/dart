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

### 1. Contrato neutro

- Criar **`IDrawingSyncQuota`** em `lib/core/contracts/` (+ provider em `core/contracts/`).
- Implementação em `planos/infra/` lendo `UserPlan.limiteTalhoesSincronizados` e regras de isenção
  abaixo, sem `drawing/` importar `planos/`.
- Consumidores típicos: `DrawingSyncService` (push), eventualmente feedback de sync na UI.

Contrato mínimo (semântica; nomes finais na fase 2):

| Método / getter | Semântica |
|---|---|
| `int? get cloudTalhaoLimit` | `null` = ilimitado |
| `Future<bool> isExemptFromQuota(String drawingId)` | Isenção (a) |
| `Future<int> countTowardQuota({required String userId})` | Talhões já na nuvem que consomem cota |

### 2. O que conta como “talhão” na cota

Uma linha em `public.drawings` com:

- `user_id` = dono do push (consultor que sincroniza);
- `deleted_at IS NULL`;
- `properties->>'ativo'` verdadeiro (ou equivalente local antes do push);
- **não** isenta pelas regras abaixo.

Partes de MultiPolygon com ids `__parte_N` contam como linhas distintas se forem ids distintos
(comportamento atual de sync/espelho).

### 3. Isenções (decisão de produto — opção **a**)

Estas geometrias **não** entram na contagem nem são bloqueadas no push:

1. **Case de marketing** — existe `marketing_cases.drawing_id = drawings.id` para o mesmo
   `owner_user_id`, case publicado e não deletado (remoto ou cache SQLite coerente com ADR-064).
2. **Vínculo produtor** — desenho do consultor cujo `properties.cliente_id` está coberto por
   `producer_client_links` ativo com `share_fields = true` entre consultor e produtor (mesma
   regra de escopo que `ProducerLinkedDrawingSyncService` / `loadAuthorizedClientIdsForDrawings`).

Isenções valem no **cliente** (ordem de push) e no **servidor** (contagem + trigger). Espelhos
locais do produtor (`insertMirror`, outro `user_id`) não consomem cota do consultor.

### 4. Comportamento do sync (cliente — fase 3)

Em `DrawingSyncService.synchronize()`, antes de `_remoteStore.push`:

1. Resolver `cloudTalhaoLimit` via contrato.
2. `null` ⇒ fluxo atual (push todo pendente).
3. `0` ⇒ nenhum push, exceto isentos; pendências permanecem `pending_sync`.
4. Limite **N > 0**:
   - Contar linhas remotas que consomem cota + pendentes já `synced` localmente.
   - Ordenar pendentes por `created_at` ascendente.
   - Enviar até esgotar vagas; isentos sempre passam.
5. **Plano indisponível** (sem cache válido, parse inválido): **fail-closed** — não enviar novos
   pushes não isentos; **não** apagar nem rebaixar nuvem; manter último limite conhecido quando
   o cache TTL 24h permitir (`PlanoLocalCache`, ADR planos). Alinhado a `docs/case.md`.
6. Erro remoto classificado como cota excedida ⇒ **não** entrar em retry infinito no
   `SyncRetryRunner` (log + permanece pendente).

**Pull** inalterado: quem já está na nuvem continua sendo puxado e atualizado.

### 5. Servidor (fase 4)

- Função `drawing_sync_quota_limit(p_user_id uuid) returns int` — espelha tabela de planos,
  admin (`perfis.role` ou JWT claim `admin`), expiração e `user_plans.ativo`.
- Função `drawing_counts_toward_quota(p_user_id uuid) returns int` — contagem com mesmas isenções.
- Trigger **`BEFORE INSERT`** em `public.drawings`: recusa insert se contagem ≥ limite e linha
  não isenta.
- **`UPDATE`** de linha existente do próprio usuário **sempre permitido** (correção geométrica).
- Reativar tombstone (`deleted_at` → null) tratado como insert novo para fins de cota.

Migration idempotente; deploy Supabase só após cliente tratar erro de cota (ordem 3 → 4).

### 6. UX quando o teto bloqueia (fase 5 — obrigatória)

Quando o push for omitido ou recusado por cota:

- Mensagem curta, sem número mágico de “ilimitado”.
- Informar limite do plano atual e que desenhos locais permanecem no aparelho.
- CTA **“Ver planos”** (ou equivalente) via rota existente (`/planos` / Meu Plano) —
  `context.go` / `context.push`; sem rota nova; sem FAB local.
- Host preferencial: feedback pós-sync do Desenho ou sheet já aberto (definir na implementação
  sem AppBar fixa).
- Não exibir isenções técnicas (case/produtor) ao usuário final.

### 7. Documentação e testes

- `docs/case.md` permanece fonte de produto; este ADR é fonte de engenharia.
- Testes de paridade: mesmos números cliente/servidor para Bronze/Prata/Ouro/Grátis/admin.
- Testes de isenção: `drawing_id` em case; `cliente_id` em vínculo com `share_fields`.

## Não-objetivos

- Hard delete de talhões na nuvem para “caber” no plano.
- `999999` ou outro inteiro sentinela para ilimitado.
- `drawing/` importar `planos/` ou `marketing/` importar `drawing/` fora dos contratos.
- Consumir cota em espelhos read-only do produtor.

## Consequências

- Fases 2–5 dependem deste ADR; merge de código de sync exige path crítico `drawing/` + ok.
- `AGENTS.md` ganha entrada ADR-066 e linha de contrato `IDrawingSyncQuota`.
- Até fase 3 concluir, copy em Meu Plano continua correta como promessa; enforcement só após entrega.

## Referências

- `docs/case.md` — tabela de talhões sincronizados
- ADR-012 (planos), ADR-037 (DrawingRemoteStore), ADR-064 (`marketing_cases.drawing_id`)
- `INdviRefinedEntitlement` — padrão de contrato
- `ProducerLinkedDrawingSyncService`, `producer_client_links`