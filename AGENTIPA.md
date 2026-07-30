# AGENTIPA

## Regras de release

- Sempre gerar o próximo IPA com `CFBundleVersion` maior que o maior IPA já publicado neste repositório.
- Nunca gerar IPA com build number igual ou menor ao último IPA validado.
- Sempre embutir corretamente os dados locais necessários ao boot do app antes de fechar a release.
- Atualizar este arquivo após cada IPA com o número gerado e a evidência de validação.

## Histórico

- IPA 166: `build/ios/ipa/soloforte_app.ipa` | `CFBundleVersion=166` | `CFBundleShortVersionString=1.34.0`
- Correção: o IPA válido para a sequência atual é o 167; nunca reutilizar 166 como entrega final.
- IPA 167: `build/ios/ipa/soloforte_app.ipa` | `CFBundleVersion=167` | `CFBundleShortVersionString=1.34.0`
- IPA 168: `build/ios/ipa/soloforte_app.ipa` | `CFBundleVersion=168` | `CFBundleShortVersionString=1.34.0` | `SUPABASE_URL` confirmada no binário
- IPA 169: `build/ios/ipa/soloforte_app.ipa` | `CFBundleVersion=169` | `CFBundleShortVersionString=1.34.0` | `SUPABASE_URL` confirmada no binário
- IPA 170: `build/ios/ipa/soloforte_app.ipa` | `CFBundleVersion=170` | `CFBundleShortVersionString=1.34.0` | `SUPABASE_URL` confirmada no binário
- IPA 175: **código pronto, archive falhou no codesign** | `pubspec 1.34.0+175` | branch `cursor/fix-nav-ux-ipa175-9765` @ `08a5ff2` | erro Xcode: certificado Apple Development do team `BA2BU25B78` existe na conta, mas a **private key não está no keychain** deste Mac | ação: Xcode → Settings → Accounts → Manage Certificates → Revoke órfão e gerar novo (ou restaurar `.p12` de outro Mac) → `./build_testflight.sh`
- IPA 176: `build/ios/ipa/soloforte_app.ipa` | `CFBundleVersion=176` | `CFBundleShortVersionString=1.34.0` | `SUPABASE_URL` confirmada no binário | branch `cursor/fix-cta-shadow-regression-b77f` | inclui fix alinhamento vértices mid-draw + gota + AppIcon orphans removidos
- IPA 177: `build/ios/ipa/soloforte_app.ipa` | `CFBundleVersion=177` | `CFBundleShortVersionString=1.34.0` | `SUPABASE_URL` confirmada no binário | branch `cursor/fix-cta-shadow-regression-b77f` @ `dcc35ac` | locale pt-BR (date pickers) · fix UX carteira/agenda/consultoria QA · gota mid-draw center · AppIcon orphans removidos
- IPA 178: pendente | `pubspec 1.34.0+178` | branch `cursor/agenda-session-mirror-7357` | ADR-048 espelhamento agenda → visit_sessions
- IPA 179: `build/ios/ipa/soloforte_app.ipa` | `CFBundleVersion=179` | `CFBundleShortVersionString=1.34.0` | `SUPABASE_URL` confirmada no binário | branch `cursor/marketing-case-story-3d34` @ `0ddee02` | story HTML share (P1) · route guard `/marketing/story` (P2a) · escape HTML injector (P2b) · PR #21
