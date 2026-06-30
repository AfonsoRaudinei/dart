# PLANO DE IMPLEMENTAÇÃO: MAPA PÚBLICO V2.0
**Data Inicial:** 09 de fevereiro de 2026  
**Data Conclusão:** 10 de fevereiro de 2026  
**Desenvolvedor:** Top 0.1% Flutter/Dart Senior Engineer  
**Status:** ✅ **TODAS AS FASES CONCLUÍDAS** (100%)

**Tempo Total:** ~185 minutos (estimado: 270-360 min)  
**Eficiência:** 146% 🚀

---

## 📊 RESUMO DE EXECUÇÃO

| Fase | Status | Tempo Real | Estimado |
|------|--------|------------|----------|
| FASE 1 | ✅ CONCLUÍDA | ~20 min | 30-45 min |
| FASE 2 | ✅ CONCLUÍDA | ~35 min | 45-60 min |
| FASE 3 | ✅ CONCLUÍDA | ~15 min | 30 min |
| FASE 4 | ✅ CONCLUÍDA | ~35 min | 60-90 min |
| FASE 5 | ✅ CONCLUÍDA | ~40 min | 60-75 min |
| FASE 6 | ✅ CONCLUÍDA | ~40 min | 45-60 min |

**Relatório detalhado:** Ver `FASE_6_RELATORIO_FINAL.md`

---

## 📋 RESUMO EXECUTIVO

### Objetivo
Reformular completamente a tela de **Mapa Público** (`/public-map`) como a **primeira tela do aplicativo** (pré-login), com funcionalidades específicas:

1. ✅ Botão "Acessar SoloForte" com ícone do app (centralizado na parte inferior)
2. ✅ Botão de localização que centraliza no usuário (ponto azul)
3. ✅ Zoom manual com limites (min/max configuráveis)
4. ✅ Novo estilo de mapa (camada personalizada - estilo da imagem 2)
5. ✅ Exibição de publicações (fotos/pins) no mapa - **SOMENTE VISUALIZAÇÃO**

### Princípios Arquiteturais
- **MAP-FIRST:** Seguir rigorosamente `docs/arquitetura-navegacao.md`
- **OFFLINE-FIRST:** Preparar para cache e persistência
- **ISOLAMENTO:** `/public-map` NÃO compartilha estado com `/map` (privado)
- **MOBILE-ONLY:** iOS e Android apenas

---

## 🎯 ANÁLISE DE CONTEXTO ATUAL

### Arquivos Principais Identificados
```
lib/ui/screens/public_map_screen.dart       [EXISTENTE - 56 linhas]
lib/core/router/app_router.dart             [EXISTENTE - navegação OK]
lib/core/domain/publicacao.dart             [EXISTENTE - modelo de publicação]
lib/ui/components/map/publicacao_pins.dart  [EXISTENTE - pins para mapa privado]
assets/images/app_icon.png                  [EXISTENTE]
```

### Dependências Instaladas
```yaml
flutter_map: ^7.0.0                  ✅
latlong2: ^0.9.1                     ✅
geolocator: ^13.0.2                  ✅
permission_handler: ^11.3.1          ✅
flutter_map_marker_cluster: ^1.4.0   ✅
```

### Estado Atual do `public_map_screen.dart`
- ✅ FlutterMap básico funcionando
- ✅ TileLayer OpenStreetMap
- ❌ Sem botão de acesso ao app
- ❌ Sem botão de localização
- ❌ Sem limites de zoom
- ❌ Sem camada de mapa personalizada
- ❌ Sem publicações

---

## 📐 ARQUITETURA PROPOSTA

### Estrutura de Componentes
```
/public-map (Tela Raiz Pré-Login)
├── FlutterMap (Widget Principal)
│   ├── TileLayer (Camada Base - Novo Estilo)
│   ├── MarkerLayer (Publicações - Pins)
│   └── CircleLayer (Localização do Usuário - Ponto Azul)
├── LocationButton (FAB Superior Direito)
├── AccessButton (Centralizado Inferior - CTA Principal)
└── ZoomControls (Controles Manuais - Opcional)
```

### Fluxo de Navegação
```
[App Inicia]
    ↓
[Usuário NÃO autenticado?]
    ↓
[/public-map carrega]
    ↓
[Usuário clica "Acessar SoloForte"]
    ↓
[Navega para /login]
```

### Providers/Controllers Necessários
```dart
// NÃO usar LocationController compartilhado
// Criar provider isolado para mapa público

@riverpod
class PublicMapController extends _$PublicMapController {
  // Localização do usuário
  // Zoom atual
  // Publicações mockadas ou via API pública
}
```

---

## 🔧 PLANO DE EXECUÇÃO POR FASES

