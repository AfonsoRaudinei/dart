# SoloForte — Checklist Real de Publicação App Store

> Bundle ID: `com.soloforte.soloforteApp` · Branch: `release/v1.1` · Supabase: `pyoejhhkjlrjijiviryq`
> Abril 2026

**Legenda:**
- 🔴 Crítico — rejeição automática
- 🟡 Importante — alta chance de rejeição ou crash
- 🔵 Atenção — risco específico do SoloForte

---

## FASE 1 — Pré-Build

### 1.1 Gates de Qualidade Obrigatórios

> ⚠️ Nenhum build enviado à App Store sem esses gates passando.

- [ ] `arch_check.sh` → Exit 0. Sem violações novas além das 3 documentadas (`database_helper`, `novo_case_sheet`, `private_map_screen`) 🔴
- [ ] `flutter analyze` → 0 errors. 1 warning pré-existente (`publicacao_editor_screen.dart`) e ~45 infos aceitáveis 🔴
- [ ] Suite `consultoria/`: 67/67 testes verdes 🔴
- [ ] Suite `drawing/`: 268/268 testes verdes 🔴
- [ ] 32 testes auth verdes (série P0+P1 — commits `bc4b648` → `edc080f`) 🔴
- [ ] `dart run build_runner build --delete-conflicting-outputs` executado — todos os `.g.dart` atualizados 🔴
- [ ] `flutter pub get` + `pod install` executados após qualquer mudança de dependência 🔴

---

### 1.2 Segredos e Credenciais — Nenhum no Código

> ⚠️ Rejeição garantida se Apple encontrar keys expostas. Ferramentas automatizadas varrem o bundle.

- [ ] Supabase URL (`pyoejhhkjlrjijiviryq.supabase.co`) em config não versionado — não hardcoded em nenhum `.dart` commitado 🔴
- [ ] Supabase anon key fora do repositório ou em arquivo `.env` não versionado 🔴
- [ ] Nenhum token Mercado Pago (`access_token`, `secret`) hardcoded no bundle 🔴
- [ ] Tile providers: Stadia Maps API key (se houver) não exposta no bundle iOS 🔴
- [ ] Google Satellite (`mt{s}.google.com/vt`, `lyrs=y`) — confirmar que uso via `flutter_map` não viola ToS do Google Maps para redistribuição em App Store 🔵
- [ ] Stadia Maps — confirmar plano permite distribuição em app store e volume de requisições esperado 🔵
- [ ] Nenhum log de dados sensíveis (tokens, `user_id`, coordenadas de clientes) em modo Release 🟡

---

### 1.3 Info.plist — Permissões Reais do SoloForte

> ⚠️ Apple rejeita permissões declaradas sem uso demonstrável no fluxo do app.

- [ ] `NSLocationWhenInUseUsageDescription` — ex: `"Localizar talhões e registrar posição em visitas de campo"` 🔴
- [ ] `NSCameraUsageDescription` — ex: `"Fotografar ocorrências, talhões e relatórios agronômicos"` 🔴
- [ ] `NSPhotoLibraryUsageDescription` — se o app lê galeria para anexar fotos aos relatórios 🔴
- [ ] `NSPhotoLibraryAddUsageDescription` — se o app salva imagens (mapas, relatórios) na galeria 🔴
- [ ] `NSLocationAlwaysUsageDescription` — SOMENTE se houver tracking em background real e documentado. Se não → **REMOVER** 🔴
- [ ] Confirmar AUSENTES: `NSMicrophoneUsageDescription`, `NSHealthShareUsageDescription`, `NSBluetoothAlwaysUsageDescription`, `NSCalendarsUsageDescription` 🟡
- [ ] Textos de permissão descrevem propósito agronômico real — sem `"app needs access"` genérico 🔴

---

### 1.4 Deep Links `soloforte://` — Ponto Crítico de Auth

