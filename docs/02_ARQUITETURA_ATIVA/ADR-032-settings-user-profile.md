# ADR-032 — Settings: Perfil do Usuário Completo, Editável e Auditável

**Status:** ENCERRADO  
**Data:** Abr/2026  
**Módulo:** `settings`  
**DB:** v29 → v30  
**Substitui:** `accountProfileProvider` (removido)

---

## Contexto

O módulo `settings` exibia dados parciais do usuário via `accountProfileProvider`, que lia
`supabase.auth.currentUser` + tabela `perfis` diretamente no provider, sem cache local,
sem entidade de domínio, sem possibilidade de edição e sem trilha de auditoria.

**Problemas identificados:**
- `ProfileState` (domain/settings_models.dart) continha apenas `photoUrl`
- `crea_number` não existe na tabela `perfis` do Supabase — apenas `name`, `phone`, `role`, `photo_url`
- Nenhuma escrita era possível a partir da tela de configurações
- Nenhum registro de quem alterou o quê e quando

---

## Decisão

1. **Criar** entidade `UserProfile` em `settings/domain/entities/`
2. **Criar** interface `IUserProfileRepository` em `settings/domain/repositories/`
3. **Criar** `UserProfileRepositoryImpl` em `settings/data/repositories/` — absorve lógica do `accountProfileProvider`
4. **Criar** `UserProfileAuditEntry` em `settings/data/models/`
5. **Criar** provider `userProfileProvider` (Riverpod codegen) — substitui `accountProfileProvider`
6. **Remover** `accountProfileProvider` de `settings_providers.dart` após integração
7. **Criar** `edit_profile_screen.dart` acessível via modal/push da `settings_screen.dart`
8. **Migrar** DB para v30: tabelas `user_profile_cache` + `user_profile_edits`
9. **`crea_number`** salvo apenas em `userMetadata` do Supabase Auth — sem ALTER em `perfis`

---

## Contrato de Campos

| Campo | Fonte | Editável | Observação |
|---|---|---|---|
| `id` | Supabase Auth uid | NÃO | somente leitura |
| `email` | Supabase Auth email | NÃO | somente leitura |
| `fullName` | tabela `perfis`.name + userMetadata | SIM | |
| `phone` | tabela `perfis`.phone | SIM | |
| `role` | tabela `perfis`.role | NÃO | gerenciado pelo backend |
| `photoUrl` | tabela `perfis`.photo_url | SIM | Supabase Storage |
| `creaNumber` | userMetadata apenas | SIM | tabela `perfis` não tem coluna |
| `createdAt` | Supabase Auth createdAt | NÃO | somente leitura |

---

## Schema SQLite v30

### `user_profile_cache`

```sql
CREATE TABLE user_profile_cache (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  role TEXT,
  photo_url TEXT,
  crea_number TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status INTEGER NOT NULL DEFAULT 0
);
```

### `user_profile_edits` (append-only — nunca deletar)

```sql
CREATE TABLE user_profile_edits (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  field_changed TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT NOT NULL,
  changed_at TEXT NOT NULL
);
```

Padrão: `DROP TABLE IF EXISTS` + `CREATE TABLE` (idempotente, conforme histórico do projeto).

---

## Fonte da Verdade

| Campo | Fonte primária | Fallback |
|---|---|---|
| `id`, `email`, `createdAt` | Supabase Auth | — somente leitura |
| `fullName`, `phone`, `role`, `photoUrl` | Supabase tabela `perfis` | SQLite cache |
| `creaNumber` | Supabase `userMetadata['crea_number']` | SQLite cache |

**Merge rule:** cache local prevalece se `updated_at` local > remoto (`sync_status = 1`).

---

## Trilha de Auditoria

- Append-only — nunca deletar entradas
- 1 entrada por campo alterado por save
- Exibir últimas 20 na `settings_screen.dart`
- Schema SQLite: `user_profile_edits` (v30)

---

## Offline-First

1. Edição persiste em `user_profile_cache` com `sync_status = 1` imediatamente
2. Auditoria é gerada mesmo offline
3. Sync com Supabase ocorre quando online (manual nesta versão; `SyncOrchestrator` em v31+)

---

## Consequências

- `accountProfileProvider` removido — **breaking change intencional e controlado**
- `settings_screen.dart` migra para `currentUserProfileProvider`
- `side_menu_overlay.dart` migra para `currentUserProfileProvider`
- `arch_check.sh` não é afetado — settings permanece bounded context satélite
- Retrocompatível: novas tabelas, sem ALTER em tabelas existentes
- DB v30 idempotente (DROP + CREATE)

---

## Arquivos Afetados

```
CRIADOS:
  lib/modules/settings/domain/entities/user_profile.dart
  lib/modules/settings/domain/repositories/i_user_profile_repository.dart
  lib/modules/settings/data/repositories/user_profile_repository_impl.dart
  lib/modules/settings/data/models/user_profile_audit_entry.dart
  lib/modules/settings/presentation/providers/user_profile_provider.dart
  lib/modules/settings/presentation/screens/edit_profile_screen.dart
  lib/modules/settings/presentation/widgets/profile_field_tile.dart
  lib/modules/settings/presentation/widgets/audit_trail_widget.dart

MODIFICADOS:
  lib/core/database/database_helper.dart          ← migração v30
  lib/modules/settings/presentation/providers/settings_providers.dart ← removido accountProfileProvider
  lib/modules/settings/presentation/screens/settings_screen.dart ← integrado novo provider + auditoria
  lib/ui/components/side_menu_overlay.dart ← migrado para currentUserProfileProvider
```

---

## Status de Implementação

- [x] GATE 2 — ADR-032 criado
- [x] GATE 3 — DB v29 → v30 (`user_profile_cache`, `user_profile_edits`)
- [x] GATE 4 — Entidade + Interface + Repositório + Provider compilando
- [x] GATE 5 — `settings_screen.dart` exibe dados reais via `currentUserProfileProvider`
- [x] GATE 6 — `edit_profile_screen.dart` salva + gera auditoria
- [x] GATE 7 — `accountProfileProvider` removido (`grep` retorna zero referências)
- [x] GATE 8 — `arch_check.sh` Exit 0 — `flutter analyze` 0 novos erros

---

## Encerramento

Data: 30/05/2026
Motivo: Módulo implementado e funcional.
Implementado em: lib/modules/settings/
Gaps registrados como dívida técnica:
- Campo `especialidade` ausente (baixa prioridade)
- Retry de sync pendente (baixa prioridade)

---

*ADR-032 — SoloForte App — Abr/2026*