### **FASE 1: FUNDAÇÃO E BOTÃO DE ACESSO** ⚡
**Complexidade:** Baixa  
**Tempo Estimado:** 30-45 min  
**Arquivos Afetados:** 2-3

#### Tarefas:
1. **Criar componente `AccessSoloForteButton`**
   - Localização: `lib/ui/components/public_map/access_button.dart`
   - Design: Container com ícone + texto "Acessar SoloForte"
   - Ação: Navegar para `/login` via `context.go(AppRoutes.login)`
   - Estilo: SoloForte Theme (verde + branco)

2. **Atualizar `public_map_screen.dart`**
   - Adicionar botão na Stack (Positioned bottom center)
   - Padding: 24px bottom, 20px horizontal
   - Shadow e border-radius

3. **Teste Manual**
   - Clicar no botão → redireciona para login
   - Verificar alinhamento e responsividade

**Critérios de Sucesso:**
- ✅ Botão visível e centralizado
- ✅ Navegação para login funcionando
- ✅ Design consistente com tema do app

---

### **FASE 2: LOCALIZAÇÃO DO USUÁRIO (GPS)** 🗺️
**Complexidade:** Média  
**Tempo Estimado:** 45-60 min  
**Arquivos Afetados:** 3-4

#### Tarefas:
1. **Criar `PublicLocationController`**
   - Localização: `lib/modules/dashboard/controllers/public_location_controller.dart`
   - Provider Riverpod isolado
   - Métodos:
     - `requestLocationPermission()` → solicita permissão
     - `getCurrentPosition()` → obtém lat/lng atual
     - `centerMapOnUser()` → move MapController

2. **Criar `LocationFAB` (Botão de Localização)**
   - Localização: `lib/ui/components/public_map/location_button.dart`
   - Ícone: `Icons.my_location`
   - Posicionamento: Superior direito (top: 60, right: 16)
   - Estados:
     - Loading (circular progress)
     - Active (azul)
     - Error (vermelho)

3. **Adicionar CircleMarker para posição do usuário**
   - Cor azul translúcido
   - Raio: 10px
   - Borda branca

4. **Atualizar `public_map_screen.dart`**
   - Adicionar LocationFAB à Stack
   - Conectar ao controller
   - Atualizar mapa quando localização obtida

5. **Configurar Permissões**
   - iOS: `ios/Runner/Info.plist` → `NSLocationWhenInUseUsageDescription`
   - Android: `android/app/src/main/AndroidManifest.xml` → `ACCESS_FINE_LOCATION`

**Critérios de Sucesso:**
- ✅ Botão solicita permissão de GPS
- ✅ Mapa centraliza na posição do usuário
- ✅ Ponto azul aparece no local correto
- ✅ Funciona em iOS e Android

---

### **FASE 3: CONTROLES DE ZOOM MANUAL** 🔍
**Complexidade:** Baixa  
**Tempo Estimado:** 30 min  
**Arquivos Afetados:** 2

#### Tarefas:
1. **Atualizar MapOptions em `public_map_screen.dart`**
   ```dart
   MapOptions(
     initialCenter: LatLng(-23.5505, -46.6333),
     initialZoom: 13.0,
     minZoom: 3.0,        // ← Limite mínimo
     maxZoom: 18.0,       // ← Limite máximo
     interactionOptions: const InteractionOptions(
       flags: InteractiveFlag.all, // Permitir pinch-zoom e drag
     ),
   )
   ```

2. **[OPCIONAL] Criar botões +/- de zoom**
   - Componente: `lib/ui/components/public_map/zoom_controls.dart`
   - Posicionamento: Canto inferior direito
   - Métodos: `_mapController.move(center, zoom + 1)` e `zoom - 1`

3. **Teste de Limites**
   - Usuário tenta zoom out além do mínimo → travado
   - Usuário tenta zoom in além do máximo → travado

**Critérios de Sucesso:**
- ✅ Zoom por gestos (pinch) funcionando
- ✅ Limites respeitados (min: 3, max: 18)
- ✅ [Opcional] Botões +/- operacionais

---

### **FASE 4: NOVA CAMADA DE MAPA (ESTILO PERSONALIZADO)** 🎨
**Complexidade:** Média-Alta  
**Tempo Estimado:** 60-90 min  
**Arquivos Afetados:** 3-4

#### Contexto:
A segunda imagem mostra um **estilo de mapa customizado** (não é o padrão OpenStreetMap).
Opções para implementação:

#### Opção A: Mapbox Vector Tiles (Recomendado)
- **Serviço:** Mapbox (conta gratuita: 50k tiles/mês)
- **Configuração:**
  ```dart
  TileLayer(
    urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
    additionalOptions: {
      'accessToken': 'YOUR_MAPBOX_TOKEN',
      'id': 'mapbox/streets-v12', // ou custom style
    },
  )
  ```

