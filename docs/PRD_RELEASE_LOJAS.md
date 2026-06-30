# PRD — SoloForte App: Release para App Store e Google Play

**Versão do documento:** 1.0  
**Data:** 29/06/2026  
**Status:** Aprovado para planejamento  
**Produto:** SoloForte App (Flutter · iOS · Android)  
**Versão alvo de release:** 1.0.0 (build de produção)

---

## 1. Resumo executivo

O SoloForte App possui uma base funcional sólida para operação de campo (mapa, visitas, ocorrências offline), mas **não está apto para publicação nas lojas**. Este PRD define todos os reparos necessários para transformar o protótipo atual em um **aplicativo funcional, seguro e conforme** com os requisitos da Apple App Store, Google Play Store e LGPD.

**Estado atual estimado:** ~30% pronto para lojas  
**Meta deste PRD:** ≥ 90% pronto para submissão com alta confiança de aprovação

**Princípio inegociável do produto** (conforme `docs/arquitetura-navegacao.md`):
> Map-first · Mobile-only · Offline como regra · Online como bônus

---

## 2. Problema

Consultores agrícolas precisam registrar visitas de campo, ocorrências e dados de clientes **com ou sem internet**. O app atual:

- Simula login (qualquer credencial funciona)
- Não sincroniza dados com backend
- Declara permissões sensíveis sem implementação adequada
- Não possui documentação legal exigida pelas lojas
- Usa configuração de build inadequada para produção (Android assinado com debug)

**Consequência:** submissão hoje resultaria em **rejeição garantida** e exposição a riscos de segurança e LGPD.

---

## 3. Objetivos

| # | Objetivo | Métrica de sucesso |
|---|----------|-------------------|
| O1 | Publicar nas lojas iOS e Android | Aprovação na 1ª ou 2ª submissão |
| O2 | Autenticação real e segura | 100% das sessões via Supabase Auth |
| O3 | Sync confiável offline → online | Zero perda de dados em teste de 7 dias |
| O4 | Conformidade legal (LGPD + lojas) | Política de privacidade, termos e exclusão de conta ativos |
| O5 | Build de produção assinado | APK/AAB e IPA gerados com certificados corretos |
| O6 | Qualidade mínima garantida | ≥ 80% cobertura dos fluxos críticos testados |

---

## 4. Escopo

### 4.1 Dentro do escopo (v1.0 Release)

- Autenticação real (login, cadastro, logout, exclusão de conta)
- Integração Supabase (Auth + sync de dados agrícolas)
- Correção de permissões iOS/Android
- Conformidade legal (privacidade, termos, LGPD)
- Build e assinatura de release
- Correção de bugs bloqueadores identificados na auditoria
- Completar funcionalidades placeholder críticas
- Testes automatizados dos fluxos principais
- Documentação de release (Data Safety, App Privacy)

### 4.2 Fora do escopo (v1.0)

- Web, Windows, macOS, Linux
- Scanner, IA, gráficos avançados
- Push notifications remotas (FCM/APNs)
- Certificate pinning
- Jailbreak/root detection
- Internacionalização (i18n) além de pt-BR

---

## 5. Personas

| Persona | Necessidade principal |
|---------|----------------------|
| **Consultor de campo** | Registrar visitas e ocorrências offline no mapa |
| **Gestor da consultoria** | Ver clientes, fazendas e relatórios sincronizados |
| **Operador de compliance** | App conforme LGPD e políticas das lojas |

---

## 6. Épicos e requisitos

Prioridade: **P0** (bloqueador de loja) · **P1** (funcionalidade real) · **P2** (qualidade/polish)

---

### ÉPICO 1 — Autenticação e sessão segura `[P0]`

**Problema atual:** `AuthService` é fake; token salvo em `SharedPreferences` em texto claro.

