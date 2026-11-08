# Check-in — Fases 1, 3 e 4

Data: 8 de novembro de 2026, America/Araguaina.

A Fase 1 fecha o binário. As Fases 3 e 4 fecham a ficha para colar. O envio nos sites da Apple e do Google fica com o titular da conta: esta máquina não tem chave de API do App Store Connect nem sessão do Play Console.

---

## Fase 1 — binário — 100%

| Item | Resultado |
|---|---|
| `READ_MEDIA_IMAGES`, `FOREGROUND_SERVICE` e `FOREGROUND_SERVICE_LOCATION` saem do merge com `tools:node="remove"` | sim |
| `GeolocatorLocationService` permanece (GPS em primeiro plano, sem `startForeground`) | sim |
| `NSLocationAlwaysAndWhenInUseUsageDescription` ausente | sim |
| `NSLocationWhenInUseUsageDescription`, câmera, microfone, fotos e `ITSAppUsesNonExemptEncryption=false` | sim |
| `NSPrivacyCollectedDataTypeAudioData` (ligado, sem tracking, App Functionality) | sim |
| `./tool/release_store_check.sh` | Exit 0, 10 tipos, Audio Data presente |
| Keystore fora do git | `android/key.properties`, `android/keystore/`, `*.jks` e `*.keystore` no `.gitignore` |
| Cópia da chave | `~/.soloforte-release/` (`soloforte-release.jks` e `key.properties`) |

AAB conferido, `build` com `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `ENV=production`:

| Checagem | Resultado |
|---|---|
| Arquivo | `~/.soloforte-release/store-1.34.0-311/app-release.aab` (58 MB) |
| Versão | 1.34.0 (311), `com.soloforte.app` |
| targetSdk | 36 |
| Permissões removidas | ausentes no manifesto empacotado |
| 16 KB | 9 bibliotecas `.so`, alinhamento mínimo 16384, nenhuma abaixo |
| Assinatura | release, `CN=Raudinei Afonso Silva Pereira, O=SoloForte, C=BR` |
| SHA-256 do certificado | `4B:A3:7A:31:EB:24:57:EF:BA:A2:2F:5F:C8:61:18:C2:DD:D5:9E:DA:89:1B:2B:E4:70:D0:C4:38:E2:68:39:55` |

IPA conferido com os mesmos `--dart-define`:

| Checagem | Resultado |
|---|---|
| Arquivo | `~/.soloforte-release/store-1.34.0-311/soloforte_app.ipa` (31 MB) |
| Versão | 1.34.0 (311) |
| Bundle | `com.soloforte.soloforteApp` |
| Audio Data no manifesto do app | sim, 10 tipos |
| Chave Always | ausente |
| Criptografia não isenta | `false` |

O upload do IPA é pelo Transporter ou pelo Xcode. Se o TestFlight já aceitou o build 311, o próximo envio precisa de um número maior no `pubspec.yaml`.

---

## Fase 3 — ficha do App Store Connect — 100%

Guia para colar: `docs/store/APP_STORE_CONNECT.md`.

| Item da ficha | Onde está |
|---|---|
| Bundle `com.soloforte.soloforteApp`, só iPhone | seções 1 e 10 |
| Versão 1.34.0 (311) | cabeçalho |
| Subtitle, keywords, descrição, copyright, preço Free | seções 1 e 3 |
| Categoria Business, secundária Productivity | seção 1 |
| Content rights (tiles de terceiros com atribuição) | seção 1 |
| Privacy, Support; Marketing vazio | seção 2 |
| Questionário de idade, nota esperada 4+, sem override 18+ | seção 4 |
| App Privacy: 9 tipos, sem tracking, App Functionality | seção 5 |
| Export compliance: No | seção 6 |
| Disponibilidade só Brasil; DSA “This is not a trader account” | seção 7 |
| Tamanho de screenshot 1179×2556 ou 1206×2622 | seção 8 |
| Notas de review em inglês e contato `privacidade@soloforte.app` | seção 9 |

A ficha não inventa telefone do titular nem marca o app como enviado.

---

## Fase 4 — ficha do Play Console — 100%

Guia para colar: `docs/store/PLAY_CONSOLE.md`. Tabela de dados: `docs/store/DATA_SAFETY_GOOGLE_PLAY.md`.

| Item da ficha | Onde está |
|---|---|
| App `com.soloforte.app`, grátis, Business, português (Brasil), só Brasil | seção 1 |
| Advertising ID: No | seção 1 |
| Descrição curta (73) e descrição completa | seção 1 e `METADADOS_LOJAS.md` |
| Política e link de exclusão | seções 1 e 2 |
| Data safety: coleta sim, sharing não, HTTPS sim | `DATA_SAFETY_GOOGLE_PLAY.md` |
| Alarme exato, com fallback inexato | seção 2 |
| Anúncio: No. Recurso financeiro: o app não oferece | seção 2 |
| IARC Livre, público 18+, fora do Families | seção 2 |
| Fotos pelo seletor; sem as três permissões removidas | seção 2 |
| Teste fechado de 12 pessoas por 14 dias, se a conta pessoal for posterior a 13/11/2023 | seção 3 |

---

## O que o titular ainda faz no site da loja

Estes passos não estão neste repositório. Sem eles o botão de enviar das lojas não passa.

1. Publicar `docs/legal/github-pages/` na raiz de `AfonsoRaudinei/SoloForte-Pol-tica-de-Privacidade` (Pages em `main`, pasta `/`) e abrir as três URLs no navegador.
2. Criar `review@soloforte.app` no Supabase de produção, com e-mail confirmado, um cliente, uma fazenda e um talhão. Credenciais em `docs/store/CONTA_DEMO_REVIEW.md`.
3. Confirmar que a função `delete-user` está publicada no projeto de produção.
4. Capturar os screenshots (iPhone 1179×2556 ou 1206×2622; telefone 9:16; tablet 7" e 10" se a Play pedir) e o ícone 512 e o feature graphic 1024×500.
5. Subir o IPA pelo Transporter e o AAB no Play Console.
6. Colar as fichas das Fases 3 e 4. O telefone do contato da Apple é o do titular da conta.
7. Guardar `~/.soloforte-release/` fora desta máquina. Sem o keystore não há atualização do app Android.