#### Opção B: Stadia Maps (Alternativa)
- Tiles gratuitos com estilo personalizado
- URL: `https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png`

#### Opção C: Custom Style via Carto
- Tiles com visual clean e moderno
- URL: `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png`

#### Tarefas:
1. **Configurar conta no serviço escolhido** (ex: Mapbox)
2. **Criar arquivo de configuração**
   - Localização: `lib/core/config/map_config.dart`
   - Armazenar tokens/URLs
   - Enum para estilos de mapa

3. **Atualizar `public_map_screen.dart`**
   - Substituir TileLayer pelo novo provider
   - Adicionar fallback (OpenStreetMap) se falhar

4. **Adicionar chave ao `API_KEYS_MASTER.md`**

5. **Testar renderização**
   - Verificar carregamento de tiles
   - Validar performance
   - Testar offline (cache de tiles)

**Critérios de Sucesso:**
- ✅ Novo estilo de mapa renderizando
- ✅ Performance aceitável (FPS > 30)
- ✅ Cache de tiles funcionando
- ✅ Fallback para OpenStreetMap se necessário

---

### **FASE 5: PUBLICAÇÕES NO MAPA (PINS)** 📌
**Complexidade:** Média  
**Tempo Estimado:** 60-75 min  
**Arquivos Afetados:** 4-5

#### Tarefas:
1. **Criar Provider de Publicações Públicas**
   ```dart
   // lib/modules/public/providers/public_publications_provider.dart
   
   @riverpod
   Future<List<Publicacao>> publicPublications(Ref ref) async {
     // Buscar publicações públicas da API Supabase
     // OU retornar mocks para desenvolvimento
     return _mockPublicacoes;
   }
   ```

2. **Adaptar `PublicacaoPins` para mapa público**
   - Criar cópia: `lib/ui/components/public_map/public_publication_pins.dart`
   - **REMOVER** todas ações de edição/exclusão
   - **MANTER** apenas visualização (preview)

3. **Criar `PublicPublicationPreview`**
   - Similar ao `PublicacaoPreviewSheet` mas simplificado
   - Apenas: foto, título, descrição
   - Sem botões de ação (editar/excluir/navegar)

4. **Atualizar `public_map_screen.dart`**
   - Adicionar `MarkerClusterLayer` para pins
   - Conectar ao provider de publicações
   - Tap no pin → abre preview modal

5. **Configurar Query Supabase (opcional)**
   ```sql
   -- Apenas publicações públicas (is_public = true)
   SELECT * FROM publicacoes WHERE is_public = true LIMIT 100;
   ```

6. **Adicionar loading state**
   - Skeleton/shimmer enquanto carrega publicações

**Critérios de Sucesso:**
- ✅ Pins aparecem no mapa
- ✅ Clustering funciona (agrupa pins próximos)
- ✅ Tap abre preview com foto e informações
- ✅ **NENHUMA** ação de edição disponível
- ✅ Performance OK com 50+ pins

---

### **FASE 6: REFINAMENTO E POLISH** ✨
**Complexidade:** Baixa-Média  
**Tempo Estimado:** 45-60 min  
**Arquivos Afetados:** 3-5

#### Tarefas:
1. **Animações e Transições**
   - Animação suave ao centralizar no usuário
   - Fade in dos pins ao carregar
   - Hero animation do logo (se aplicável)

2. **Estados de Erro**
   - Sem permissão de GPS → mostrar dialog explicativo
   - Sem internet → usar tiles em cache
   - Falha ao carregar publicações → retry button

3. **Acessibilidade**
   - Semantic labels em todos os botões
   - Contrast ratio > 4.5:1
   - Touch targets ≥ 48x48px

4. **Performance**
   - Debounce em eventos de zoom/pan
   - Lazy loading de tiles
   - Image caching para pins

5. **Documentação**
   - Atualizar `docs/arquitetura-navegacao.md` (seção `/public-map`)
   - Adicionar comentários inline
   - Criar ADR (Architectural Decision Record) para escolha de tile provider

**Critérios de Sucesso:**
- ✅ Animações fluidas (60 FPS)
- ✅ Tratamento de erros robusto
- ✅ Score de acessibilidade > 90%
- ✅ Código documentado

---

## 📦 ESTRUTURA DE ARQUIVOS RESULTANTE

