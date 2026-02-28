# ADR-009 — Relatório Técnico e Publicação Técnica como sub-domínios de consultoria

**Data:** 22/02/2026
**Branch:** `release/v1.1`
**Status:** APROVADO
**Autor:** Engenheiro Sênior Flutter
**Módulo afetado:** `consultoria`
**Tipo de alteração:** ESTRUTURAL — novos sub-domínios e interfaces
**Altera fronteira entre módulos?** NÃO — Opção A confirmada
**Altera contrato de interface?** SIM — `IRelatorioRepository`, `IPublicacaoRepository`
**arch_check.sh:** APROVADO — sem violação de fronteira

---

## 1. Contexto

O SoloForte possui um módulo `consultoria` responsável por conteúdo técnico e ocorrências agronômicas. Ao escalar o produto, dois novos fluxos se tornaram necessários:

- **Relatório Técnico de Visita:** documento estruturado gerado automaticamente ao finalizar uma `VisitSession`, composto por dados de campo reais (ocorrências, talhões, monitoramentos, fotos).
- **Publicação Técnica:** conteúdo técnico aberto criado pelo agrônomo sobre temas agronômicos (pragas, doenças, recomendações), visível publicamente na plataforma e referenciável por relatórios.

A decisão central desta ADR é: onde esses dois domínios vivem e como a dependência de dados de `VisitSession` (que vive em `operacao`) é resolvida sem criar acoplamento estrutural proibido.

---

## 2. Decisão

### 2.1 Localização arquitetural

Ambos os sub-domínios são criados dentro de `consultoria`, sem nova fronteira de módulo:

| Sub-domínio | Bounded Context | Justificativa |
|---|---|---|
| `relatorios/` | `consultoria` | Produto final do trabalho técnico do agrônomo — mesmo domínio |
| `publicacoes/` | `consultoria` | Conteúdo técnico produzido pelo agrônomo — mesmo domínio |

Criar um bounded context `publicacao` separado foi avaliado e **rejeitado**. A justificativa: não há responsabilidades que extrapolem `consultoria` no estágio atual do produto. A criação seria custo arquitetural sem benefício imediato.

### 2.2 Resolução da dependência de VisitSession (Opção A)

`GenerateRelatoryUseCase` precisa de dados de `VisitSession`, que vive em `operacao`. Duas opções foram avaliadas:

| Opção | Descrição | Decisão |
|---|---|---|
| A | `consultoria` recebe `VisitSessionSnapshot` (DTO próprio). Quem resolve a dependência é `map/` ou a camada de apresentação. | ✅ ADOTADA |
| B | Declarar `consultoria → operacao` como dependência permitida via ADR e atualizar CI. | ❌ REJEITADA |

Opção A foi adotada porque mantém `consultoria` isolado. `VisitSessionSnapshot` é um DTO que vive em `consultoria/relatorios/models/` e define apenas o que o relatório precisa saber sobre uma visita — sem importar nenhuma classe de `operacao`.

### 2.3 Estados do Relatório Técnico

| Estado | Descrição | Visível ao produtor? |
|---|---|---|
| `pendente_revisao` | Gerado automaticamente ao finalizar `VisitSession`. Editável pelo agrônomo. | NÃO |
| `publicado` | Agrônomo aprovou. Produtor e agrônomo têm acesso. | SIM |
| `arquivado` | Relatório encerrado. Mantido para histórico. | SIM (somente leitura) |

---

## 3. Contratos de Dados

### 3.1 RelatórioTécnico

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | SIM | Identificador único (v4) |
| `visit_session_id` | UUID | SIM | FK para VisitSession (referência, não importação) |
| `client_id` | UUID | SIM | ID do cliente |
| `agronomist_id` | UUID | SIM | ID do agrônomo responsável |
| `farm_name` | String | SIM | Nome da fazenda |
| `period_start` | DateTime | SIM | Início do período da visita (UTC) |
| `period_end` | DateTime | SIM | Fim do período da visita (UTC) |
| `status` | Enum | SIM | `pendente_revisao` \| `publicado` \| `arquivado` |
| `sync_status` | Enum | SIM | `local_only` \| `pending_sync` \| `synced` \| `sync_error` \| `deleted_local` |
| `created_at` | DateTime | SIM | Timestamp de criação (UTC) |
| `updated_at` | DateTime | SIM | Timestamp de atualização (UTC) |
| `deleted_at` | DateTime? | NÃO | Soft delete (nullable) |
| `title` | String? | NÃO | Título editável pelo agrônomo |
| `custom_notes` | String? | NÃO | Seção livre editável |
| `publicacoes_refs` | List\<UUID\> | NÃO | Publicações técnicas incluídas como referência |
| `ocorrencias` | List\<OcorrenciaSnapshot\> | NÃO | Dados de ocorrências da sessão (snapshot imutável) |
| `talhoes` | List\<TalhaoVisitado\> | NÃO | Talhões visitados na sessão |
| `fotos` | List\<String\> | NÃO | Paths locais de fotos registradas |
| `monitoramentos` | List\<MonitoramentoSnapshot\> | NÃO | Dados de monitoramento da sessão |

