# Apple App Store — App Privacy (Nutrition Labels)

Preencher no App Store Connect → App Privacy.

---

## Tracking

**Does this app track users?** → **No**

---

## Data Linked to You

Todos: finalidade App Functionality, ligados à identidade, sem tracking.

| Data Type | No SoloForte |
|-----------|----------------|
| Name | Nome da conta |
| Email Address | E-mail de login |
| Phone Number | Telefone digitado em cliente ou caso |
| User ID | Identificador da conta |
| Precise Location | GPS com o app aberto |
| Photos or Videos | Fotos de ocorrência, relatório e perfil |
| Audio Data | Áudio de até 30 segundos na ocorrência |
| Other User Content | Clientes, fazendas, talhões, visitas, ocorrências e relatórios |
| Customer Support | Mensagens de feedback |

Não marcar Product Interaction, Crash Data, Contacts, Health, Financial Info nem Advertising Data.

---

## Data Not Collected for Tracking

Nenhum dado usado para publicidade ou tracking entre apps.

---

## Privacy Manifest (PrivacyInfo.xcprivacy)

Arquivo incluído em `ios/Runner/PrivacyInfo.xcprivacy`:

- NSPrivacyTracking: false
- API reasons: UserDefaults (CA92.1), FileTimestamp (C617.1)
- Collected data types declarados conforme uso real

**Checklist archive + Transporter:** `docs/store/IOS_ARCHIVE_PRIVACY_CHECKLIST.md`

**Gate automatizado:**

```bash
./tool/release_store_check.sh
# Com IPA gerado:
./tool/release_store_check.sh build/ios/ipa/*.ipa
```

---

## Export Compliance

`ITSAppUsesNonExemptEncryption` = **NO** (apenas HTTPS padrão / TLS).

---

## Account deletion

**Yes** — in-app em Configurações → Excluir minha conta.

---

## Privacy Policy URL

`https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/`

Support URL: `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/suporte.html`

Ficha completa: `docs/store/APP_STORE_CONNECT.md`.