| ID | Requisito | Critério de aceite |
|----|-----------|-------------------|
| AUTH-01 | Integrar Supabase Auth no `main.dart` | `Supabase.initialize()` com URL e anon key via `--dart-define` ou env seguro |
| AUTH-02 | Substituir `AuthService` fake por auth real | Login com e-mail/senha validados no Supabase; erro claro em credenciais inválidas |
| AUTH-03 | Cadastro real | Criação de conta no Supabase; confirmação de e-mail configurável |
| AUTH-04 | Armazenamento seguro de sessão | Migrar token para `flutter_secure_storage` (Keychain / EncryptedSharedPreferences) |
| AUTH-05 | Refresh e expiração de sessão | Sessão expirada redireciona para login; refresh automático quando possível |
| AUTH-06 | Exclusão de conta in-app | Fluxo em Configurações → excluir conta → confirmação → delete no Supabase (obrigatório Apple) |
| AUTH-07 | Validação de inputs | E-mail válido, senha mín. 8 caracteres, campos obrigatórios no signup |
| AUTH-08 | Mensagens de erro amigáveis | Substituir `e.toString()` por mensagens localizadas; sem stack trace na UI |

**Arquivos impactados:** `lib/main.dart`, `lib/core/auth/`, `lib/core/session/`, `lib/ui/screens/login_screen.dart`, `lib/ui/screens/signup_screen.dart`, `lib/modules/settings/`

---

### ÉPICO 2 — Backend Supabase e sincronização `[P0/P1]`

**Problema atual:** `supabase_flutter` instalado mas nunca inicializado; `SyncService` e `AgronomicSyncService` não conectados.

| ID | Requisito | Critério de aceite |
|----|-----------|-------------------|
| SYNC-01 | Inicializar cliente Supabase | App conecta ao projeto configurado em staging e produção |
| SYNC-02 | RLS por usuário/tenant | Políticas restritas: usuário só acessa seus clientes/dados |
| SYNC-03 | Push local → remoto | Clientes, fazendas, talhões, visitas, ocorrências e relatórios sincronizam |
| SYNC-04 | Pull remoto → local | Delta sync com `updated_at`; conflito resolvido por last-write-wins documentado |
| SYNC-05 | Sync silencioso ativo | `syncServiceProvider` instanciado no startup; retry em reconexão |
| SYNC-06 | Indicador de status (opcional mínimo) | Ícone discreto ou contador de pendentes em Configurações |
| SYNC-07 | Sync de ocorrências e visitas | Remover TODOs em `sync_service.dart`; implementar métodos reais |
| SYNC-08 | Schema alinhado | SQLite local e Supabase com campos compatíveis; migration v5+ testada |

**Arquivos impactados:** `lib/core/services/sync_service.dart`, `lib/modules/consultoria/services/agronomic_sync_service.dart`, `supabase_schema.sql`, controllers de visita e ocorrência

---

### ÉPICO 3 — Conformidade legal e privacidade `[P0]`

**Problema atual:** Sem política de privacidade; termos inativos; LGPD ~15% conforme.

| ID | Requisito | Critério de aceite |
|----|-----------|-------------------|
| LEGAL-01 | Política de Privacidade publicada | URL HTTPS acessível; link em Configurações e no cadastro |
| LEGAL-02 | Termos de Serviço | URL HTTPS; botão funcional em Configurações |
| LEGAL-03 | Consentimento no cadastro | Checkbox obrigatório "Li e aceito Termos e Política" |
| LEGAL-04 | Formulário Data Safety (Google Play) | Todos os dados coletados declarados (localização, fotos, e-mail, dados agrícolas) |
| LEGAL-05 | App Privacy (Apple) | Labels de coleta alinhadas ao comportamento real do app |
| LEGAL-06 | Canal de contato LGPD | E-mail ou formulário para solicitações do titular |
| LEGAL-07 | Base legal documentada | Política descreve finalidade, retenção e compartilhamento |

---

### ÉPICO 4 — Permissões e privacidade nativa `[P0]`

**Problema atual:** Permissões declaradas incorretamente; usage descriptions iOS incompletas.

| ID | Requisito | Critério de aceite |
|----|-----------|-------------------|
| PERM-01 | iOS: NSCameraUsageDescription | Texto em pt-BR explicando uso da câmera |
| PERM-02 | iOS: NSPhotoLibraryUsageDescription | Texto em pt-BR para galeria |
| PERM-03 | iOS: PrivacyInfo.xcprivacy | Manifest criado conforme SDKs de terceiros |
| PERM-04 | Android: POST_NOTIFICATIONS | Declarada + runtime request (API 33+) |
| PERM-05 | Android: CAMERA + READ_MEDIA_IMAGES | Declaradas conforme uso do image_picker |
| PERM-06 | Decisão sobre background location | **Opção A (recomendada v1):** remover `ACCESS_BACKGROUND_LOCATION` e strings "Always" · **Opção B:** implementar foreground service + fluxo Google |
| PERM-07 | Geofence apenas em foreground | Monitoramento GPS pausa em background (v1) ou implementação completa (v1.1) |
| PERM-08 | NotificationService.init() no startup | Notificações locais funcionam ao entrar em geofence |

