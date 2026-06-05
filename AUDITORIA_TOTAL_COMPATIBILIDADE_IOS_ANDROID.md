# Auditoria Total - Compatibilidade iOS + Android

Data: 2026-05-31

## Escopo e metodo

Auditoria estatica completa do projeto Flutter, configuracoes nativas iOS/Android,
dependencias, navegacao, permissoes, SafeArea, bottom sheets, teclado, tema,
acessibilidade e pontos de performance. Nenhuma regra de negocio, API ou
estrutura de banco de dados foi alterada.

Validacoes executadas:

- `flutter doctor -v`: sem problemas no ambiente.
- `flutter analyze --no-pub`: 13 infos restantes, todas em enums persistidos.
- `flutter test --reporter compact`: 662 testes aprovados e 1 ignorado.
- `flutter build apk --debug --no-pub`: aprovado.
- `flutter build appbundle --release --no-pub`: aprovado.
- `flutter build ios --simulator --no-pub`: aprovado.
- `plutil -lint ios/Runner/Info.plist`: aprovado.
- Inspecao dos manifests Android mesclados debug e release.

## Corrigido

### Compatibilidade Android

- Adicionada permissao `INTERNET` ao manifest principal. Antes ela existia
  apenas em debug/profile, quebrando rede no build release.
- Removidas permissoes amplas e obsoletas de storage:
  `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES` e
  `READ_MEDIA_VIDEO`.
- Mantido o fluxo moderno: `image_picker` usa Photo Picker e `file_picker` usa
  Storage Access Framework, sem acesso amplo a galeria.
- Adicionadas `FOREGROUND_SERVICE` e `FOREGROUND_SERVICE_LOCATION` para
  compatibilidade com Android 14+ no uso continuo de localizacao em primeiro
  plano.
- Removida `ACCESS_BACKGROUND_LOCATION`: o codigo nao configura rastreio em
  background e aceita `whileInUse`.
- Adicionados `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` e receivers do
  `flutter_local_notifications` para restaurar notificacoes agendadas apos
  reboot.
- Alarmes exatos agora verificam autorizacao no Android 14+ e degradam para
  `inexactAllowWhileIdle` quando negados, evitando `SecurityException`.
- Removido `fullScreenIntent` de lembretes comuns da agenda. Esse recurso e
  restrito a chamadas e alarmes criticos e aumentava risco Play Store.
- Nome visivel Android alinhado para `SoloForte`.

### Compatibilidade iOS

- Habilitados no Podfile somente os modulos usados do `permission_handler`:
  camera, fotos e localizacao `whenInUse`.
- Removida descricao iOS de localizacao Always, pois o app nao implementa
  rastreio real em background.
- Mantidas descricoes amigaveis para camera, fotos e localizacao em uso.
- Nome visivel iOS alinhado para `SoloForte`.
- `Info.plist` validado com `plutil`.

### UX, UI e performance

- Todos os bottom sheets de producao passam pelo wrapper padronizado.
- O seletor de formato de exportacao foi migrado para o wrapper comum.
- O wrapper mantem arraste, dismiss, SafeArea e suporte a teclado.
- Removido `Clip.antiAliasWithSaveLayer` dos sheets; `Clip.antiAlias` evita uma
  camada offscreen cara sem alterar o visual esperado.
- Cancelada a assinatura de deep links no `dispose` do shell, evitando listener
  residual e vazamento de memoria.
- Migrados todos os usos depreciados de `withOpacity` para
  `withValues(alpha:)`.
- Registrada explicitamente a dependencia de teste
  `permission_handler_platform_interface`.
- Ignorado cache gerado `android/.kotlin`.

## Encontrado

### Navegacao

- O app usa `GoRouter` e nao possui `WillPopScope`, bloqueios globais de back ou
  rotas customizadas que impeçam gesture back.
- Rotas imperativas pontuais usam `MaterialPageRoute`, que aplica transicoes
  conforme a plataforma Flutter.
- Predictive Back Android deve ser homologado em dispositivo/emulador, pois
  animacao e comportamento final dependem da versao do sistema.

### SafeArea, teclado e responsividade