> ⚠️ Principal ponto de falha do SoloForte. Configuração incompleta quebra reset de senha silenciosamente.

- [ ] `CFBundleURLTypes` no `Info.plist`: scheme = `"soloforte"`, Identifier = `"com.soloforte.soloforteApp"` 🔴
- [ ] URL Types no Xcode (Runner → Info → URL Types): idêntico ao `Info.plist` 🔴
- [ ] Supabase Dashboard → Authentication → URL Configuration → Redirect URLs contém: `soloforte://reset-password` 🔴
- [ ] Supabase Dashboard → Redirect URLs contém: `soloforte://login` 🔴
- [ ] `app_shell.dart _handleDeepLink` testado no device físico: recebe token, chama `setSession(refreshToken)` — gotrue 2.18.0 aceita **apenas** `refreshToken` 🔴
- [ ] Fluxo completo testado: e-mail de reset → clicar no link → app abre → tela de nova senha aparece 🔴
- [ ] `_authSubscription.cancel()` no `dispose` do AppShell — sem leak de listener 🟡

---

### 1.5 Auth — Exclusão de Conta (Obrigatório Apple)

> ⚠️ Apple rejeita qualquer app com criação de conta sem opção de exclusão. Sem exceção.

- [ ] Opção "Excluir conta" visível e acessível no app (perfil ou configurações), encontrável em ≤3 toques 🔴
- [ ] Exclusão remove dados do usuário no Supabase (`user_id` em todas as tabelas: `soloforte.db` v27, marketing v2, visitas v3) 🔴
- [ ] Logout limpa keepAlive providers + `clearUserLocalData` antes de `signOut` — isolamento entre sessões confirmado 🔴
- [ ] SoloForte NÃO oferece login social (Google/Facebook) → Sign in with Apple **não é obrigatório** neste build. Confirmar que nenhum login de terceiro foi adicionado. 🔵
- [ ] Fluxo de recuperação de senha testado end-to-end no device físico 🔴

---

### 1.6 SQLite e Privacidade de Dados

- [ ] `soloforte.db` v27 — decidir se deve ser excluído do backup iCloud (`NSURLIsExcludedFromBackupKey`). Dados de clientes e fazendas de agronomistas são sensíveis. 🔵
- [ ] Política de privacidade publicada em URL permanente — declara coleta de localização e dados agronômicos 🔴
- [ ] Nutrition Labels (App Store Connect) preenchido — incluir: localização precisa, dados de contato profissional, dados de uso 🔴
- [ ] Tokens Supabase armazenados via `flutter_secure_storage` — Keychain Sharing entitlement ativo no Xcode 🔴
- [ ] Todas as chamadas de rede via HTTPS: Supabase, Edge Functions, tile providers 🔴
- [ ] `NSAppTransportSecurity` sem `NSAllowsArbitraryLoads` 🔴

---

### 1.7 Mercado Pago vs StoreKit — Decisão Obrigatória Antes de Submeter

> ⚠️ Maior risco de rejeição financeira do SoloForte. Precisa estar resolvido antes do submit.

- [ ] **DECIDIR**: Mercado Pago é in-app (transação dentro do app) ou external purchase (link externo/PIX fora do app)? 🔴
- [ ] **SE IN-APP**: migrar para StoreKit obrigatoriamente. Apple rejeita pagamento digital processado fora do StoreKit. 🔴
- [ ] **SE EXTERNAL**: não exibir preço dentro do fluxo do app + incluir nota explicativa ao revisor 🔵
- [ ] Funcionalidades pagas (publicar marketing cases) bloqueadas corretamente sem plano ativo 🟡
- [ ] Edge Function `mercadopago-webhook` com validação HMAC ativa em produção 🟡

---

## FASE 2 — Build e Xcode

### 2.1 Versão e Build Number