**Arquivos impactados:** `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`, `lib/main.dart`, `lib/core/services/notification_service.dart`

---

### ÉPICO 5 — Build, assinatura e identidade `[P0]`

**Problema atual:** Android release com debug keystore; bundle IDs inconsistentes; label técnico.

| ID | Requisito | Critério de aceite |
|----|-----------|-------------------|
| BUILD-01 | Keystore Android de produção | `signingConfig` release com keystore seguro (CI secrets) |
| BUILD-02 | Certificados iOS de distribuição | Provisioning profile App Store configurado |
| BUILD-03 | Bundle ID unificado | Mesmo identificador lógico: `com.soloforte.app` (iOS + Android) |
| BUILD-04 | Nome do app nas lojas | Label Android: "SoloForte" (não `soloforte_app`) |
| BUILD-05 | Versão e build number | `1.0.0+1` incrementável; processo documentado |
| BUILD-06 | ProGuard/R8 Android | Minificação habilitada em release; testes de smoke pós-build |
| BUILD-07 | Ícones finais | launcher_icon consistente; 1024×1024 iOS sem alpha |
| BUILD-08 | userAgentPackageName | Alinhado ao bundle ID real nos TileLayers |

**Arquivos impactados:** `android/app/build.gradle.kts`, `ios/Runner.xcodeproj/`, `pubspec.yaml`, manifests

---

### ÉPICO 6 — Correção de bugs bloqueadores `[P0/P1]`

| ID | Bug | Severidade | Critério de aceite |
|----|-----|------------|-------------------|
| BUG-01 | Migração SQLite duplicada (v1→v2) | Alta | Upgrade de DB v1 para v5 sem crash; teste automatizado |
| BUG-02 | Sync nunca instanciado | Alta | Provider ativo no `main.dart` ou `ProviderScope` |
| BUG-03 | Notificações sem init | Alta | Geofence dispara notificação visível em dispositivo real |
| BUG-04 | Edição de ocorrência placeholder | Média | Tap no pin abre sheet de edição funcional |
| BUG-05 | Limpar dados locais não executa | Média | Ação apaga SQLite + cache; confirmação funciona |
| BUG-06 | Switches fake em Configurações | Média | Modo offline e notificações persistem preferência ou ficam ocultos até implementação |
| BUG-07 | SessionUnknown flash redirect | Baixa | Splash/loading enquanto sessão inicializa |
| BUG-08 | Alerta visita longa repetitivo | Baixa | Notifica no máximo 1× por sessão |
| BUG-09 | print() em produção | Baixa | Substituir por logger condicional (`kDebugMode`) |

---

### ÉPICO 7 — Completar funcionalidades placeholder `[P1]`

| ID | Tela/Feature | Estado atual | Critério de aceite v1.0 |
|----|--------------|--------------|------------------------|
| FEAT-01 | Agenda | Placeholder | Listar eventos do SQLite; criar/editar evento básico |
| FEAT-02 | Feedback | Placeholder | Formulário envia e-mail ou grava no Supabase |
| FEAT-03 | Modo offline | Switch fake | Toggle persiste; sync pausa quando offline forçado |
| FEAT-04 | Limpar cache | Ação vazia | Remove tiles cacheados e arquivos temporários |
| FEAT-05 | Relatórios KPI | Parcial | Export PDF funcional; dados reais do SQLite |
| FEAT-06 | Lista de ocorrências | Parcial | Filtros e edição integrados ao mapa |

---

### ÉPICO 8 — Segurança de dados `[P1]`

