# Plano de Publicacao iOS App Store — SoloForte

Data da auditoria: 2026-06-07
Escopo: prontidao tecnica e operacional para publicar o app iOS na App Store.
Bounded context: release iOS / App Store. Nenhuma regra de negocio foi alterada.

## Resultado executivo

Status atual: NAO PUBLICAR AINDA.

O app compila em iOS Release sem assinatura, o `flutter analyze lib/` esta limpo
e a suite de testes passou. A Fase 1 de desbloqueio tecnico foi concluida em
2026-06-07: `tool/arch_check.sh` agora retorna Exit 0.

Ainda assim, existem bloqueadores operacionais antes de qualquer envio oficial:

1. Falta homologacao real em device fisico, TestFlight, App Store Connect,
   politica de privacidade, conta demo e metadata de loja.
2. O workspace contem alteracoes pendentes nao relacionadas que precisam ser
   revisadas antes de congelar uma branch de release.

## Evidencias coletadas

Comandos executados:

- `chmod +x tool/arch_check.sh && ./tool/arch_check.sh`: OK apos Fase 1.
- `flutter analyze lib/`: OK, sem issues.
- `flutter test`: OK, 747 testes passaram, 1 skip.
- `flutter doctor -v`: OK, Xcode 26.4.1, CocoaPods 1.16.2.
- `plutil -lint ios/Runner/Info.plist`: OK.
- `plutil -lint ios/Runner/PrivacyInfo.xcprivacy`: OK.
- `flutter build ios --release --no-codesign`: OK, gerou `Runner.app` 42.8 MB.

Configuracao atual observada:

- Bundle ID: `com.soloforte.soloforteApp`.
- Versao Flutter: `pubspec.yaml` em `1.34.0+134`.
- Deployment target iOS: 13.0.
- `Info.plist` contem permissoes de camera, fotos, fotos escrita e
  localizacao WhenInUse.
