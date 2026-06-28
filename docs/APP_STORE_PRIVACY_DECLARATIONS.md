# App Store Privacy Declarations — SoloForte

Data: 2026-06-07

Escopo: declaracoes de privacidade para App Store Connect e politica publica.

## App Privacy — dados a declarar

Declarar que os dados abaixo podem ser coletados e vinculados a identidade do
usuario, pois ficam associados ao usuario autenticado no Supabase.

| Categoria Apple | Uso no SoloForte | Tracking |
|---|---|---|
| Name | Perfil do usuario e dados cadastrais | Nao |
| Email Address | Login, conta, suporte e recuperacao de senha | Nao |
| Phone Number | Perfil profissional opcional | Nao |
| User ID | Supabase Auth, `user_id` e sync remoto | Nao |
| Precise Location | GPS para mapa, talhoes, ocorrencias e visitas | Nao |
| Photos or Videos | Fotos de perfil, ocorrencias, relatorios e marketing cases | Nao |
| Other User Content | Fazendas, talhoes, visitas, relatorios, ocorrencias, NDVI e anotacoes | Nao |
| Product Interaction | Uso operacional do app e estados de sincronizacao quando armazenados | Nao |
| Customer Support | Feedback e contatos de suporte quando enviados pelo usuario | Nao |

Finalidade principal para todos: App Functionality.

## Terceiros/processadores

Incluir nas respostas do App Store Connect e na politica de privacidade:

- Supabase: autenticacao, banco remoto, storage, edge functions e sincronizacao.
- Provedores de mapa/tiles: Stadia, MapTiler/Google tiles conforme build ativo.
- Google Weather/OpenWeather/servicos de clima configurados via dart-define.
- Mercado Pago: pagamentos e webhooks enquanto o fluxo estiver ativo.
- Apple/iOS: notificacoes, camera, fotos, localizacao e compartilhamento nativo.

## Permissoes iOS

Permissoes mantidas:

- `NSLocationWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

Permissoes removidas por nao haver background mode/capability de tracking real:

- `NSLocationAlwaysUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

Se tracking real em background for adotado no futuro, reabrir decisao com:

- `UIBackgroundModes = location`
- consentimento explicito no fluxo
- nota ao revisor
- justificativa na politica de privacidade

## Privacy manifest

O app possui manifest proprio:

- `ios/Runner/PrivacyInfo.xcprivacy`

Pods/plugins tambem possuem manifests proprios via CocoaPods para SDKs como:

- geolocator
- image_picker
- file_picker
- shared_preferences
- sqflite
- url_launcher
- webview_flutter
- share_plus
- connectivity_plus
- flutter_local_notifications

## Politica de privacidade publica

URL atual usada no app:

https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/

A pagina publica deve declarar:

- coleta de localizacao precisa durante uso do app
- fotos/imagens anexadas pelo usuario
- dados de clientes, fazendas, talhoes, visitas, ocorrencias e relatorios
- sincronizacao com Supabase
- uso de provedores de mapas, clima e pagamento
- exclusao de conta dentro do app
- contato de suporte e prazo de atendimento

## Exclusao de conta

Fluxo no app:

- Configuracoes -> Sessao -> Excluir minha conta
- Confirma exclusao permanente
- Chama Edge Function `delete-user`
- Limpa dados locais via `DatabaseHelper.clearUserLocalData`
- Invalida providers de usuario
- Encerra sessao

Backend:

- `supabase/functions/delete-user/index.ts`

Antes de submeter:

- confirmar deploy da Edge Function no projeto de producao
- confirmar `SUPABASE_SERVICE_ROLE_KEY` configurada no ambiente da function
- testar com conta demo sem dados criticos

## Segredos e chaves

Estado local:

- `.env.local` e `.env.local.json` estao ignorados por Git.
- `API_KEYS_MASTER.md` esta ignorado por Git.

Antes de build de loja:

- restringir chaves Google/Stadia/MapTiler por bundle id, dominio, API e cota
- rotacionar qualquer chave que tenha sido compartilhada fora de canal seguro
- confirmar que secrets de Mercado Pago ficam apenas no Supabase/ambiente seguro