- [ ] `CFBundleShortVersionString` incrementado em relação ao último build submetido (ex: `1.1.0`) 🔴
- [ ] `CFBundleVersion` (build number) maior que **todos** os builds anteriores enviados ao App Store Connect 🔴
- [ ] `pubspec.yaml version:` bate com `CFBundleShortVersionString+CFBundleVersion` 🟡

---

### 2.2 Configurações Xcode — Runner

- [ ] Signing & Capabilities: Team configurado, Provisioning Profile App Store selecionado manualmente 🔴
- [ ] Capability **Location** ativada — necessária para GPS de talhões e visitas 🔴
- [ ] **Keychain Sharing** ativada — necessária para `flutter_secure_storage` 🔴
- [ ] `ENABLE_BITCODE = NO` (obrigatório Xcode 14+) 🔴
- [ ] `IPHONEOS_DEPLOYMENT_TARGET` compatível com `flutter_map`, `supabase_flutter`, `gotrue 2.18.0` 🔴
- [ ] Scheme **Release** selecionado ao arquivar — nunca Debug 🔴
- [ ] Capabilities NÃO usadas desativadas: HealthKit, CarPlay, HomeKit, Siri, Wallet 🟡
- [ ] Nenhuma configuração de Debug em produção (mocks, bypass de auth, logs verbosos) 🟡

---

### 2.3 Geração do IPA

- [ ] `./build_testflight.sh` a partir de `appdart/` — sem erros fatais 🔴
- [ ] IPA gerado em `build/ios/ipa/soloforte_app.ipa` — tamanho esperado ~35MB 🔴
- [ ] Warnings de Pods deprecated — NÃO bloqueantes, documentados, ignorar 🟡
- [ ] Todos os assets declarados em `pubspec.yaml` existem fisicamente em `assets/` 🔴

---

## FASE 3 — App Store Connect

### 3.1 Upload do IPA

- [ ] IPA enviado via **Apple Transporter** (`appdart/*.ipa`) 🔴
- [ ] Build processado sem erros no App Store Connect (pode levar 15–60 min) 🔴
- [ ] Export Compliance: SoloForte usa HTTPS/TLS + `flutter_secure_storage` → marcar isenção padrão 🔴
- [ ] Build selecionado na versão correta dentro do App Store Connect 🔴

---

### 3.2 Metadados da Loja

- [ ] Ícone 1024×1024px PNG — sem transparência, sem cantos arredondados, sem texto "beta" 🔴
- [ ] Screenshots iPhone 6.9" (1320×2868px) — mín. 1 — mostrar mapa com talhões, visita ativa, ocorrência real 🔴
- [ ] Screenshots iPhone 6.5" (1242×2688px) — mín. 1 🔴
- [ ] Screenshots com dados reais de campo — sem mockups genéricos 🔴
- [ ] Nome: `"SoloForte"` ≤30 caracteres 🔴
- [ ] Subtítulo ≤30 caracteres — ex: `"Gestão agronômica de precisão"` 🟡
- [ ] Descrição ≤4000 caracteres — primeira frase descreve valor real para agronomistas (visitas, talhões, NDVI, ocorrências) 🔴
- [ ] Palavras-chave ≤100 caracteres — ex: `agronomia,visita,talhão,NDVI,ocorrência,campo,precisão` 🟡
- [ ] URL de política de privacidade definida, acessível e permanente 🔴
- [ ] Categoria: Produtividade ou Negócios 🔴
- [ ] Classificação etária: 4+ 🔴
- [ ] Preço definido (Grátis + compras in-app, ou modelo escolhido) 🔴

---

### 3.3 Conta de Demo — Obrigatória para o Revisor

> ⚠️ SoloForte exige login. Sem conta de demo funcional com dados de campo o revisor rejeita por não conseguir testar.