- `Info.plist` contem deep link `soloforte://`.
- `PrivacyInfo.xcprivacy` esta versionado e entra no bundle do app.
- `ITSAppUsesNonExemptEncryption` esta `false`.
- App icon iOS 1024x1024 existe em `ios/Runner/Assets.xcassets/AppIcon.appiconset`.
- `.env.local.json` existe no workspace local e esta ignorado pelo Git.
- `build_testflight.sh` injeta `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
  `STADIA_API_KEY`, `MAPTILER_API_KEY` e `GOOGLE_WEATHER_API_KEY` via
  `--dart-define`.

## Fase 1 — Desbloqueio tecnico obrigatorio

Objetivo: permitir que o reposititorio alcance o gate minimo de release.

Status: CONCLUIDA em 2026-06-07.

Foi criado o contrato neutro `IDrawingFieldWriter` em `lib/core/contracts/`,
com adapter concreto em `drawing/infra/` e registro via `ProviderScope`.
As telas de `consultoria/clients` deixaram de importar `drawing_provider.dart`.

Validado:

- `./tool/arch_check.sh`: OK.
- `flutter analyze lib/`: OK.
- `flutter test`: OK, 747 testes passaram, 1 skip.
- `flutter build ios --release --no-codesign`: OK.

Pendente operacional:

1. Congelar branch de release.
   - Nao misturar alteracoes pendentes atuais do workspace com release sem revisar.
   - Hoje existem arquivos modificados nao relacionados, incluindo `pubspec.yaml`,
     `build_testflight.sh`, `ios/Podfile.lock`, auth, settings e UI.

Saida da fase: todos os gates locais verdes e diff de release compreendido.

## Fase 2 — Compliance Apple e privacidade

Objetivo: reduzir risco de rejeicao por privacidade, permissoes e dados.

Status tecnico: CONCLUIDA em 2026-06-07.

Entregue:

1. Criado e versionado `ios/Runner/PrivacyInfo.xcprivacy`.
   - Declara dados coletados pelo app para funcionalidade.
   - `NSPrivacyTracking = false`.
   - `NSPrivacyAccessedAPITypes` fica vazio no app; required reason APIs ficam
     cobertas pelos manifests dos SDKs/Pods quando o acesso vem dos plugins.

2. Confirmados manifests dos SDKs via Pods.
   - geolocator, image_picker, file_picker, shared_preferences, sqflite,
     url_launcher, webview, share_plus, connectivity e notificacoes possuem
     manifests via CocoaPods.

3. Revisadas permissoes iOS.
   - Mantido apenas `NSLocationWhenInUseUsageDescription`.
   - Removidos `NSLocationAlwaysUsageDescription` e
     `NSLocationAlwaysAndWhenInUseUsageDescription`, pois nao ha
     `UIBackgroundModes = location` nem capability de tracking real em background.

4. Exclusao de conta.
   - Fluxo acessivel em Configuracoes -> Sessao -> Excluir minha conta.
   - Chama Edge Function `delete-user`.
   - Limpeza local agora remove todos os dados locais conhecidos do usuario,
     nao apenas registros pendentes.

5. Documentacao operacional criada:
   - `docs/APP_STORE_PRIVACY_DECLARATIONS.md`.

Pendente operacional fora do codigo:

1. App Privacy Nutrition Labels no App Store Connect.
   - Declarar, no minimo, conforme uso real: localizacao precisa, identificadores
     de usuario/conta, dados de contato se coletados, conteudo do usuario,
     fotos/imagens, diagnosticos se houver, e dados de uso se coletados.
   - Incluir praticas de terceiros: Supabase, mapas/tiles, clima, Mercado Pago,
     WebView/url externa, notificacoes e quaisquer analytics se existirem.

2. Politica de privacidade publica.
   - URL HTTPS permanente.
   - Explicar coleta de localizacao de campo, fotos, dados de clientes/fazendas,
     sincronizacao Supabase, pagamentos, exclusao de conta e suporte.

3. Deploy e teste real da exclusao de conta.
   - Confirmar deploy de `supabase/functions/delete-user`.
   - Confirmar `SUPABASE_SERVICE_ROLE_KEY` no ambiente da function.
   - Testar em conta demo de producao.

4. Segredos e chaves.
   - Manter `.env.local.json` fora do Git.
   - Restringir chaves Google/Stadia/MapTiler por bundle id, dominio, cota e APIs.
   - Rotacionar chaves caso tenham sido compartilhadas fora do ambiente seguro.

Saida da fase: privacidade pronta para App Store Connect e permissoes coerentes
com o comportamento real do app.

## Fase 3 — Monetizacao e planos

Objetivo: resolver o maior risco de review funcional.

Status tecnico: CONCLUIDA em 2026-06-07.

Decisao deste release: iOS nao vende plano digital dentro do app e nao inicia
checkout externo. Mercado Pago fica restrito aos canais nao iOS. Se a compra de
plano digital precisar ocorrer dentro do iOS no futuro, a migracao correta e
StoreKit / In-App Purchase.

Entregue:

1. Removido do iOS qualquer CTA, preco ou link para checkout externo em
   `planos/`.
2. Bloqueadas rotas diretas de pagamento/confirmacao no runtime iOS.
3. `MercadoPagoService` agora aborta chamadas em iOS antes de invocar a Edge
   Function e aceita tanto `checkout_url` quanto `init_point` na resposta.
4. Documentacao operacional criada:
   - `docs/APP_STORE_MONETIZATION_REVIEW_NOTES.md`.

Auditado:
   - `lib/modules/planos/presentation/screens/planos_screen.dart`
   - `lib/modules/planos/presentation/screens/pagamento_screen.dart`
   - `lib/modules/planos/presentation/screens/confirmacao_screen.dart`
   - `lib/modules/planos/data/services/mercadopago_service.dart`
   - `supabase/functions/mercadopago-*`

Pendente operacional fora do codigo:

1. App Store Connect.
   - Nao cadastrar IAP para planos enquanto StoreKit nao existir.
   - Nao prometer compra/renovacao por checkout externo nas screenshots,
     descricao ou notas publicas do app iOS.

2. Nota ao revisor.
   - Informar que o iOS exibe apenas status de plano associado a conta.
   - Informar que Mercado Pago e Edge Functions de pagamento existem para canais
     nao iOS e ficam bloqueados no runtime iOS.

Saida da fase: fluxo de monetizacao compativel com App Review Guideline 3.1.1.

## Fase 4 — Assinatura, archive e TestFlight

Objetivo: gerar build assinado e validado pelo pipeline Apple.

Status local: IPA GERADO em 2026-06-07.

Entregue:

1. App Identifier confirmado localmente:
   - Bundle ID: `com.soloforte.soloforteApp`.
   - Team atual no Xcode: `BA2BU25B78`.

2. Signing/export confirmados no IPA:
   - Provisioning final: `iOS Team Store Provisioning Profile:
     com.soloforte.soloforteApp`.
   - `get-task-allow=false`.
   - `beta-reports-active=true`.
   - Team final: `BA2BU25B78`.
   - Bundle final: `com.soloforte.soloforteApp`.

3. `ExportOptions.plist` versionado e explicito.
   - Criado `ios/ExportOptions.plist`.
   - `manageAppVersionAndBuildNumber=false` para impedir que o Xcode altere o
     build number durante export.
   - `method=app-store-connect`.

4. Script de build reforcado.
   - `build_testflight.sh` agora usa `ios/ExportOptions.plist`.
   - O script valida que o IPA exportado preserva a versao/build do
     `pubspec.yaml`.

5. Build assinado.
   - `./build_testflight.sh`: OK.
   - Archive: `build/ios/archive/Runner.xcarchive`.
   - IPA: `build/ios/ipa/soloforte_app.ipa`.
   - Versao final do IPA: `1.34.0`.
   - Build final do IPA: `134`.
   - Tamanho do IPA: aproximadamente 36 MB.
   - `PrivacyInfo.xcprivacy` do app e dos SDKs presentes no bundle.
   - SUPABASE_URL confirmada no binario pelo script.

Observacao:

- O archive intermediario aparece com assinatura de desenvolvimento porque o
  Xcode arquiva automaticamente para device antes da exportacao. O IPA final foi
  reexportado com provisioning de Store para App Store Connect.

Pendente operacional:

1. Confirmar no App Store Connect que nenhum build igual ou superior a `134` ja
   foi enviado para a versao `1.34.0`.
2. Upload do IPA.
   - Enviar `build/ios/ipa/soloforte_app.ipa` por Transporter/Xcode Organizer,
     ou via `xcrun altool` com API key App Store Connect.
   - Aguardar processamento no App Store Connect.
   - Resolver warnings ITMS, privacidade ou SDKs antes de review.

Saida da fase: IPA App Store Connect gerado localmente; TestFlight ainda depende
de upload e processamento no App Store Connect.

## Fase 5 — Homologacao funcional em iPhone/iPad

Objetivo: provar que o app funciona em condicoes reais de review.

Status: PENDENTE DE DEVICE FISICO / TESTFLIGHT.

Checklist operacional criado:

- `docs/HOMOLOGACAO_IOS_FASE_5.md`.

Evidencia local:

- `flutter devices` detectou apenas macOS e Chrome.
- `xcrun devicectl list devices` detectou um iPhone 16 chamado `Raudinei`, mas
  em estado `unavailable`.
- Simuladores iPhone/iPad estao disponiveis, mas nao substituem a homologacao
  em device fisico exigida para esta fase.

Matriz minima:

- iPhone pequeno.
- iPhone grande.
- iPad, ja que `TARGETED_DEVICE_FAMILY` inclui iPhone/iPad em algumas configs.
- Rede boa, rede ruim e modo offline.
- Localizacao permitida, negada e negada permanentemente.

Fluxos obrigatorios:

1. Cadastro/login/logout e isolamento entre usuarios.
2. Reset de senha por `soloforte://`.
3. Mapa inicial, tiles, layers, satelite e GPS.
4. Criar cliente, fazenda, talhao e ocorrencia.
5. Iniciar/finalizar visita.
6. Gerar/exportar/compartilhar relatorio.
7. Fotos por camera e galeria.
8. Importacao KML/KMZ/GPX quando aplicavel.
9. Notificacoes de agenda.
10. Planos conforme decisao da Fase 3.
11. Exclusao de conta.
12. Testes de acessibilidade: VoiceOver, Dynamic Type e contraste.