### 3.2 PublicaçãoTécnica

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | SIM | Identificador único (v4) |
| `author_id` | UUID | SIM | ID do agrônomo autor |
| `tema` | Enum | SIM | `praga` \| `doenca` \| `solo` \| `fenologia` \| `recomendacao` \| `outro` |
| `titulo` | String | SIM | Título da publicação |
| `conteudo` | String | SIM | Conteúdo técnico |
| `visibility` | Enum | SIM | `publica` \| `restrita` |
| `sync_status` | Enum | SIM | Padrão offline-first |
| `created_at` | DateTime | SIM | Timestamp de criação (UTC) |
| `updated_at` | DateTime | SIM | Timestamp de atualização (UTC) |
| `deleted_at` | DateTime? | NÃO | Soft delete |
| `foto_paths` | List\<String\>? | NÃO | Paths locais de fotos |
| `talhao_ref` | UUID? | NÃO | Referência opcional a talhão |
| `fazenda_ref` | UUID? | NÃO | Referência opcional a fazenda |
| `safra` | String? | NÃO | Safra de referência |

---

## 4. Estrutura de Arquivos

```
lib/modules/consultoria/
  ├── relatorios/
  │     ├── models/
  │     │     ├── relatorio_tecnico.dart
  │     │     ├── relatorio_status.dart          (enum)
  │     │     └── visit_session_snapshot.dart    (DTO — NÃO importa operacao)
  │     ├── repositories/
  │     │     └── i_relatorio_repository.dart
  │     └── use_cases/
  │           ├── generate_relatorio_use_case.dart
  │           └── publish_relatorio_use_case.dart
  └── publicacoes/
        ├── models/
        │     ├── publicacao_tecnica.dart
        │     └── publicacao_tema.dart            (enum)
        ├── repositories/
        │     └── i_publicacao_repository.dart
        └── use_cases/
              └── create_publicacao_use_case.dart
```

---

## 5. Consequências

### O que muda

- 2 novos sub-domínios criados dentro de `consultoria`: `relatorios/` e `publicacoes/`
- 2 novas interfaces formais: `IRelatorioRepository` e `IPublicacaoRepository`
- 1 novo DTO: `VisitSessionSnapshot` (em `consultoria/relatorios/models/`)
- `bounded_contexts.md` atualizado para refletir os sub-domínios
- `ARCH_BASELINE_v1.1_SCORE_90.md` atualizado: Seção 4 e Seção 2 (métricas)

### O que não muda

- Fronteiras entre módulos — nenhuma nova dependência cruzada
- `consultoria` não importa `operacao` — Opção A garante isolamento
- `arch_check.sh` — nenhuma regra nova necessária
- Todos os contratos existentes de `drawing`, `agenda` e `operacao`

### Riscos

| Risco | Severidade | Mitigação |
|---|---|---|
| `VisitSessionSnapshot` ficar desatualizado em relação a `VisitSession` | Média | Testes de snapshot garantem consistência dos campos mapeados |
| `relatorios/` crescer além de 900 linhas por arquivo | Baixa | `arch_check.sh` REGRA 3 monitora automaticamente |
| `publicacoes/` ser confundida com módulo de marketing | Baixa | Nomenclatura técnica explícita + documentação de bounded context |

---

## 6. Checklist de Conformidade

- [x] Lido: `00_INDEX_OFICIAL.md`
- [x] Lido: `ARCH_BASELINE_v1.1_SCORE_90.md`
- [x] Lido: `bounded_contexts.md`
- [x] Módulo afetado declarado: `consultoria`
- [x] Altera contrato de interface: SIM — 2 novas interfaces
- [x] Altera fronteira entre módulos: NÃO — Opção A adotada
- [x] `arch_check.sh` planejado: REGRAS 1, 2, 3 respeitadas
- [x] ADR criado: ADR-009 (este documento)
- [x] `bounded_contexts.md`: sub-domínios de `consultoria` atualizados
- [x] `ARCH_BASELINE_v1.1_SCORE_90.md`: Seções 2 e 4 atualizadas
- [x] `00_INDEX_OFICIAL.md`: ADR-009 adicionado

---

## Referências

- [ADR-008](ADR-008-RIVERPOD-NORMALIZATION.md) — Normalização Riverpod
- `02_ARQUITETURA_ATIVA/bounded_contexts.md` — Fronteiras de módulo
- `01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md` — Autoridade máxima
- `03_ENFORCEMENT/enforcement-rules.md` — Regras de CI

---

*ADR-009 — SoloForte App v1.1 — 22/02/2026 — Branch: `release/v1.1`*
