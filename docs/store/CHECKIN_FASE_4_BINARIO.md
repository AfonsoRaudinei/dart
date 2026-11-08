# Check-in — Fase 4: binário Android (Play)

Data: 8 de novembro de 2026 (America/Araguaina).

Escopo: AAB release conferido para upload no Play Console. Ficha para colar: `docs/store/PLAY_CONSOLE.md` e `docs/store/DATA_SAFETY_GOOGLE_PLAY.md`. O `.aab` não entra no git.

**Binário Fase 4: ✅ pronto para upload** (formulários e gráficos no Console ainda são do titular).

---

## Artefato

| Campo | Valor |
|---|---|
| Versão | 1.34.0 (**versionCode 312**) |
| Application ID | `com.soloforte.app` |
| Arquivo no projeto | `build/app/outputs/bundle/release/app-release.aab` |
| Cópia local | `~/.soloforte-release/store-1.34.0-312/app-release.aab` (~58 MB) |
| Alinhado ao IPA | Mesmo `pubspec` e mesmos `--dart-define` da Fase 1/3 |

---

## Conferências (8 nov 2026)

| Checagem | Resultado |
|---|---|
| `./tool/release_store_check.sh` na `main` | Exit 0 |
| targetSdk | 36 |
| `READ_MEDIA_IMAGES` | Ausente no manifest do bundle |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION` | Ausentes |
| `SCHEDULE_EXACT_ALARM` | Presente (lembretes de agenda) |
| `ACCESS_BACKGROUND_LOCATION` | Ausente |
| Página 16 KB (9 bibliotecas `.so`) | Todas com alinhamento ≥ 16384 |
| Assinatura | Release — `CN=Raudinei Afonso Silva Pereira, O=SoloForte, C=BR` |
| SHA-256 do certificado | `4B:A3:7A:31:EB:24:57:EF:BA:A2:2F:5F:C8:61:18:C2:DD:D5:9E:DA:89:1B:2B:E4:70:D0:C4:38:E2:68:39:55` |

Chave fora do git: `android/key.properties` e `android/keystore/` (backup em `~/.soloforte-release/`).

---

## Regenerar o AAB

```bash
cd /caminho/para/appdart
set -a && source .env.local && set +a
./tool/release_store_check.sh
flutter build appbundle --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENV=production
```

Se o Play já tiver o build **312**, incremente o número após `+` no `pubspec.yaml` e gere de novo.

---

## Upload no Play Console

1. Play Console → app `com.soloforte.app` → **Testing** (interno/fechado) ou **Production**, conforme a conta.
2. **Create new release** → enviar `app-release.aab`.
3. No **App Bundle Explorer**, conferir de novo a checagem de **16 KB**.
4. Completar **App content** com `PLAY_CONSOLE.md` e Data safety com `DATA_SAFETY_GOOGLE_PLAY.md`.
5. URLs da Fase 2 já no ar (política e exclusão).
6. Conta de revisão: `docs/store/CONTA_DEMO_REVIEW.md`.

### Ainda não está no repositório (loja)

| Item | Status |
|---|---|
| Ícone 512 × 512 | ⬜ |
| Feature graphic 1024 × 500 | ⬜ |
| ≥ 2 screenshots telefone 9:16 | ⬜ |
| Screenshots tablet 7" / 10" (se a Play pedir) | ⬜ |
| Teste fechado 12 × 14 dias (conta pessoal pós 13/11/2023) | ⬜ se aplicável |
| Release em produção publicada | ⬜ |