Saida da fase: checklist assinado com evidencias de device fisico e sem crashes.
Ainda nao concluida.

## Fase 6 — App Store Connect

Objetivo: completar os requisitos de loja e review.

Status: PENDENTE DE APP STORE CONNECT / BUILD PROCESSADO.

Artefato operacional criado:

- `docs/APP_STORE_CONNECT_FASE_6.md`.

Evidencia local:

- Nome planejado: SoloForte.
- Bundle: `com.soloforte.soloforteApp`.
- Versao alinhada: `1.34.0`.
- Build local gerado: `134`.
- Metadata proposta, screenshots esperados, conta demo e notas ao revisor foram
  documentados para preenchimento manual no App Store Connect.

1. Criar versao iOS.
   - Nome: SoloForte.
   - Bundle: `com.soloforte.soloforteApp`.
   - Versao: alinhar com `1.34.0`.

2. Metadata.
   - Subtitulo ate 30 caracteres.
   - Descricao clara para agronomia de campo.
   - Keywords ate 100 caracteres.
   - Categoria: Negocios ou Produtividade.
   - URL de suporte.
   - URL de politica de privacidade.

3. Screenshots.
   - Usar dados reais ou demo realista autorizado.
   - Mostrar mapa, talhoes, visita, ocorrencia, relatorio e planos somente se
     o fluxo estiver aprovado.

