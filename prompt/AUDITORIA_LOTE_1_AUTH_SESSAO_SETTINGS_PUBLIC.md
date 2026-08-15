# SOLOFORTE — AUDITORIA LOTE 1 — AUTH, SESSAO, SETTINGS E PUBLIC

**Modo:** READ-ONLY. Nenhum código de app foi alterado.  
**Bounded contexts:** `auth`, `settings`, `public`, `core/session`  
**Prioridade:** P0  
**Data:** 2026-08-10  

## Arquivos Avaliados

- `lib/modules/auth/AGENTS.md`
- `lib/modules/settings/AGENTS.md`
- `lib/modules/public/AGENTS.md`
- `lib/core/session/session_controller.dart`
- `lib/core/session/local_session_identity.dart`
- `lib/core/router/app_router.dart`
- `lib/modules/auth/services/auth_service.dart`
- `lib/modules/settings/presentation/providers/settings_providers.dart`
- `lib/ui/screens/public_map_screen.dart`
- `docs/SUPABASE_MANUAL.md`

## Limites

- Nao valida RLS publicada no Supabase.
- Nao valida comportamento de OAuth em navegador real.
- Nao valida cold start em device físico.

## Achados

```yaml
🟡 [Severidade: Média]
Categoria: A
Localização: lib/core/session/session_controller.dart:375-380
Problema: O logout invalida providers e limpa LocalSessionIdentity antes de aguardar o signOut do Supabase.
Risco: Se `signOut` falhar, o app pode ficar com sessão remota ainda ativa e identidade local limpa, criando estado inconsistente entre Auth, cache local e providers.
Direção da correção (conceitual, sem código): Definir uma sequência transacional para logout: preservar identidade até o resultado do signOut ou tratar rollback/estado de falha explicitamente.
Evidência: `_invalidateUserScopedProviders(); LocalSessionIdentity.clear(); await Supabase.instance.client.auth.signOut();`
Validação necessária: teste de logout com falha simulada de Supabase Auth.
```

```yaml
🟡 [Severidade: Média]
Categoria: B
Localização: lib/modules/settings/presentation/providers/settings_providers.dart:15-133
Problema: Settings ainda usa `StateNotifierProvider` para perfil, branding e tema, enquanto a regra global privilegia Riverpod moderno e whitelist ADR-044.
Risco: Novas alterações podem perpetuar padrão legado e fugir do contrato atual de estado previsível.
Direção da correção (conceitual, sem código): Confirmar se estes notifiers estão na whitelist ADR-044; se não estiverem, planejar migração incremental para providers modernos sem alterar o tema global fora de aprovação.
Evidência: `ProfileNotifier`, `ReportBrandingNotifier` e `ThemeNotifier` estendem `StateNotifier`.
Validação necessária: leitura da ADR-044 + testes de settings/profile.
```

```yaml
🟡 [Severidade: Média]
Categoria: D
Localização: lib/modules/auth/services/auth_service.dart:293-315
Problema: Erros de upload/atualização de perfil são registrados com `AppLogger.error`, que sempre registra em release.
Risco: Dependendo do conteúdo do erro de storage/Postgrest, detalhes operacionais podem aparecer em logs de produção; a sanitização persistida cobre mensagem, mas `developer.log` recebe o objeto de erro.
Direção da correção (conceitual, sem código): Padronizar logging seguro para auth/profile, evitando anexar payloads completos de erro quando houver risco de URL, path de storage, id ou metadados pessoais.
Evidência: `AppLogger.error('Erro no upload de avatar', tag: 'AuthService', error: e);`
Validação necessária: teste/unit de sanitização + revisão manual de logs em build profile/release.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: A
Localização: lib/core/session/session_controller.dart:36-51
Problema: Nenhum vazamento de subscription de auth foi identificado.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Nenhuma.
Evidência: `_authSubscription` é cancelada no `ref.onDispose`.
Validação necessária: teste de dispose do provider.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: D
Localização: lib/core/session/local_session_identity.dart:21-38
Problema: O fallback de último usuário conhecido tem trava explícita para sessão pública.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Manter testes de bootstrap/cold start cobrindo `SessionUnknown` e `signedOut`.
Evidência: `if (!allowLastKnown || _sessionKnownPublic) return '';`
Validação necessária: teste de cold start com sessão restaurada e logout real.
```

```yaml
🟢 [Severidade: Baixa]
Categoria: E
Localização: lib/core/router/app_router.dart:63-112
Problema: Redirect de rota privada/publica tem decisão centralizada e testável.
Risco: Sem risco identificado dentro do escopo avaliado.
Direção da correção (conceitual, sem código): Manter testes de SessionUnknown, SessionPublic, authenticated e password recovery.
Evidência: redirect central lê `sessionControllerProvider`, `notifier.isAuthenticated` e `AppAccess.canAccessPath`.
Validação necessária: testes de router/auth.
```

## RESUMO

Lote auditado: 1 — Auth, Sessao, Settings e Public  
Bounded contexts: auth, settings, public, core/session  
Arquivos avaliados: 10  
Total de achados: 6  
Alta severidade: 0  
Média severidade: 3  
Baixa severidade: 3  
Achados que exigem ADR novo: 0, mas 1 exige confirmar whitelist ADR-044  
Achados que dependem de backend/RLS/device/build real: 2  
Nenhuma alteração de código foi feita — apenas diagnóstico.