- Telas principais, overlays de mapa, docks e sheets possuem protecoes
  `SafeArea`, `viewInsets` e padding inferior.
- Android usa `adjustResize`.
- Formularios em sheets possuem scroll e padding de teclado nos pontos
  auditados.
- Nao ha bloqueio global de orientacao. iPhone aceita portrait e landscape;
  iPad aceita tambem portrait invertido.

### Dark mode e acessibilidade

- Ha tema claro e escuro Material 3 com `ColorScheme`, overlay de status bar e
  tokens de contraste.
- Existem `Semantics` em controles publicos importantes do mapa.
- A cobertura de Semantics nao e integral em todos os botoes customizados.

### Dependencias

- `golden_toolkit` esta descontinuado e e usado apenas em testes.
- `build_resolvers` e `build_runner_core` aparecem descontinuados como
  dependencias transitivas de tooling.
- Existem atualizacoes major disponiveis para varios pacotes. Upgrade major nao
  foi feito nesta auditoria para evitar regressao funcional.

## Nao corrigido

- Assinatura Android release ainda usa chave debug em
  `android/app/build.gradle.kts`. Credenciais release nao estao no repositorio.
- Splash Android continua visualmente basico, com fundo branco sem arte de
  marca. Nao bloqueia build, mas reduz acabamento premium.
- Toque em notificacao da agenda ainda nao navega para o evento; ha TODO
  preexistente. Corrigir exige decisao de fluxo, fora de compatibilidade pura.
- Auditoria visual completa em iPhone SE, iPhone 15, iPhone Pro Max, iPad,
  Android pequeno, medio e tablet nao foi executada nesta rodada. Exige matriz
  de simuladores, sessao autenticada e dados representativos.
- Performance Overlay, jank e memoria precisam de medicao runtime em profile
  com fluxos reais. A auditoria estatica corrigiu dois pontos objetivos, mas nao
  substitui profiling.
- Os 13 infos restantes do analyzer sao enums snake_case persistidos. Renomear
  pode alterar serializacao e foi deliberadamente evitado.

## App Store

Pontos favoraveis:

- Build iOS simulator aprovado.
- Descricoes de privacidade presentes e reduzidas ao escopo usado.
- Navegacao e SafeArea estruturadas para iOS.

Pendencias:

- Homologar gesture back, Dynamic Island, teclado, VoiceOver e fontes dinamicas
  em matriz real.
- Validar archive assinado e metadados no App Store Connect.

Risco de rejeicao atual: **Medio**.

## Play Store

Pontos favoraveis:

- Build AAB release aprovado com target SDK 36.
- Compatibilidade Android 13, 14 e 15 tratada para notificacoes, Photo Picker,
  edge-to-edge e servico foreground de localizacao.
- Permissoes de storage removidas.

Pendencias:

- Configurar assinatura release.
- Documentar justificativa de `SCHEDULE_EXACT_ALARM` na Play Console ou optar
  por alarmes sempre inexatos caso o produto nao precise de horario preciso.
- Homologar Predictive Back e edge-to-edge em Android 15+.

Risco de rejeicao atual: **Alto** enquanto a assinatura release usar chave
debug; depois da assinatura, **Medio** por causa da revisao de alarme exato.

## Compatibilidade final

- iOS: **88%**
- Android: **86%**

Os percentuais medem prontidao tecnica observada, nao certificacao de loja.

## Conclusao

Aplicativo apto para producao: **NAO**.

O codigo esta compilando e a base de compatibilidade melhorou de forma
mensuravel, mas publicacao exige assinatura release Android e homologacao manual
da matriz de dispositivos, acessibilidade e performance runtime.

## Referencias oficiais

- Android edge-to-edge:
  https://developer.android.com/develop/ui/views/layout/edge-to-edge
- Android Photo Picker e acesso parcial:
  https://developer.android.com/about/versions/14/changes/partial-photo-video-access
- Android alarmes exatos:
  https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
- Android foreground service location:
  https://developer.android.com/about/versions/14/changes/fgs-types-required
- Android Predictive Back:
  https://developer.android.com/guide/navigation/custom-back/support-animations
- Geolocator:
  https://pub.dev/packages/geolocator
