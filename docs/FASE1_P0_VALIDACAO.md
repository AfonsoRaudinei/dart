# Fase 1 P0 — Checklist de validação

Use este checklist para confirmar que a Fase 1 foi executada conforme o PRD.

## ÉPICO 1 — Autenticação

- [ ] `Supabase.initialize()` em `main.dart` com `--dart-define`
- [ ] `AuthService` usa Supabase Auth (não fake)
- [ ] Token em `flutter_secure_storage`
- [ ] Validação e-mail/senha/nome nos formulários
- [ ] Mensagens de erro amigáveis (`mapAuthError`)
- [ ] Exclusão de conta em Configurações
- [ ] Logout chama `signOut()` do Supabase

## ÉPICO 3 — Legal

- [ ] `docs/legal/politica-de-privacidade.md` publicado
- [ ] `docs/legal/termos-de-servico.md` publicado
- [ ] Links funcionais em Configurações e cadastro
- [ ] Checkbox de consentimento no signup

## ÉPICO 4 — Permissões

- [ ] iOS: GPS when-in-use, câmera, galeria
- [ ] iOS: `PrivacyInfo.xcprivacy` no target Runner
- [ ] Android: POST_NOTIFICATIONS, CAMERA, READ_MEDIA_IMAGES
- [ ] Background location removida (Android + iOS Always)
- [ ] `NotificationService.init()` no startup

## ÉPICO 5 — Build

- [ ] Bundle ID `com.soloforte.app` (iOS + Android)
- [ ] Label Android `SoloForte`
- [ ] Release signing via `key.properties`
- [ ] ProGuard/R8 habilitado em release
- [ ] `docs/BUILD_RELEASE.md` documentado

## BUGs P0

- [ ] BUG-01: migração SQLite v1→v5 sem duplicata
- [ ] BUG-02: `syncServiceProvider` instanciado via `AppBootstrap`
- [ ] BUG-03: notificações inicializadas no startup

## Gate Fase 1

- [ ] `flutter analyze` sem erros
- [ ] `flutter test` passando
- [ ] Login real com Supabase configurado
- [ ] Mapa / visitas / ocorrências sem regressão de comportamento
