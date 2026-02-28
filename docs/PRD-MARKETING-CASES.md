# PRD — Sistema de Cases de Marketing (Publicação)
# Versão: 1.0
# Data: 28/02/2026
# Status: APROVADO — base para ADR-011 revisado

---

## 1. VISÃO GERAL

O sistema de Cases de Marketing permite que vendedores/agrônomos publiquem
resultados técnicos de produtos agrícolas diretamente no mapa do SoloForte.

Um "Case" é um pin georreferenciado visível no mapa que contém provas
técnicas de desempenho de um produto: fotos, ROI, comparações, produtividade.

A hierarquia Bronze/Prata/Ouro define a visibilidade do pin no mapa.

---

## 2. FLUXO DO USUÁRIO

```
1. Usuário toca no ícone de marketing no mapa
2. Modo de seleção de localização ativado
3. Usuário toca em um ponto do mapa
4. Bottom sheet "Novo Case" abre
5. Usuário preenche os dados do case
6. Toca em "Publicar"
7. Pin aparece no mapa na localização escolhida
```

---

## 3. TIPOS DE CASE

### 3.1 Resultado
Prova de resultado final com uma foto principal.

**Campos específicos:**
- Foto principal (obrigatória, proporção 9:16)
- Quantidade Produzida (número)
- Economia gerada (opcional, texto — ex: "R$ 22.000")

### 3.2 Antes/Depois
Comparação visual com duas fotos lado a lado.

**Campos específicos:**
- Foto ANTES (obrigatória)
- Foto DEPOIS (obrigatória)
- Ganho de Produtividade (texto — ex: "+38%")
- Economia Gerada (texto — ex: "R$ 22.000")

### 3.3 Avaliação/Campo
Comparação técnica com avaliações dinâmicas.

**Campos específicos:**
- Nome do Talhão (texto)
- Tamanho em hectares (número)
- Avaliações dinâmicas (0 a N, ver seção 4)
- SEM seção de Produtividade

---

## 4. COMPONENTES DINÂMICOS (apenas Avaliação/Campo)

O usuário pode adicionar até N blocos de cada tipo via botão "+ Adicionar":

### 4.1 Bloco Avaliação
Comparação lado a lado (Produto A vs Produto B).
- Layout: 2 fotos (padrão) ou 1 foto
- Cada lado tem: label editável, foto, tipo de cultura (Soja/Milho/Trigo/Café), observações
- Pode colapsar/expandir
- Pode ser removido

