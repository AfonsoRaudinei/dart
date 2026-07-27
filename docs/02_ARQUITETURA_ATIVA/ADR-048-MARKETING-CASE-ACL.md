# ADR-048 — Marketing case ACL (edit / soft-delete / cross-approval)

**Status:** ATIVO  
**Data:** Jul/2026  
**Relacionados:** ADR-011 · ADR-041 · marketing visibility Ouro/Prata/Bronze

## Contexto

O sheet do pin de marketing era somente leitura. Produto exige:

- **Owner** edita e exclui (soft) o próprio case.
- **Contraparte vinculada** (produtor↔consultor via `client_id`) pode
  **propor** edição; o owner aprova ou rejeita.
- **Público** vê apenas o visual de resultado (sem ações).

## Decisão

1. Policy pura `MarketingCaseAccessPolicy` (domínio marketing) com:
   `canEditDirect`, `canProposeEdit`, `canApproveEdit`, `canSoftDelete`.
2. Vínculo via `client_id` + `linkedClientIds` (produtor: ADR-041;
   consultor: IDs de `IClientLookup.listAtivos()`).
3. Campos em `marketing_cases` + cache JSON:
   - `pending_edit_json` (payload proposto)
   - `pending_edit_by`
   - `pending_edit_at`
4. Status de ciclo: adicionar `pending_approval` ao enum (publicado
   permanece visível no mapa enquanto aguarda).
5. Soft-delete: `deletado_em` + `sync_status=pending_sync` — nunca hard delete.
6. Sheet: um `showSoloForteSheet` (sem `DraggableScrollableSheet` aninhado);
   hero de resultado compartilhado com superfície pública.

## Não-objetivos

- TTL / liberação pública (plano IPA171) — débito separado.
- Reescrever marker pin / zoom por tier.
- Hard delete sincronizável.

## Consequências

- Migration Supabase obrigatória antes do sync remoto dos novos campos.
- Cache SQLite JSON absorve campos via `toJson`/`fromJson`.
- Testes unitários da policy são a fonte da regra de negócio.
