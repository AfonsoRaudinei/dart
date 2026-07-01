# Build de Release — SoloForte App

## Pré-requisitos

- Flutter SDK estável
- Xcode 15+ (iOS) — **obrigatório para IPA**
- Android Studio / JDK 17 (Android)
- Conta Apple Developer e Google Play Console

---

## Chaves Supabase no build (obrigatório)

O app usa `String.fromEnvironment` — as chaves são **compiladas no binário** via `--dart-define`.
Se o IPA/AAB for gerado **sem** essas variáveis, o Supabase **não inicializa** (erro observado no build 152).

### Passo 1 — Criar `dart_defines.json` (local, não commitar)

```bash
cp dart_defines.example.json dart_defines.json
```

Edite `dart_defines.json`:

```json
{
  "SUPABASE_URL": "https://pyoejhhkjlrjijiviryq.supabase.co",
  "SUPABASE_ANON_KEY": "SUA_ANON_KEY_REAL"
}
```

> Nunca commitar `dart_defines.json` — já está no `.gitignore`.

### Passo 2 — Build com script (recomendado)

```bash
# iOS — build 153 (macOS + Xcode)
chmod +x scripts/build_ipa.sh
./scripts/build_ipa.sh 153

# Android
chmod +x scripts/build_appbundle.sh
./scripts/build_appbundle.sh 153
```

### Alternativa — comando manual

```bash
flutter build ipa \
  --build-number=153 \
  --dart-define-from-file=dart_defines.json
```

---

## Variáveis opcionais

| Variável | Default |
|----------|---------|
| `PRIVACY_POLICY_URL` | GitHub raw política |
| `TERMS_URL` | GitHub raw termos |
| `LGPD_CONTACT_EMAIL` | privacidade@soloforte.app |

---

## Supabase — SQL no Dashboard

Execute antes do primeiro login em produção:

1. `supabase_schema.sql`
2. `supabase/auth_delete_account.sql`
3. `supabase/feedback_table.sql`

Guia: [`docs/SUPABASE_MANUAL.md`](SUPABASE_MANUAL.md)

---

## Android — assinatura release

1. Gere o keystore (uma vez):

```bash
keytool -genkey -v \
  -keystore android/keystore/soloforte-release.jks \
  -alias soloforte \
  -keyalg RSA -keysize 2048 -validity 10000
```

2. Copie `android/key.properties.example` → `android/key.properties`
3. `./scripts/build_appbundle.sh 153`

---

## iOS — distribuição

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Bundle Identifier: `com.soloforte.app`
3. Certificado **Apple Distribution** + provisioning App Store
4. `./scripts/build_ipa.sh 153`

Saída: `build/ios/ipa/*.ipa`

---

## Checklist pós-build (build 153+)

- [ ] Login com conta Supabase real
- [ ] Cadastro com confirmação de e-mail (se habilitada)
- [ ] Sync após criar cliente offline → reconectar
- [ ] Feedback in-app
- [ ] Exclusão de conta em Configurações
- [ ] Mapa, visitas e ocorrências offline inalterados

---

## Versionamento

| Campo | Valor atual |
|-------|-------------|
| Version name | `1.0.0` (`pubspec.yaml`) |
| Build number | `153` |

Incrementar build number a cada submissão TestFlight/App Store.