| ID | Requisito | Critério de aceite |
|----|-----------|-------------------|
| SEC-01 | RLS Supabase restritivo | Políticas por `auth.uid()` ou tenant_id |
| SEC-02 | Secrets fora do código | URL/keys via dart-define ou CI; nunca commitadas |
| SEC-03 | SQLite com dados sensíveis | Avaliar SQLCipher ou criptografia de campos PII |
| SEC-04 | Sanitização de inputs | SQL injection impossível (queries parametrizadas — já OK) |
| SEC-05 | Sessão invalidada no logout | Token removido do secure storage + Supabase signOut |

---

### ÉPICO 9 — Qualidade, testes e CI `[P1/P2]`

| ID | Requisito | Critério de aceite |
|----|-----------|-------------------|
| QA-01 | Testes unitários auth | Login, logout, token storage |
| QA-02 | Testes unitários sync | Push/pull mockado |
| QA-03 | Testes widget login/signup | Render + validação de campos |
| QA-04 | Testes integração SQLite | Migrations v1→v5 |
| QA-05 | CI GitHub Actions | `flutter analyze` + `flutter test` em PR |
| QA-06 | Smoke test manual checklist | Documento com 30 cenários; 100% pass antes de submeter |
| QA-07 | Teste em dispositivos reais | Mín. 1 iPhone + 1 Android (API 33+) |

---

### ÉPICO 10 — Metadados das lojas `[P1]`

| ID | Requisito | Critério de aceite |
|----|-----------|-------------------|
| STORE-01 | Screenshots | 6.7" iPhone + phone Android (mín. 4 telas) |
| STORE-02 | Descrição pt-BR | Texto alinhado ao produto real (não template) |
| STORE-03 | Categoria | Produtividade / Negócios |
| STORE-04 | Classificação etária | 4+ (sem conteúdo restrito) |
| STORE-05 | Export compliance iOS | ITSAppUsesNonExemptEncryption = NO (se aplicável) |
| STORE-06 | Conta de teste para review | Credenciais demo documentadas para Apple/Google |

---

## 7. Requisitos não funcionais

| Categoria | Requisito |
|-----------|-----------|
| **Performance** | Mapa abre em < 3s em dispositivo mid-range |
| **Offline** | 100% das operações de campo funcionam sem rede |
| **Bateria** | Geofence em foreground: check a cada 45–60s (não agressivo) |
| **Acessibilidade** | Contraste mínimo WCAG AA nos textos principais |
| **Compatibilidade** | iOS 15+ · Android 8+ (API 26+) · targetSdk atual Play |
| **Tamanho** | APK/AAB < 50 MB (ideal) |
| **Logs** | Zero logs sensíveis em release |

---

## 8. Arquitetura de release (referência)

```
┌─────────────────────────────────────────────────────────┐
│                    SoloForte App                         │
├─────────────────────────────────────────────────────────┤
│  UI (Map-first) → Riverpod → Controllers/Repositories   │
├──────────────────────┬──────────────────────────────────┤
│   SQLite (offline)   │   Supabase (online)              │
│   - visitas          │   - Auth                         │
│   - ocorrências      │   - clients/farms/fields         │
│   - clientes         │   - sync delta                   │
├──────────────────────┴──────────────────────────────────┤
│  Secure Storage (token) · Local Notifications · GPS      │
└─────────────────────────────────────────────────────────┘
```

**Regra de sync:** local sempre ganha se `sync_status = dirty` e `updated_at` local > remoto.

---

## 9. Fases de entrega

### Fase 1 — Desbloqueio de loja `[P0]` → meta ~70%

1. Auth real + secure storage + exclusão de conta  
2. Permissões iOS/Android corrigidas  
3. Política de privacidade + termos  
4. Build assinado (Android + iOS)  
5. Privacy Manifest iOS  
6. Bundle ID unificado  
7. Bugs BUG-01 a BUG-03  

**Gate:** build release instalável em dispositivo físico; login real funciona.

### Fase 2 — Produto funcional `[P1]` → meta ~85%

1. Supabase sync completo  
2. RLS restritivo  
3. Funcionalidades placeholder críticas (Agenda, limpar dados, edição ocorrência)  
4. Testes automatizados fluxos críticos  
5. CI pipeline  

**Gate:** consultor usa app 1 dia inteiro offline e sincroniza ao reconectar.

### Fase 3 — Polish e submissão `[P1/P2]` → meta ~90%+

