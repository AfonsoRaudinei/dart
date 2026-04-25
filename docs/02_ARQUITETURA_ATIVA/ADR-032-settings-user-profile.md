# ADR-032 — Settings: Perfil do Usuário Completo, Editável e Auditável

**Status:** Aprovado  
**Data:** Abr/2026  
**Módulo:** `settings` (bounded context satélite — sem dependências cruzadas)  
**DB:** v29 → v30  
**Branch:** release/v1.1

---

## Contexto

O módulo `settings` existia estruturalmente vazio em termos de perfil de usuário: apenas `ProfileState` com `imagePath` e `useAsAppIcon`. O `accountProfileProvider` em `settings_providers.dart` fazia leitura simples do Supabase Auth + tabela `perfis`, mas sem cache local, sem edição e sem rastreabilidade de alterações.

Os dados do login (nome, telefone, CREA) nunca foram bridgeados para a tela de configurações de forma estruturada.

---

## Decisão

Implementar três capacidades dentro do bounded context `settings`:

1. **Exibição completa** dos dados do usuário autenticado via `userProfileProvider` (Riverpod codegen, autoDispose), com cache SQLite offline-first.
2. **Edição** dos campos editáveis (`fullName`, `phone`, `photoUrl`, `creaNumber`) via `edit_profile_screen.dart`, aberta como `Navigator.push` sem criar nova rota no GoRouter.
3. **Trilha de auditoria local** append-only: cada campo alterado gera 1 entrada em `user_profile_edits` (SQLite), nunca deletada.

---

## Arquivos criados / modificados

### Novos
| Arquivo | Descrição |
|---|---|
| `settings/domain/entities/user_profile.dart` | Entidade imutável com `copyWith` |
| `settings/domain/repositories/i_user_profile_repository.dart` | Interface do repositório |
| `settings/data/models/user_profile_audit_entry.dart` | Modelo com `toMap`/`fromMap` |
| `settings/data/repositories/user_profile_repository_impl.dart` | Implementação (Supabase + SQLite) |
| `settings/presentation/providers/user_profile_provider.dart` | Riverpod codegen autoDispose |
| `settings/presentation/screens/edit_profile_screen.dart` | Tela de edição (sem rota nova) |
| `settings/presentation/widgets/profile_field_tile.dart` | Widget de exibição de campo |
| `settings/presentation/widgets/audit_trail_widget.dart` | Lista de auditoria |

### Modificados
| Arquivo | Mudança |
|---|---|
| `core/database/database_helper.dart` | v29 → v30: tabelas `user_profile_cache` e `user_profile_edits` |
| `settings/presentation/screens/settings_screen.dart` | Integração com `userProfileProvider`; seção "Histórico de alterações" |
| `settings/presentation/providers/settings_providers.dart` | Remoção de `AccountProfileData` e `accountProfileProvider` (absorvidos) |

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
| `id`, `email`, `createdAt` | Supabase Auth | — (somente leitura) |
| `fullName`, `phone`, `role`, `photoUrl` | Supabase tabela `perfis` | SQLite cache |
| `creaNumber` | Supabase `userMetadata['crea_number']` | SQLite cache |

**Merge rule:** cache local prevalece se `updated_at` local > remoto (`sync_status = 1`).

---

## Campos editáveis vs somente leitura

| Campo | Editável | Destino da edição |
|---|---|---|
| `id` | ❌ | — |
| `email` | ❌ | — |
| `createdAt` | ❌ | — |
| `role` | ❌ | — |
| `fullName` | ✅ | `perfis.name` + cache |
| `phone` | ✅ | `perfis.phone` + cache |
| `photoUrl` | ✅ | Storage Supabase (fluxo existente) |
| `creaNumber` | ✅ | `userMetadata` Supabase Auth |

---

## Regras de Auditoria

- Cada campo editado = 1 entrada na tabela `user_profile_edits`
- Múltiplos campos na mesma edição = múltiplas entradas com mesmo `changedAt`
- Append-only: sem `DELETE`, sem `UPDATE` na tabela de auditoria
- UI exibe últimas 20 entradas em ordem cronológica reversa

---

## Offline-First

1. Edição persiste em `user_profile_cache` com `sync_status = 1` imediatamente
2. Auditoria é gerada mesmo offline
3. Sync com Supabase ocorre quando online (manual nesta versão; `SyncOrchestrator` em v31+)

---

## Restrições

- ❌ Nenhuma rota nova no GoRouter — `edit_profile_screen` abre via `Navigator.push`
- ❌ Nenhuma coluna nova na tabela `perfis` — `crea_number` vai apenas em `userMetadata`
- ❌ Nenhuma dependência cruzada entre módulos — `settings` permanece satélite
- ❌ Nenhum `ALTER TABLE` em tabelas existentes — apenas novas tabelas em v30

---

## Consequências

- `accountProfileProvider` e `AccountProfileData` removidos de `settings_providers.dart` após integração
- `settings_screen.dart` passa a usar `currentUserProfileProvider` (codegen)
- `ProfileState` em `settings_models.dart` permanece (gerencia foto/ícone app — escopo diferente)

---

*ADR-032 aprovado — Engenheiro Sênior Flutter/Dart — Abr/2026*
