# Fase 3 — Validação SoloForte

Checklist de validação para o gate de release da Fase 3.

---

## Gate Manual: Executar SQL no Supabase

Este é o passo obrigatório antes de qualquer teste de login real ou geração de build de release.

**→ [docs/SUPABASE_MANUAL.md](SUPABASE_MANUAL.md) — Guia completo de configuração Supabase**

### Ordem de execução (resumo)

| # | Script | O que cria | Status |
|---|---|---|---|
| 1 | `supabase_schema.sql` | 7 tabelas + RLS | ☐ |
| 2 | `supabase/auth_delete_account.sql` | RPC `delete_own_account()` | ☐ |
| 3 | `supabase/feedback_table.sql` | Tabela `feedback` | ☐ |
| 4 | Queries de verificação | Confirmação: 8 tabelas, 1 função | ☐ |

Execute o SQL de verificação antes de prosseguir:

```sql
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'clients','farms','fields','visit_sessions',
    'occurrences','visit_reports','agenda_events','feedback'
  )
ORDER BY tablename;

SELECT proname FROM pg_proc WHERE proname = 'delete_own_account';
```

**Critério de aprovação:** 8 tabelas retornadas + função presente.

---

## Gate Manual: Configurar flutter run

Após configurar o Supabase, execute o app com as variáveis de ambiente:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://pyoejhhkjlrjijiviryq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```

Ver seção 8 de [SUPABASE_MANUAL.md](SUPABASE_MANUAL.md) para detalhes completos.

---

## Checklist de Validação Funcional

| # | Ação | Depende de | ☐/✓ |
|---|---|---|---|
| 1 | Login com e-mail válido | Supabase configurado + Auth habilitado | ☐ |
| 2 | Cadastro de novo usuário | Supabase + Auth | ☐ |
| 3 | Criar cliente e fazenda | Script 1 (schema) | ☐ |
| 4 | Sync offline → online | Script 1 + login | ☐ |
| 5 | Excluir conta | Script 2 (delete_own_account) | ☐ |
| 6 | Enviar feedback pelo app | Script 3 (feedback) + login | ☐ |
| 7 | GPS e mapa funcionando | Permissão de localização | ☐ |
| 8 | Build Android release | `key.properties` configurado | ☐ |
| 9 | Build iOS release | Certificado Apple Distribution | ☐ |

---

## Gates Não Automatizáveis

| Ação | Responsável | Documentação |
|---|---|---|
| SQL no Supabase | Dev (manual) | [SUPABASE_MANUAL.md](SUPABASE_MANUAL.md) |
| Android keystore | Dev (local) | [BUILD_RELEASE.md](BUILD_RELEASE.md) |
| Certificado iOS | Dev (Xcode) | [BUILD_RELEASE.md](BUILD_RELEASE.md) |
| URLs legais HTTPS | Dev (hosting) | `docs/legal/` |
| Conta demo revisores | Dev (Supabase) | [SUPABASE_MANUAL.md](SUPABASE_MANUAL.md) seção 7.3 |

---

## Referências

- [SUPABASE_MANUAL.md](SUPABASE_MANUAL.md) — Configuração completa do Supabase
- [BUILD_RELEASE.md](BUILD_RELEASE.md) — Build Android e iOS
- [store/GUIA_SUBMISSAO.md](store/GUIA_SUBMISSAO.md) — Submissão às lojas
- [SMOKE_TEST_CHECKLIST.md](SMOKE_TEST_CHECKLIST.md) — Smoke test completo