1. Metadados das lojas  
2. Smoke test checklist 100%  
3. Data Safety + App Privacy preenchidos  
4. Remoção de prints e placeholders restantes  
5. Submissão App Store Connect + Play Console  

**Gate:** aprovação nas lojas.

---

## 10. Critérios de aceite globais (Definition of Done)

Um item só é **Done** quando:

- [ ] Código implementado e revisado  
- [ ] `flutter analyze` sem erros  
- [ ] Testes relacionados passando  
- [ ] Testado em dispositivo físico (iOS ou Android conforme escopo)  
- [ ] Documentação atualizada se aplicável  
- [ ] Sem regressão nos fluxos mapa → visita → ocorrência  

**Release Done** quando todos os itens **P0** e **P1** estão Done + checklist da Seção 11 completo.

---

## 11. Checklist final de submissão

### Apple App Store

- [ ] Build assinado com certificado de distribuição  
- [ ] PrivacyInfo.xcprivacy incluído  
- [ ] App Privacy labels preenchidos  
- [ ] Política de privacidade URL no App Store Connect  
- [ ] Exclusão de conta in-app funcional  
- [ ] Usage descriptions completas (GPS, câmera, fotos)  
- [ ] Conta demo para review  
- [ ] Screenshots e descrição pt-BR  

### Google Play Store

- [ ] AAB assinado com keystore de produção  
- [ ] Data Safety form completo  
- [ ] Política de privacidade URL  
- [ ] targetSdk conforme requisito atual  
- [ ] Permissões justificadas (sem background location se não usada)  
- [ ] Conta demo para review  
- [ ] Screenshots e descrição pt-BR  

### LGPD

- [ ] Política de privacidade acessível no app  
- [ ] Consentimento no cadastro  
- [ ] Exclusão de conta disponível  
- [ ] Canal de contato do titular  

---

## 12. Riscos e mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Rejeição por background location | Alto | Remover permissão na v1; geofence só em foreground |
| RLS mal configurado expõe dados | Crítico | Testes de isolamento por usuário antes de produção |
| Perda de dados no sync | Alto | Testes offline 7 dias; backup local antes de sync |
| Atraso na revisão Apple | Médio | Submeter cedo; conta demo clara |
| Keystore Android perdida | Crítico | Backup seguro do keystore; Play App Signing habilitado |

---

## 13. Dependências externas

| Dependência | Responsável | Necessário para |
|-------------|-------------|-----------------|
| Projeto Supabase (prod) | Backend/DevOps | Auth + sync |
| URLs de Política e Termos | Jurídico/Product | Conformidade |
| Keystore Android | DevOps | Play Store |
| Apple Developer Account | Product | App Store |
| Google Play Console | Product | Play Store |
| Certificados iOS | DevOps | App Store |

---

## 14. Métricas pós-release

| Métrica | Meta 30 dias |
|---------|--------------|
| Crash-free rate | ≥ 99,5% |
| Taxa de sync bem-sucedida | ≥ 95% |
| Tempo médio de login | < 2s |
| Avaliação nas lojas | ≥ 4,0 |
| Rejeições de review | 0 após aprovação inicial |

---

## 15. Referências

- Auditoria de release (jun/2026) — análise estática do repositório  
- `docs/arquitetura-navegacao.md` — contrato de navegação (congelado)  
- `docs/persistenca-agricola.md` — modelo offline/sync  
- `supabase_schema.sql` — schema remoto base  
- `.agent/AUDITORIA_PRE_RELEASE_V1.md` — baseline funcional v1  

---

## 16. Resumo de prioridades (backlog executivo)

| Prioridade | Qtd. itens | Foco |
|------------|-----------|------|
| **P0** | 28 | Bloqueadores de loja — fazer primeiro |
| **P1** | 22 | Produto realmente funcional |
| **P2** | 8 | Qualidade e polish |
| **Total** | **58 requisitos** | |

**Ordem recomendada de execução:**

```
P0: Auth → Legal → Permissões → Build → Bugs críticos
         ↓
P1: Sync → Segurança RLS → Features placeholder → Testes
         ↓
P2: CI → Metadados lojas → Polish → Submissão
```

---

*Documento gerado a partir da auditoria de prontidão para App Store e Google Play. Revisar a cada fase concluída.*
