# Marketing — Regras Ouro / Prata / Bronze

**Status:** ATIVO  
**Bounded context:** `marketing/`  
**Data produto (TTL):** Jul/2026 — definido pelo produto  
**Código vs produto:** §1–2 = verdade do código hoje; §3–4 = regras de produto obrigatórias (TTL ainda **não** implementado no app)

**Fontes de código:** `marketing_case_marker.dart`, `plano_marketing.dart`, `marketing_case_visibility.dart`, `isolated_marker_layers.dart`, `public_map_screen.dart`, RLS `marketing_cases`  
**Autoridade de tamanho/zoom:** código (não ADR-011 legado 80/64/48)

---

## 1. Resumo executivo

| Dimensão | Ouro | Prata | Bronze |
|---|---|---|---|
| Tamanho do pin (código) | maior `120×100` | médio `100×84` | pequeno `84×70` |
| Alcance / zoom mínimo (código) | ≥ **10** | ≥ **12** | ≥ **14** |
| Tempo visível ao **público** (produto) | **6 meses** | **4 meses** | **2 meses** |
| Após expirar a janela pública | some do **público** | some do **público** | some do **público** |
| Dados apagados? | **NÃO** | **NÃO** | **NÃO** |
| Owner pode renovar? | **SIM** | **SIM** | **SIM** |
| Quem pode liberar / renovar | Produtor **e** consultor (autor / `user_id`) | idem | idem |

---

## 2. Tamanho e alcance (já no código)

Fonte: `lib/modules/marketing/presentation/widgets/marketing_case_marker.dart`

### 2.1 Tamanho

```
Ouro   → 120 × 100   (maior)
Prata  → 100 × 84    (médio)
Bronze →  84 × 70    (menor)
```

### 2.2 Alcance (zoom mínimo no mapa)

```
Ouro   → zoom ≥ 10   (visível mais cedo / de mais longe)
Prata  → zoom ≥ 12
Bronze → zoom ≥ 14   (precisa aproximar mais)
```

API: `MarketingCaseMarker.minZoomForTier` / `isVisibleAtZoom`.

---

## 3. Tempo de visibilidade pública (regra de produto)

### 3.1 Duração por tier

| Tier | Meses no público | Equivalente |
|---|---|---|
| **Ouro** | **6** meses | ~180 dias |
| **Prata** | **4** meses | ~120 dias |
| **Bronze** | **2** meses | ~60 dias |

Contagem: a partir da data de **liberação pública** (primeira publicação liberada ou última **renovação**).

### 3.2 O que acontece ao expirar

1. O pin **deixa de ficar visível ao público** (mapa anônimo / splash / leitura pública de terceiros sem vínculo).  
2. O registro **não é apagado** (proibido hard delete; soft delete só por ação explícita do owner).  
3. O autor continua vendo o próprio case (lista Relatórios / mapa próprio).  
4. Consultor vinculado / `client_id` autorizado: leitura compartilhada segue as regras ADR-041 / filtros existentes (não confundir com “público”).  
5. Owner pode **renovar** → nova janela de N meses conforme o tier atual.

### 3.3 Estado no código (gap)

| Item | Hoje |
|---|---|
| Campo `liberado_em` / `publico_ate` em `MarketingCase` | **Ausente** |
| Filtro de expiração nas layers / RLS | **Ausente** |
| UI “Renovar liberação” | **Ausente** |
| Tabela legada `marketing_pins.expira_em` | Existe, mas **não** é o fluxo `MarketingCase` |

Implementação deve introduzir persistência + filtros **sem apagar** linhas.

---

## 4. Liberação para o público (regra de produto)

### 4.1 Quem

- **Produtor** e **consultor** (autor do case, `user_id = auth.uid()`).

### 4.2 O que é “liberar”

Ação do owner que torna o pin elegível à leitura pública, pelo prazo do tier (§3.1).

- Liberar **não** apaga dados.  
- Expirar **não** apaga dados — só remove da superfície pública.  
- Renovar = owner redefine a âncora temporal (nova janela).

### 4.3 Relação com o enum `visibilidade` (código atual)

Hoje, sem flag separada:

| `visibilidade` | Leitura anônima (código atual) |
|---|---|
| `ouro` | SIM (RLS `ouro public read`) |
| `prata` / `bronze` | NÃO |

**Decisão de produto para implementação:**

