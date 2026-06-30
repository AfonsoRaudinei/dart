# Fase 2 P1 — Checklist de validação

## ÉPICO 2 — Sync Supabase

- [ ] `RemoteSyncService` sincroniza agronômico + visitas + ocorrências + relatórios + agenda
- [ ] Push marca `sync_status = 0` após sucesso
- [ ] Pull respeita last-write-wins com local dirty
- [ ] `SyncService` respeita modo offline forçado
- [ ] Contador de pendentes em Configurações

## ÉPICO 8 — RLS

- [ ] `supabase_schema.sql` com `user_id` e políticas `auth.uid()`
- [ ] Push injeta `user_id` do usuário autenticado

## ÉPICO 6/7 — Placeholders

- [ ] BUG-04: edição de ocorrência via pin no mapa
- [ ] BUG-05: limpar dados locais funcional
- [ ] FEAT-01: tela Agenda com listar/criar/editar
- [ ] FEAT-03: modo offline persiste preferência
- [ ] FEAT-04: limpar cache funcional

## ÉPICO 9 — QA

- [ ] Testes unitários auth/sync/validators
- [ ] CI GitHub Actions (`flutter analyze` + `flutter test`)
- [ ] Migração SQLite v6 (occurrences + reports + agenda updated_at)

## Gate Fase 2

- [ ] Operação offline intacta (mapa → visita → ocorrência)
- [ ] Sync ao reconectar com Supabase configurado
- [ ] `flutter test` passando
