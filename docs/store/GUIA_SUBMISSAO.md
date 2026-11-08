# Guia de Submissão — App Store e Google Play

Checklist operacional para publicar SoloForte v1.0.0.

---

## Pré-requisitos

- [ ] Fases 1 e 2 concluídas e testadas
- [ ] `flutter test` e `flutter analyze` passando
- [ ] Smoke test 100% (`docs/SMOKE_TEST_CHECKLIST.md`)
- [ ] Supabase produção configurado
- [ ] Política de privacidade em URL HTTPS pública
- [ ] Keystore Android e certificado iOS de distribuição

---

## 1. Build de release

Seguir `docs/BUILD_RELEASE.md`:

```bash
# Android
flutter build appbundle \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

# iOS
flutter build ipa \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

---

## 2. Google Play Console

1. Criar app → Nome: **SoloForte**
2. Upload AAB (Production ou Internal testing primeiro)
3. **App content → Data safety** — usar `docs/store/DATA_SAFETY_GOOGLE_PLAY.md`
4. **App content → Privacy policy** — URL HTTPS
5. **Store listing** — usar `docs/store/METADADOS_LOJAS.md`
6. Screenshots (mín. 4) — ver METADADOS_LOJAS
7. **App access** — credenciais demo (`docs/store/CONTA_DEMO_REVIEW.md`)
8. Content rating questionnaire → provável **Livre**
9. Enviar para revisão

---

## 3. Apple App Store Connect

Seguir `docs/store/APP_STORE_CONNECT.md`.

1. App com bundle `com.soloforte.soloforteApp` (só iPhone)
2. Upload IPA 1.34.0 com build maior que o último aceito
3. App Privacy — `docs/store/APP_PRIVACY_APPLE.md`
4. Privacy Policy URL e Support URL das páginas publicadas
5. Screenshots 1179 × 2556 ou 1206 × 2622
6. App Review Information — `docs/store/CONTA_DEMO_REVIEW.md`
7. Export compliance → No
8. Disponibilidade Brasil e DSA conforme o guia
9. Submit for Review

---

## 4. Pós-submissão

| Ação | Quando |
|------|--------|
| Monitorar e-mail de review | Diário |
| Responder rejeições em 24h | Se ocorrer |
| Smoke test em build aprovado | Antes de promover 100% |
| Tag git `v1.0.0` | Após aprovação |

---

## 5. Rollback

- Play Console: halt rollout / revert to previous AAB
- App Store: remove from sale / submit expedited fix

---

## Referências

- `docs/store/METADADOS_LOJAS.md`
- `docs/store/DATA_SAFETY_GOOGLE_PLAY.md`
- `docs/store/APP_PRIVACY_APPLE.md`
- `docs/store/CONTA_DEMO_REVIEW.md`
- `docs/BUILD_RELEASE.md`