### 4.2 Bloco ROI
Calculadora automática de retorno sobre investimento.
- Investimento (R$)
- Retorno (R$)
- ROI calculado automaticamente: ((retorno - investimento) / investimento) × 100
- Fundo verde (#34C759)
- Apenas 1 por case

### 4.3 Bloco Conclusão
Texto livre de conclusão técnica.
- Fundo azul (#0057FF)
- Apenas 1 por case

---

## 5. CAMPOS COMUNS (todos os tipos)

| Campo | Tipo | Obrigatório | Exemplo |
|---|---|---|---|
| Tipo | Enum (resultado/antes-depois/avaliacao) | SIM | "Resultado" |
| Visibilidade | Enum (bronze/prata/ouro) | SIM | "Prata" |
| Produtor/Fazenda | Texto | SIM | "Fazenda Santa Rita" |
| Produto Utilizado | Texto | SIM | "Soja Olimpo" |
| Localização (texto) | Texto | SIM | "Jataizinho - PR" |
| Localização (GPS) | lat/lng | SIM | capturado no toque do mapa |
| Produtividade Valor | Número | SIM (exceto Avaliação) | 80 |
| Produtividade Unidade | Enum (sc/ha, ton/ha, kg/ha) | SIM (exceto Avaliação) | "sc/ha" |
| Nome Vendedor | Texto | NÃO | "Carlos Silva" |
| Telefone Vendedor | Tel | NÃO | "(43) 99876-5432" |
| Descrição | Texto livre | NÃO | "Descreva o case..." |

---

## 6. HIERARQUIA DE VISIBILIDADE

| Plano | Tamanho do pin | Z-index | Visível sem login |
|---|---|---|---|
| Ouro | 80×80px | 3 | SIM |
| Prata | 64×64px | 2 | NÃO |
| Bronze | 48×48px | 1 | NÃO |

**Regra splash/login:** apenas pins Ouro aparecem antes do login.
**Regra mapa autenticado:** todos os planos visíveis.

---

## 7. MODELO DE DADOS COMPLETO

### Entidade Principal: `MarketingCase`

```
id                String (UUID)           obrigatório
tipo              CaseTipo (enum)         obrigatório
visibilidade      PlanoMarketing (enum)   obrigatório
lat               double                  obrigatório  ← toque no mapa
lng               double                  obrigatório  ← toque no mapa
localizacaoTexto  String                  obrigatório  ← "Jataizinho - PR"
produtorFazenda   String                  obrigatório
produtoUtilizado  String                  obrigatório
produtividadeValor double?                opcional (nulo em Avaliação)
produtividadeUnidade ProdutividadeUnidade? opcional
nomeVendedor      String?                 opcional
telefoneVendedor  String?                 opcional
descricao         String?                 opcional
fotoPrincipalUrl  String?                 Resultado: foto única
fotoAntesUrl      String?                 Antes/Depois: foto antes
fotoDepoisUrl     String?                 Antes/Depois: foto depois
ganhoProdutividade String?               Antes/Depois: "+38%"
economiaGerada    String?                 opcional
quantidadeProduzida double?              Resultado: qtd produzida
nomeTalhao        String?                 Avaliação: nome do talhão
tamanhoHa         double?                 Avaliação: tamanho em ha
avaliacoes        List<AvaliacaoBloco>    Avaliação: comparações dinâmicas
roi               RoiBloco?              Avaliação: bloco ROI
conclusao         String?                 Avaliação: texto conclusão
ativo             bool                    obrigatório, default true
criadoEm          DateTime               obrigatório
atualizadoEm      DateTime               obrigatório
syncStatus        String                  local_only / pending_sync / synced
deletadoEm        DateTime?              soft delete
```

### Entidade: `AvaliacaoBloco`

```
id                String (UUID)
caseId            String (FK → MarketingCase)
ordem             int
layout            AvaliacaoLayout (duas_fotos / uma_foto)
colapsado         bool
ladoA             AvaliacaoLado
ladoB             AvaliacaoLado
```

### Entidade: `AvaliacaoLado`

```
label             String          ex: "Produto A"
fotoUrl           String?
tipoCultura       String?         soja / milho / trigo / cafe
observacoes       String?
```

### Entidade: `RoiBloco`

```
investimento      double
retorno           double
roiCalculado      double          ((retorno - investimento) / investimento) × 100
```

### Enums

```dart
enum CaseTipo { resultado, antesDepois, avaliacao }

enum PlanoMarketing { ouro, prata, bronze }

enum ProdutividadeUnidade { scHa, tonHa, kgHa }

enum AvaliacaoLayout { duasFotos, umaFoto }
```

---

## 8. REGRAS DE NEGÓCIO

1. Tipo "Resultado" → foto principal obrigatória
2. Tipo "Antes/Depois" → foto antes E foto depois obrigatórias
3. Tipo "Avaliação" → sem seção de Produtividade
4. ROI: apenas 1 bloco por case
5. Conclusão: apenas 1 bloco por case
6. Avaliações: ilimitadas por case
7. Fotos: compressão máxima 1200px, qualidade 85%, limite 5MB por foto
8. Publicar: valida Produtor/Fazenda + Produto Utilizado obrigatórios
9. PIN ouro: visível antes do login
10. PIN prata/bronze: visível apenas após autenticação

---

## 9. ARQUITETURA — ONDE VIVE

```
lib/modules/marketing/
├── domain/
│   ├── entities/
│   │   ├── marketing_case.dart
│   │   ├── avaliacao_bloco.dart
│   │   ├── avaliacao_lado.dart
│   │   └── roi_bloco.dart
│   └── enums/
│       ├── case_tipo.dart
│       ├── plano_marketing.dart
│       ├── produtividade_unidade.dart
│       └── avaliacao_layout.dart
├── data/
│   ├── repositories/
│   │   ├── i_marketing_case_repository.dart
│   │   └── marketing_case_repository_impl.dart
│   └── services/
│       └── marketing_sync_service.dart
└── presentation/
    ├── providers/
    │   └── marketing_providers.dart
    ├── screens/
    │   └── novo_case_sheet.dart        ← o bottom sheet completo
    └── widgets/
        ├── marketing_case_marker.dart  ← pin no mapa
        ├── avaliacao_bloco_widget.dart ← bloco dinâmico
        ├── roi_bloco_widget.dart
        └── conclusao_bloco_widget.dart
```

---

## 10. SUPABASE — TABELAS

```sql
-- Tabela principal
CREATE TABLE marketing_cases (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo                  TEXT NOT NULL CHECK (tipo IN ('resultado','antes_depois','avaliacao')),
  visibilidade          TEXT NOT NULL CHECK (visibilidade IN ('ouro','prata','bronze')),
  lat                   NUMERIC(10,7) NOT NULL,
  lng                   NUMERIC(10,7) NOT NULL,
  localizacao_texto     TEXT NOT NULL,
  produtor_fazenda      TEXT NOT NULL,
  produto_utilizado     TEXT NOT NULL,
  produtividade_valor   NUMERIC,
  produtividade_unidade TEXT,
  nome_vendedor         TEXT,
  telefone_vendedor     TEXT,
  descricao             TEXT,
  foto_principal_url    TEXT,
  foto_antes_url        TEXT,
  foto_depois_url       TEXT,
  ganho_produtividade   TEXT,
  economia_gerada       TEXT,
  quantidade_produzida  NUMERIC,
  nome_talhao           TEXT,
  tamanho_ha            NUMERIC,
  roi_investimento      NUMERIC,
  roi_retorno           NUMERIC,
  roi_calculado         NUMERIC,
  conclusao             TEXT,
  ativo                 BOOLEAN NOT NULL DEFAULT true,
  criado_em             TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em         TIMESTAMPTZ NOT NULL DEFAULT now(),
  deletado_em           TIMESTAMPTZ,
  sync_status           TEXT NOT NULL DEFAULT 'local_only'
);

-- Avaliações dinâmicas (filhos)
CREATE TABLE marketing_avaliacoes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id         UUID NOT NULL REFERENCES marketing_cases(id) ON DELETE CASCADE,
  ordem           INT NOT NULL,
  layout          TEXT NOT NULL DEFAULT 'duas_fotos',
  colapsado       BOOLEAN NOT NULL DEFAULT false,
  lado_a_label    TEXT NOT NULL DEFAULT 'Produto A',
  lado_a_foto_url TEXT,
  lado_a_cultura  TEXT,
  lado_a_obs      TEXT,
  lado_b_label    TEXT NOT NULL DEFAULT 'Produto B',
  lado_b_foto_url TEXT,
  lado_b_cultura  TEXT,
  lado_b_obs      TEXT
);

-- RLS
ALTER TABLE marketing_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_avaliacoes ENABLE ROW LEVEL SECURITY;

-- Ouro: leitura pública sem autenticação
CREATE POLICY "ouro public read" ON marketing_cases
  FOR SELECT USING (
    visibilidade = 'ouro'
    AND ativo = true
    AND deletado_em IS NULL
  );

-- Prata e Bronze: leitura apenas autenticado
CREATE POLICY "prata bronze auth read" ON marketing_cases
  FOR SELECT TO authenticated USING (
    ativo = true
    AND deletado_em IS NULL
  );

-- Avaliações seguem o case pai
CREATE POLICY "avaliacoes public read" ON marketing_avaliacoes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM marketing_cases mc
      WHERE mc.id = case_id
      AND mc.ativo = true
      AND mc.deletado_em IS NULL
    )
  );
```

---

## 11. ORDEM DE EXECUÇÃO DOS PROMPTS

```
ADR-011 revisado  → aprovar este PRD como contrato
PASSO 1  → Supabase: criar tabelas + RLS + seed ouro de teste
PASSO 2  → Domínio: entidades + enums em marketing/domain/
PASSO 3  → Repositório: interface + impl Supabase + SQLite cache
PASSO 4  → Providers: marketingCasesProvider (keepAlive)
PASSO 5  → Widget: MarketingCaseMarker (pin no mapa por plano)
PASSO 6  → Bottom sheet: NovoCaseSheet (formulário completo do HTML)
PASSO 7  → Componentes dinâmicos: avaliacao, roi, conclusao widgets
PASSO 8  → Integração mapa: renderizar pins + abrir sheet ao tocar
PASSO 9  → Integração splash: pins ouro no fundo da tela de login
```

---

## 12. O QUE ESTÁ FORA DO ESCOPO DESTE PRD

- Painel administrativo para gerenciar cases (web)
- Sistema de pagamento dos planos
- Analytics de visualizações por pin
- Edição de case já publicado
- Moderação de conteúdo
