# Auditoria de Segurança — 2026-06-04

## Escopo

Correção e confirmação dos pontos fracos identificados em:

- Supabase RLS de marketing.
- Storage público `marketing-cases`.
- Chaves reais em arquivos locais.
- WebView com JavaScript irrestrito.
- SQLite local e risco de extração por backup.
- Edge Function `delete-user`.
- `role` definido pelo cliente no cadastro.

## Resultado Executivo

Status geral: **endurecido para os vetores remotos críticos**.

Os riscos de alteração indevida por usuário autenticado comum foram fechados no código e nas migrations. O banco local teve backup/extração Android bloqueados. Permanecem duas ações que exigem ambiente externo: rotacionar chaves nos provedores e planejar migração real para SQLCipher se o requisito for criptografia local forte contra dispositivo comprometido.

## Correções Confirmadas

### 1. Supabase RLS de marketing

Status: **corrigido**.

Arquivos:

- `supabase/migrations/20260228120000_marketing_cases.sql`
- `supabase/migrations/20260228130000_marketing_cases_rls_write.sql`
- `supabase/migrations/20260604000000_security_hardening_marketing.sql`
- `soloforte_db_setup.sql`
- `lib/modules/marketing/data/repositories/marketing_case_repository_impl.dart`

Confirmação:

- `marketing_cases` e `marketing_avaliacoes` agora possuem `user_id`.
- INSERT/UPDATE exigem `auth.uid() = user_id`.
- Avaliações só podem ser gravadas quando pertencem ao mesmo usuário do case pai.
- O app envia `user_id` no upsert de case e avaliações.
- O setup SQL manual também usa `WITH CHECK` nas policies `FOR ALL`.
- A busca por `USING (true)` e `WITH CHECK (true)` nos scripts corrigidos não retornou policies abertas.

### 2. Storage `marketing-cases`

Status: **corrigido**.

Arquivos:

- `supabase/migrations/20260228140000_marketing_cases_storage_bucket.sql`
- `supabase/migrations/20260604000000_security_hardening_marketing.sql`
- `lib/modules/marketing/data/services/marketing_photo_service.dart`

Confirmação:

- Upload e delete exigem que o primeiro segmento do path seja `auth.uid()`.
- O app grava fotos em `userId/...`.
- A leitura pública foi preservada para manter o mapa público e URLs existentes.

### 3. Chaves reais em arquivos locais

Status: **saneado localmente; rotação externa obrigatória**.

Arquivos:

- `.env.local`
- `.env.local.json`

Confirmação:

- Valores reais foram substituídos por placeholders.
- `git ls-files` confirma que os arquivos locais não estão versionados.
- A rotação deve ser feita nos painéis dos provedores antes de novos builds reais.

### 4. WebView de relatórios

Status: **corrigido**.

Arquivo:

- `lib/core/html_templates/html_report_viewer.dart`

Confirmação:

- `JavaScriptMode.unrestricted` foi removido.
- Relatórios HTML agora carregam com `JavaScriptMode.disabled`.
- Os renderers existentes continuam usando escape HTML para campos dinâmicos.

### 5. SQLite local

Status: **mitigado contra backup/transfer; criptografia forte pendente**.

Arquivos:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/res/xml/backup_rules.xml`
- `android/app/src/main/res/xml/data_extraction_rules.xml`

Confirmação:

- `android:allowBackup="false"` configurado.
- Cloud backup e device transfer excluem `database`, `sharedpref` e `file`.

Limite confirmado:

- O projeto ainda usa `sqflite`; isso não fornece SQLCipher.
- Para criptografia local forte, criar ADR e migração controlada para `sqflite_sqlcipher` ou equivalente, com chave em Keystore/Keychain e plano de migração do arquivo `soloforte.db`.

### 6. Edge Function `delete-user`

Status: **corrigido no cliente e confirmado no servidor versionado**.

Arquivos:

- `lib/core/session/session_controller.dart`
- `supabase/functions/delete-user/index.ts`

Confirmação:

- O app não envia mais `body: {'user_id': ...}`.
- A function versionada valida o JWT via `supabaseAdmin.auth.getUser(jwt)`.
- O `userId` usado para exclusão vem do usuário autenticado, não do body.

### 7. Role no cadastro

Status: **corrigido**.

Arquivos:

- `lib/modules/auth/services/auth_service.dart`
- `lib/core/session/session_controller.dart`

Confirmação:

- O app não envia mais `role` em `signUp`.
- `_completeProfile` não grava `role` vindo do formulário.
- A atribuição de papel fica sob responsabilidade do backend/defaults.

## Validações Executadas

- Busca por policies abertas nos scripts corrigidos.
- Busca por `JavaScriptMode.unrestricted`.
- Busca por envio de `user_id` para `delete-user`.
- Busca por uso de `dto.role` em metadata/profile.
- Conferência dos arquivos Android de backup/extração.
- Conferência da Edge Function `delete-user`.

## Ações Externas Obrigatórias

1. Rotacionar as chaves expostas nos provedores.
2. Aplicar a migration `20260604000000_security_hardening_marketing.sql` no Supabase.
3. Redeploy da Edge Function `delete-user` se o ambiente remoto estiver diferente do arquivo versionado.
4. Decidir via ADR se o requisito do SQLite é mitigação de backup ou criptografia local forte com SQLCipher.

## Conclusão

Os vetores exploráveis remotamente por usuário autenticado comum foram fechados no código versionado. O projeto está em estado seguro para RLS/Storage/Auth/WebView após aplicação das migrations e redeploys correspondentes. O único ponto que não pode ser declarado como criptografia local forte é o SQLite, porque isso exige troca de engine e migração dedicada.