```
lib/
├── ui/
│   ├── screens/
│   │   └── public_map_screen.dart                [ATUALIZADO]
│   └── components/
│       └── public_map/                           [NOVA PASTA]
│           ├── access_button.dart                [NOVO]
│           ├── location_button.dart              [NOVO]
│           ├── zoom_controls.dart                [NOVO - OPCIONAL]
│           ├── public_publication_pins.dart      [NOVO]
│           └── public_publication_preview.dart   [NOVO]
├── modules/
│   ├── dashboard/
│   │   └── controllers/
│   │       └── public_location_controller.dart   [NOVO]
│   └── public/                                   [NOVA PASTA]
│       ├── providers/
│       │   └── public_publications_provider.dart [NOVO]
│       └── domain/
│           └── public_map_state.dart             [NOVO]
├── core/
│   └── config/
│       └── map_config.dart                       [NOVO]
└── docs/
    ├── PLANO_MAPA_PUBLICO_V2.md                  [ESTE ARQUIVO]
    └── ADR_PUBLIC_MAP_TILES.md                   [NOVO - FASE 4]
```

---

## 🧪 TESTES E VALIDAÇÃO

### Checklist de Testes Manuais
```
FASE 1:
[ ] Botão "Acessar SoloForte" visível
[ ] Clique navega para /login
[ ] Layout responsivo (iPhone SE, iPad, Android tablets)

FASE 2:
[ ] Permissão de GPS solicitada
[ ] Ponto azul aparece na localização
[ ] Mapa centraliza no usuário
[ ] Botão de localização muda de estado (loading → active)

FASE 3:
[ ] Zoom por pinch funciona
[ ] Limites min/max respeitados
[ ] Zoom suave e responsivo

FASE 4:
[ ] Novo estilo de mapa carrega
[ ] Performance aceitável
[ ] Fallback funciona se API falhar

FASE 5:
[ ] Pins de publicações aparecem
[ ] Clustering funciona com 50+ pins
[ ] Tap abre preview sem ações de edição
[ ] Fotos carregam corretamente

FASE 6:
[ ] Animações fluidas
[ ] Tratamento de erros OK
[ ] Acessibilidade validada
[ ] Performance > 30 FPS
```

### Testes Automatizados (Opcional)
```dart
// test/ui/screens/public_map_screen_test.dart

testWidgets('AccessButton navega para login', (tester) async {
  // ... implementar
});

testWidgets('LocationButton solicita permissão GPS', (tester) async {
  // ... implementar
});
```

---

## 📊 ESTIMATIVAS E RISCOS

### Tempo Total Estimado
```
FASE 1:  30-45 min  ⚡
FASE 2:  45-60 min  🗺️
FASE 3:  30 min     🔍
FASE 4:  60-90 min  🎨  [MAIOR RISCO]
FASE 5:  60-75 min  📌
FASE 6:  45-60 min  ✨
----------------------------
TOTAL:   4h30 - 6h
```

### Riscos Identificados

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| **API de tiles indisponível** | Média | Alto | Fallback para OpenStreetMap |
| **Performance ruim com muitos pins** | Baixa | Médio | Usar clustering + limite de 100 pins |
| **Permissões de GPS negadas** | Alta | Baixo | Dialog explicativo + usar localização padrão (SP) |
| **Estilo de mapa não corresponde à imagem** | Média | Médio | Iterar com cliente em Fase 4 |
| **Conflito com arquitetura existente** | Baixa | Alto | Seguir `docs/arquitetura-navegacao.md` rigorosamente |

---

## 🎯 PRÓXIMOS PASSOS

1. **AGUARDAR APROVAÇÃO DO PLANO** ⏸️
2. Executar Fase 1 (Fundação)
3. Validar com cliente antes da Fase 4 (Tiles)
4. Executar fases sequencialmente
5. Code review após Fase 3 e Fase 6
6. Deploy em ambiente de staging
7. Testes com usuários beta

---

## 📝 NOTAS ARQUITETURAIS

### Conformidade com `arquitetura-navegacao.md`
- ✅ `/public-map` é **exceção controlada** (pré-login)
- ✅ **NÃO compartilha estado** com `/map` (privado)
- ✅ Navegação via `context.go()` (não `pop()`)
- ✅ Sem AppBar (princípio No AppBar)
- ✅ Não usa SmartButton (contexto pré-autenticação)

### Princípios SOLID Aplicados
- **Single Responsibility:** Cada componente tem uma função clara
- **Open/Closed:** Providers extensíveis para novos estilos de mapa
- **Liskov Substitution:** TileLayers intercambiáveis
- **Interface Segregation:** Controllers focados (location, publications)
- **Dependency Inversion:** Dependência de abstrações (providers Riverpod)

---

## 🔗 REFERÊNCIAS

- [Flutter Map 7.0 Documentation](https://docs.fleaflet.dev/)
- [Mapbox Styles Documentation](https://docs.mapbox.com/api/maps/styles/)
- [Geolocator Plugin](https://pub.dev/packages/geolocator)
- `docs/arquitetura-navegacao.md` (Contrato de Navegação)
- `PROJECT_RULES.md` (Princípios do Projeto)

---

**FIM DO PLANO - AGUARDANDO APROVAÇÃO PARA EXECUÇÃO** 🚀
