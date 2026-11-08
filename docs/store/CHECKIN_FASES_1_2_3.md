# Check-in — Fases 1, 2 e 3 (loja iOS)

Data: 8 de novembro de 2026 (America/Araguaina). Escopo: binário e documentação pronta para colar no App Store Connect. Não inclui envio na Apple nem Fase 4 (Play).

---

## Fase 1 — antes do binário

| Item | OK |
|---|---|
| `READ_MEDIA_IMAGES`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` removidas no merge Android (`tools:node="remove"`) | ✅ |
| `GeolocatorLocationService` mantido (GPS com app aberto) | ✅ |
| `NSLocationAlwaysAndWhenInUseUsageDescription` presente no iOS (ASC 90683) | ✅ |
| `NSPrivacyCollectedDataTypeAudioData` no `PrivacyInfo.xcprivacy` | ✅ |
| `ITSAppUsesNonExemptEncryption = false` | ✅ |
| `./tool/release_store_check.sh` → Exit 0 | ✅ |
| Keystore fora do git (`.gitignore`) | ✅ |

---

## Fase 2 — páginas e conta de revisão

Detalhe em `docs/store/CHECKIN_FASE_2.md`.

| Item | OK |
|---|---|
| Política, exclusão e suporte no GitHub Pages (HTTP 200) | ✅ |
| Conta `review@soloforte.app` + demo no Supabase | ✅ |
| `delete-user` v15 em produção | ✅ |
| PRs [#406](https://github.com/AfonsoRaudinei/dart/pull/406), [#414](https://github.com/AfonsoRaudinei/dart/pull/414) na `main` | ✅ |

---

## Fase 3 — ficha App Store Connect

| Item | OK |
|---|---|
| Guia completo `docs/store/APP_STORE_CONNECT.md` | ✅ |
| Privacidade `docs/store/APP_PRIVACY_APPLE.md` | ✅ |
| Metadados `docs/store/METADADOS_LOJAS.md` (bundle `com.soloforte.soloforteApp`) | ✅ |
| Conta demo `docs/store/CONTA_DEMO_REVIEW.md` | ✅ |
| URLs de política e suporte (Fase 2) | ✅ |
| Screenshots 1179×2556 ou 1206×2622 | ⬜ capturar |
| Upload IPA / Submit for Review no Connect | ⬜ titular da conta |

---

## Próximo IPA (build **312**)

O último build conferido foi **311**. O `pubspec.yaml` segue em **1.34.0+312** para o próximo envio ao TestFlight.

```bash
cd /caminho/para/appdart
set -a && source .env.local && set +a
./tool/release_store_check.sh
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENV=production
```

Artefato: `build/ios/ipa/soloforte_app.ipa` · bundle `com.soloforte.soloforteApp` · equipe `BA2BU25B78`.

Depois do build:

```bash
./tool/release_store_check.sh build/ios/ipa/soloforte_app.ipa
```

Upload: **Transporter** ou Xcode → Organizer. Conferir no Connect: Privacy, Support URL, build **312**, screenshots e notas de `APP_STORE_CONNECT.md`.
