# ADR-011 — Bounded Context: Marketing Pins
# Status: APROVADO — base para execução
# Data: 28/02/2026
# Módulos afetados: marketing/ (NOVO), map/, auth/splash

---

## CONTEXTO

Pins de marketing de produtos agrícolas devem aparecer no mapa e na tela
de splash/login, visíveis para todos os usuários sem autenticação.
Hierarquia visual: ouro (maior) > prata (médio) > bronze (menor).
Toque em pin → bottom sheet com detalhes do produto.

Diagnóstico confirmou: zero código existente. Construção do zero.

---

## DECISÃO

### 1. Novo bounded context: `marketing/`

```
lib/modules/marketing/
├── domain/
│   ├── models/
│   │   └── marketing_pin.dart          ← entidade principal
│   └── enums/
│       └── plano_marketing.dart        ← ouro | prata | bronze
├── data/
│   ├── repositories/
│   │   ├── i_marketing_pin_repository.dart
│   │   └── marketing_pin_repository_impl.dart  ← lê do Supabase (sem auth)
│   └── services/
│       └── marketing_pin_sync_service.dart     ← cache local SQLite
└── presentation/
    ├── providers/
    │   └── marketing_pin_providers.dart
    └── widgets/
        ├── marketing_pin_marker.dart    ← widget do pin no mapa
        └── marketing_pin_sheet.dart    ← bottom sheet de detalhes
```

### 2. Tabela Supabase: `marketing_pins`

```sql
CREATE TABLE marketing_pins (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_produto  TEXT NOT NULL,
  imagem_url    TEXT NOT NULL,
  roi_percent   NUMERIC(5,2) NOT NULL,
  plano         TEXT NOT NULL CHECK (plano IN ('ouro', 'prata', 'bronze')),
  lat           NUMERIC(10,7) NOT NULL,
  lng           NUMERIC(10,7) NOT NULL,
  ativo         BOOLEAN NOT NULL DEFAULT true,
  criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
  expira_em     TIMESTAMPTZ
);

-- RLS: leitura pública sem autenticação
ALTER TABLE marketing_pins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public read" ON marketing_pins
  FOR SELECT USING (ativo = true AND (expira_em IS NULL OR expira_em > now()));
```

### 3. Modelo Dart: `MarketingPin`

```
Campos obrigatórios:
  id            String (UUID)
  nomeProduto   String
  imagemUrl     String
  roiPercent    double
  plano         PlanoMarketing (enum: ouro | prata | bronze)
  lat           double
  lng           double
  ativo         bool
  criadoEm     DateTime

Campos opcionais:
  expiraEm     DateTime?
```

### 4. Hierarquia visual

```
PlanoMarketing.ouro   → tamanho 80x80, zIndex 3
PlanoMarketing.prata  → tamanho 64x64, zIndex 2
PlanoMarketing.bronze → tamanho 48x48, zIndex 1
```

Imagem do produto: circular, borda colorida (ouro=#FFB800, prata=#C0C0C0, bronze=#CD7F32).
Nome do produto: texto abaixo do pin.
ROI: badge azul (#1A56DB) sobreposto no canto inferior direito.

### 5. Onde renderizar

**Mapa principal** (`/map`):
- Provider assiste `marketingPinsProvider` (keepAlive: true)
- Renderiza sobre as demais camadas do mapa
- Toque → `showModalBottomSheet` com `MarketingPinSheet`

**Splash/Login**:
- Mesmo provider — já está em memória (keepAlive)
- Mapa de fundo na tela de login exibe os pins ouro apenas
- Pins prata e bronze não aparecem no splash (só no mapa autenticado)

### 6. Acesso sem autenticação

O `MarketingPinRepositoryImpl` usa cliente Supabase anônimo:
```dart
Supabase.instance.client  // sem .auth — política RLS permite leitura pública
```

Cache local em SQLite para offline (tabela `marketing_pins_cache`).
TTL: 1 hora — após isso, refetch do Supabase.

### 7. Fronteiras arquiteturais

```
marketing/ → NÃO depende de: consultoria/, operacao/, agenda/, drawing/
map/       → PODE depender de marketing/ (lê providers)
auth/      → PODE depender de marketing/ (exibe pins no splash)
core/      → NÃO conhece marketing/
```

`arch_check.sh` deve ser atualizado para validar:
- `marketing/` não importa módulos de domínio proibidos

---

## EXECUÇÃO — ORDEM DOS PROMPTS

```
PASSO 1 → Supabase: criar tabela + RLS + seed de dados de teste
PASSO 2 → Domínio: MarketingPin model + PlanoMarketing enum
PASSO 3 → Repositório: IMarketingPinRepository + impl Supabase + cache SQLite
PASSO 4 → Providers: marketingPinsProvider (keepAlive)
PASSO 5 → Widgets: MarketingPinMarker + MarketingPinSheet
PASSO 6 → Integração mapa: renderizar pins sobre o mapa em /map
PASSO 7 → Integração splash: exibir pins ouro no fundo da tela de login
```

---

## VALIDAÇÃO FINAL DO ADR

- [ ] Novo bounded context `marketing/` criado com fronteiras claras
- [ ] Tabela Supabase com RLS público
- [ ] Leitura sem autenticação funciona
- [ ] Hierarquia visual ouro > prata > bronze respeitada
- [ ] Pins ouro visíveis no splash antes do login
- [ ] Todos os pins visíveis no mapa após login
- [ ] `arch_check.sh` atualizado e passando
- [ ] `flutter analyze` → 0 erros
