# Build de Release — SoloForte App

## Pré-requisitos

- Flutter SDK estável
- Xcode 15+ (iOS)
- Android Studio / JDK 17 (Android)
- Conta Apple Developer e Google Play Console

## Variáveis de ambiente (`--dart-define`)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY \
  --dart-define=PRIVACY_POLICY_URL=https://SEU_DOMINIO/politica-de-privacidade \
  --dart-define=TERMS_URL=https://SEU_DOMINIO/termos-de-servico \
  --dart-define=LGPD_CONTACT_EMAIL=privacidade@soloforte.app
```

> Nunca commitar `SUPABASE_ANON_KEY` em arquivos versionados.

## Supabase — exclusão de conta

Execute `supabase/auth_delete_account.sql` no SQL Editor do projeto Supabase antes de liberar a funcionalidade de exclusão in-app.

## Android — assinatura release

1. Gere o keystore:

```bash
keytool -genkey -v \
  -keystore android/keystore/soloforte-release.jks \
  -alias soloforte \
  -keyalg RSA -keysize 2048 -validity 10000
```

2. Copie `android/key.properties.example` para `android/key.properties` e preencha os valores.
3. Build:

```bash
flutter build appbundle \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

O `build.gradle.kts` usa `key.properties` quando presente; caso contrário, fallback para debug (apenas desenvolvimento local).

## iOS — distribuição

1. Abra `ios/Runner.xcworkspace` no Xcode.
2. Confirme **Bundle Identifier:** `com.soloforte.app`
3. Selecione certificado **Apple Distribution** e provisioning profile App Store.
4. Build:

```bash
flutter build ipa \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## Bundle ID unificado

- **iOS:** `com.soloforte.app`
- **Android:** `com.soloforte.app`

## Checklist pós-build

- [ ] Login com conta real Supabase
- [ ] Cadastro com confirmação de e-mail (se habilitada)
- [ ] Exclusão de conta em Configurações
- [ ] Links de Política e Termos abrem no navegador
- [ ] Permissões GPS, câmera, galeria e notificações solicitadas corretamente
- [ ] Mapa, visitas e ocorrências offline inalterados