4. Conta demo.
   - Usuario e senha funcionais.
   - Dados de campo pre-carregados.
   - Sem 2FA.
   - Notas ao revisor explicando Map-First, GPS e fluxo principal.

5. App Review.
   - Selecionar build TestFlight processado.
   - Preencher Export Compliance.
   - Preencher App Privacy.
   - Enviar para review.

Saida da fase: app submetido para revisao.
Ainda nao concluida: requer upload/processamento do build, Fase 5 aprovada em
device fisico, URLs publicas e acesso autenticado ao App Store Connect.

## Bloqueadores atuais por severidade

Critico:

- Politica de privacidade/App Privacy ainda precisam confirmacao no App Store Connect.
- Deploy/teste real da Edge Function `delete-user` ainda precisa confirmacao.

Alto:

- Upload/processamento no App Store Connect ainda nao executado nesta auditoria.
- Homologacao em device fisico nao executada nesta auditoria.
- Conta demo e screenshots nao confirmados.

Medio:

- Nenhum bloqueador medio local pendente nesta auditoria.

Resolvidos localmente:

- `Podfile` agora declara explicitamente `platform :ios, '13.0'`.
- `MARKETING_VERSION` do target `Runner` agora usa `$(FLUTTER_BUILD_NAME)`.
- Arquivos `.DS_Store` locais foram removidos e ja estao cobertos por
  `.gitignore`.

Observacao nao bloqueante:

- `pod install` ainda informa que o projeto usa base configuration customizada,
  mas os xcconfigs Flutter ja incluem `Pods-Runner.debug.xcconfig` e
  `Pods-Runner.release.xcconfig`; o build de Release segue validado.

## Referencias oficiais Apple

- App privacy details:
  https://developer.apple.com/app-store/app-privacy-details/
- Manage app privacy:
  https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Upload builds:
  https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds
- Submit an app:
  https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app
- Privacy manifests:
  https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Required reason APIs:
  https://developer.apple.com/documentation/BundleResources/describing-use-of-required-reason-api

## Checklist de saida para publicar

```text
[ ] arch_check.sh Exit 0
[ ] flutter analyze lib/ sem issues
[ ] flutter test passando
[ ] flutter build ios --release --no-codesign passando
[ ] Build assinado gerado localmente
[ ] Build processado no TestFlight
[ ] PrivacyInfo.xcprivacy presente e valido
[ ] App Privacy preenchido no App Store Connect
[ ] Politica de privacidade publicada
[ ] Exclusao de conta disponivel no app
[ ] Monetizacao iOS sem CTA/preco/checkout externo ou StoreKit implementado
[ ] Info.plist sem permissoes excedentes
[ ] Conta demo funcional
[ ] Screenshots e metadata prontos
[ ] Homologacao em device fisico concluida
[ ] Notas ao revisor preenchidas
```