- Manter Ouro/Prata/Bronze como **tamanho + zoom + prazo público**.  
- Liberação pública + TTL devem aplicar-se de forma coerente:  
  - **Opção A (preferida, mínima):** liberar público = case published + janela TTL ativa; Ouro continua sendo o único tier com leitura anônima no RLS atual **ou**  
  - **Opção B:** permitir liberação pública também para Prata/Bronze (exige ajuste RLS + filtro), com TTL 4/2 meses.

> Enquanto a Opção B não estiver aprovada em migration, o plano de execução usa **Opção A**: TTL 6/4/2 + liberação/renovação na UI; leitura anônima permanece alinhada a Ouro até ADR/RLS explícitos.

### 4.4 Relatórios vs mapa (produtor) — código atual

| Superfície | Ouro de terceiro (não expirado) |
|---|---|
| Mapa privado produtor | Visível |
| Relatórios produtor | Só próprios + vínculo |

---

## 5. Matriz de visibilidade (alvo após TTL)

Pré-requisitos comuns: `published`, `ativo`, não soft-deleted, zoom ≥ mínimo.

| Observador | Público ativo (TTL ok) | Público expirado | Próprio | Vinculado |
|---|---|---|---|---|
| Anônimo | Conforme liberação/tier (§4.3) | Não | — | — |
| Produtor (terceiro) | Conforme liberação pública ativa | Não | — | — |
| Owner | Sim* | Sim (não público) | Sim | — |
| Consultor (outros) | Conforme regras auth atuais + TTL público | Não no público | — | se vínculo |

\* subject a zoom/tamanho do tier.

---

## 6. Renovação (produto)

1. Só o **owner** (`user_id`).  
2. Disponível quando a janela pública expirou **ou** ainda está ativa (renovar antecipa = estende a partir de agora).  
3. Efeito: `publico_ate = now + meses(tier)` (ou equivalente).  
4. Não criar cópia do case; não apagar histórico.  
5. Mesmo fluxo para produtor e consultor.

---

## 7. Regras estáveis para agentes

1. **Nunca hard delete** por expiração de TTL.  
2. TTL: Ouro 6 / Prata 4 / Bronze 2 meses — âncora = liberação ou renovação.  
3. Tamanho/zoom: sempre `MarketingCaseMarker` (não ADR-011 legado).  
4. Soft delete / `ativo` / `published` continuam pré-requisitos.  
5. Sheets: `showSoloForteSheet` + `SoloForteSheetTokens`.  
6. Fronteiras: `marketing/` sem import cruzado proibido; ADR se mudar RLS/contrato.  
7. IPA só após validação 100% (`AGENTIPA.md` — próximo build **171**).

---

## 8. Checklist de aceitação (implementação + IPA)

### Documentação
- [x] TTL 6/4/2 meses documentado  
- [x] Soft-hide (sem apagar) + renovação documentados  

### Código (pendente — ver plano)
- [ ] Persistência da janela pública (`liberado_em` / `publico_ate` ou equivalente)  
- [ ] Filtro mapa público + mapa produtor (terceiros) respeita TTL  
- [ ] Owner vê case expirado; pode renovar  
- [ ] UI liberação clara (criação + pós-publicação) — produtor e consultor  
- [ ] Testes unitários TTL + renovação  
- [ ] `flutter analyze` + `./tool/arch_check.sh` Exit 0  

### Release
- [ ] `pubspec.yaml` → `1.34.0+171`  
- [ ] IPA 171 gerado e registrado em `AGENTIPA.md`

---

## 9. Referências

| Peça | Path |
|---|---|
| Tamanho / zoom | `lib/modules/marketing/presentation/widgets/marketing_case_marker.dart` |
| Enum | `lib/modules/marketing/domain/enums/plano_marketing.dart` |
| ACL produtor | `lib/modules/marketing/domain/marketing_case_visibility.dart` |
| Layer mapa | `lib/ui/components/map/widgets/isolated_marker_layers.dart` |
| Mapa público | `lib/ui/screens/public_map_screen.dart` |
| Criação | `lib/modules/marketing/presentation/screens/novo_case_sheet.dart` |
| Detalhe | `lib/modules/marketing/presentation/widgets/marketing_case_sheet.dart` |
| RLS | `supabase/migrations/20260228120000_marketing_cases.sql` |
| IPA | `AGENTIPA.md` (último validado: **170**; próximo: **171**) |
