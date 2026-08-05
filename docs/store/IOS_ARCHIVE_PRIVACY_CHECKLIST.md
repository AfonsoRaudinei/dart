# iOS — Archive, Privacy Manifest e Transporter

Checklist operacional para gerar IPA e submeter à App Store sem bloqueio de privacidade.

**Artefato principal:** `ios/Runner/PrivacyInfo.xcprivacy` (incluído no target Runner → Copy Bundle Resources).

---

## Pré-requisitos locais

```bash
flutter doctor -v          # Xcode + CocoaPods OK
chmod +x tool/release_store_check.sh
./tool/release_store_check.sh
```

Gate esperado: **Exit 0**.

Validações automáticas do script:

| Check | Esperado |
|---|---|
| `plutil -lint PrivacyInfo.xcprivacy` | OK |
| `plutil -lint Info.plist` | OK |
| PrivacyInfo no `project.pbxproj` Resources | presente |
| `NSPrivacyTracking` | `false` |
| `NSPrivacyAccessedAPITypes` | UserDefaults CA92.1, FileTimestamp C617.1 |
| `ITSAppUsesNonExemptEncryption` | `false` |

---

## Alinhamento App Store Connect ↔ PrivacyInfo

Consultar `docs/store/APP_PRIVACY_APPLE.md` ao preencher **App Privacy** no App Store Connect.

| PrivacyInfo (manifest) | App Store Connect |
|---|---|
| NSPrivacyCollectedDataTypeEmailAddress | Email — App Functionality |
| NSPrivacyCollectedDataTypeName | Name — App Functionality |
| NSPrivacyCollectedDataTypePreciseLocation | Precise Location — App Functionality |
| NSPrivacyCollectedDataTypePhotosorVideos | Photos/Videos — App Functionality |
| NSPrivacyCollectedDataTypeOtherUserContent | Other User Content — App Functionality |
| NSPrivacyTracking = false | Does this app track users? **No** |

---

## Fluxo de archive (TestFlight / App Store)

### 1. Preflight

```bash
git status                    # workspace limpo ou diff conhecido
./tool/arch_check.sh          # Exit 0
flutter analyze lib/          # 0 issues
flutter test                  # suite verde
./tool/release_store_check.sh # Exit 0
```

### 2. Build IPA

Usar script oficial quando credenciais estiverem configuradas:

```bash
./build_testflight.sh
```

Ou manualmente:

```bash
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist \
  --dart-define=ENV=production \
  # ... demais dart-defines do build_testflight.sh
```

### 3. Validar PrivacyInfo **dentro** do IPA

```bash
./tool/release_store_check.sh build/ios/ipa/*.ipa
```

Checks adicionais com IPA:

- `PrivacyInfo.xcprivacy` presente em `Payload/Runner.app/`
- `plutil -lint` no manifest embutido
- `ITSAppUsesNonExemptEncryption = false` no Info.plist do bundle

### 4. Upload Transporter

1. Abrir **Transporter** (macOS) ou `xcrun altool` / App Store Connect API
2. Selecionar IPA em `build/ios/ipa/`
3. Aguardar processamento — erros comuns:
   - **Missing Privacy Manifest** → PrivacyInfo não entrou no bundle (revisar pbxproj)
   - **Invalid PrivacyInfo** → `plutil -lint` falhou
   - **Encryption export** → confirmar `ITSAppUsesNonExemptEncryption = false`

### 5. App Store Connect pós-upload

```
[ ] Build aparece em TestFlight (processamento concluído)
[ ] Export Compliance: uses encryption → No (non-exempt)
[ ] App Privacy preenchido (ver APP_PRIVACY_APPLE.md)
[ ] Privacy Policy URL configurada
[ ] Account deletion: Yes (Configurações → Excluir conta)
[ ] Screenshots + metadata de release
```

---

## SDKs de terceiros (Pods)

Manifests de Required Reason APIs dos Pods entram no bundle agregado. Após `pod install`, validar em archive se algum SDK novo foi adicionado:

```bash
find ios/Pods -name "PrivacyInfo.xcprivacy" 2>/dev/null | head -20
```

Se Apple reportar API category faltante no upload, adicionar reason correspondente em `ios/Runner/PrivacyInfo.xcprivacy` **ou** confirmar que o Pod já declara.

---

## Troubleshooting

| Sintoma | Ação |
|---|---|
| Transporter rejeita Privacy Manifest | Rodar `./tool/release_store_check.sh path/to.ipa` |
| ITMS-91053 Missing API declaration | Revisar `NSPrivacyAccessedAPITypes` + manifests dos Pods |
| Export compliance pergunta encryption | Responder **No** — apenas TLS/HTTPS padrão |
| Archive OK mas IPA sem PrivacyInfo | Verificar `PrivacyInfo.xcprivacy in Resources` no pbxproj |

---

## Comandos rápidos de diagnóstico

```bash
plutil -lint ios/Runner/PrivacyInfo.xcprivacy
plutil -extract NSPrivacyTracking raw -o - ios/Runner/PrivacyInfo.xcprivacy
plutil -extract NSPrivacyAccessedAPITypes json -o - ios/Runner/PrivacyInfo.xcprivacy
rg "PrivacyInfo.xcprivacy" ios/Runner.xcodeproj/project.pbxproj
```

---

## Referências

- `docs/store/APP_PRIVACY_APPLE.md`
- `docs/PLANO_PUBLICACAO_IOS_APP_STORE.md`
- `build_testflight.sh`
- `tool/release_store_check.sh`
