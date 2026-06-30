# Apple App Store — App Privacy (Nutrition Labels)

Preencher no App Store Connect → App Privacy.

---

## Tracking

**Does this app track users?** → **No**

---

## Data Linked to You

| Data Type | Purpose | Linked to Identity |
|-----------|---------|-------------------|
| Email Address | App Functionality | Yes |
| Name | App Functionality | Yes |
| Precise Location | App Functionality | Yes |
| Photos or Videos | App Functionality | Yes |
| Other User Content | App Functionality | Yes |

---

## Data Not Collected for Tracking

Nenhum dado usado para publicidade ou tracking entre apps.

---

## Privacy Manifest (PrivacyInfo.xcprivacy)

Arquivo incluído em `ios/Runner/PrivacyInfo.xcprivacy`:

- NSPrivacyTracking: false
- API reasons: UserDefaults (CA92.1), FileTimestamp (C617.1)
- Collected data types declarados conforme uso real

---

## Export Compliance

`ITSAppUsesNonExemptEncryption` = **NO** (apenas HTTPS padrão / TLS).

---

## Account deletion

**Yes** — in-app em Configurações → Excluir minha conta.

---

## Privacy Policy URL

Configurar no App Store Connect (mesma URL do app).
