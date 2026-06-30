# Build Release — SoloForte

Guia para gerar builds de release para Android e iOS.

## Pré-requisito: Supabase configurado

Antes de gerar qualquer build de release, o banco de dados Supabase deve estar
completamente configurado com os 3 scripts SQL.

**→ [docs/SUPABASE_MANUAL.md](SUPABASE_MANUAL.md) — Guia completo de configuração Supabase**

---

## Android

### 1. Gerar keystore

```bash
keytool -genkey -v \
  -keystore android/app/soloforte-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias soloforte
```

### 2. Configurar `key.properties`

Copie o template e preencha com seus dados:

```bash
cp android/key.properties.example android/key.properties
```

Edite `android/key.properties`:

```properties
storePassword=SUA_SENHA_KEYSTORE
keyPassword=SUA_SENHA_KEY
keyAlias=soloforte
storeFile=soloforte-release.jks
```

> ⚠️ O arquivo `key.properties` está no `.gitignore` — nunca commite credenciais.

### 3. Build release

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://pyoejhhkjlrjijiviryq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY

# Ou AAB para Google Play
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://pyoejhhkjlrjijiviryq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```

---

## iOS

### 1. Certificado Apple Distribution

1. Abra o Xcode → **Signing & Capabilities**
2. Selecione o **Team** correto (Apple Developer Program)
3. Certifique-se de ter o certificado **Apple Distribution** instalado no Keychain

### 2. Build release

```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://pyoejhhkjlrjijiviryq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```

> O processo de assinatura e upload para a App Store Connect deve ser feito
> pelo Xcode (**Product → Archive**) ou pelo Transporter.

---

## Variáveis de ambiente de produção

Ver seção 8 de [docs/SUPABASE_MANUAL.md](SUPABASE_MANUAL.md) para a lista completa
de `--dart-define` disponíveis (`PRIVACY_POLICY_URL`, `TERMS_URL`, `LGPD_CONTACT_EMAIL`).

---

## Referências

- [SUPABASE_MANUAL.md](SUPABASE_MANUAL.md) — Configuração do banco de dados
- [store/GUIA_SUBMISSAO.md](store/GUIA_SUBMISSAO.md) — Submissão às lojas
- [Documentação Flutter — Build iOS](https://docs.flutter.dev/deployment/ios)
- [Documentação Flutter — Build Android](https://docs.flutter.dev/deployment/android)
