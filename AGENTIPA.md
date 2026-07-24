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
- IPA 171: `build/ios/ipa/soloforte_app.ipa` | `CFBundleVersion=171` | `CFBundleShortVersionString=1.34.0` | `SUPABASE_URL` confirmada no binário | evidência: Info.plist do artefato local (2026-07-23)
- IPA 172: _em geração_ | glass card público + CTA reopen + taglines + atribuição sem auto-popup