- [ ] Conta de demo criada no Supabase produção: e-mail + senha funcionais, sem 2FA 🔴
- [ ] Conta de demo tem: ≥1 fazenda, ≥1 talhão com polígono, ≥1 visita finalizada, ≥1 ocorrência registrada 🔴
- [ ] Credenciais informadas no App Store Connect → App Review Information → Sign-in Information 🔴
- [ ] Conta de demo NÃO expira durante o período de review (normalmente 1–7 dias) 🔴
- [ ] Notas ao revisor: explicar navegação Map-First, como criar visita, onde estão ocorrências e relatórios 🟡
- [ ] Se NDVI exige processamento assíncrono: avisar ao revisor que o resultado aparece após alguns instantes 🟡
- [ ] Adicionar nota: stubs Clima e Calculadora são funcionalidades em desenvolvimento, disponíveis em versão futura 🟡
- [ ] Número de contato ou e-mail de suporte informado 🟡

---

## FASE 4 — TestFlight (Antes de Submit for Review)

> ℹ️ Build 64 enviado ao TestFlight: **NÃO CONFIRMADO**. Confirmar antes de submeter.

- [ ] Build confirmado como "Pronto para Teste" no App Store Connect 🔴
- [ ] App testado em **dispositivo físico iOS** — não só simulador 🔴
- [ ] Fluxo completo: login → mapa abre → GPS ativa → visita criada → ocorrência adicionada → relatório gerado → logout 🔴
- [ ] Fluxo reset senha end-to-end no device: e-mail → link → `soloforte://` → tela nova senha 🔴
- [ ] App funciona offline: mapa carrega (tiles cache), SQLite local responde, estado offline visível 🟡
- [ ] NDVI cache funciona offline após primeira sincronização 🟡
- [ ] Nenhum dado do usuário A visível após logout e login com usuário B (isolamento `user_id`) 🔴
- [ ] Crash-free no fluxo principal durante TestFlight 🔴
- [ ] SideMenu abre/fecha: Relatórios, Agenda, Clientes, Planos, Feedback, Configurações 🟡
- [ ] Stubs Clima e Calculadora com `Opacity(0.45)` não respondem ao tap 🟡
- [ ] Coluna do mapa tem exatamente 5 botões: edit, layers, ocorrências, marketing, check-in 🟡
- [ ] Check-in/check-out: fundo verde com visita ativa, normal sem visita 🟡

---

## FASE 5 — Submissão Final

- [ ] Todos os itens das Fases 1 a 4 concluídos 🔴
- [ ] Submit for Review enviado no App Store Connect 🔴
- [ ] Monitorar e-mail e App Store Connect — revisão costuma levar 1–3 dias úteis 🟡

---

## Rejeições Comuns — Específicas do SoloForte

| Código / Motivo | Risco no SoloForte | Ação |
|---|---|---|
| 2.1 — Performance | Crash ao abrir mapa com GPS ou sincronizar SQLite v27 | Testar em device físico — nunca só simulador |
| 2.3.1 — Metadata | Screenshots sem dados reais de campo | Screenshots com mapa real, visita em progresso, ocorrência |
| 5.1.1 — Privacy | Nutrition Labels sem localização ou dados profissionais | Incluir localização precisa e dados de contato de agronomistas |
| 5.1.2 — Permission | GPS solicitado na abertura do app sem contexto | Solicitar ao iniciar uma visita, não ao abrir o app |
| 5.1.1(iv) — Exclusão | SoloForte tem criação de conta → exclusão obrigatória | Botão de exclusão acessível em ≤3 toques |
| 3.1.1 — In-App Purchase | Mercado Pago processando transação dentro do app | Migrar para StoreKit OU usar modelo external |
| Deep link inoperante | `soloforte://` não configurado → reset de senha quebrado | `CFBundleURLTypes` + Redirect URLs no Supabase antes do build |
| 4.0 — Design | Stubs Clima/Calculadora parecem funcionalidade quebrada | Nota ao revisor: "em desenvolvimento, disponível em versão futura" |

---

*SoloForte · release/v1.1 · Abril 2026*
