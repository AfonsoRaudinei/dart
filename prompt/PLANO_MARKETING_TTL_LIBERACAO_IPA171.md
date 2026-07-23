# Plano — Marketing TTL + Liberação + IPA 171

**Modo:** plano de execução (pós-revisão)  
**Revisor:** `agentrevisor.md` (somente leitura no código; este arquivo é a proposta)  
**Fonte de regras:** `docs/02_ARQUITETURA_ATIVA/MARKETING_REGRAS_VISIBILIDADE_OURO_PRATA_BRONZE.md`  
**Release:** `AGENTIPA.md` — último IPA **170** → gerar **171** só após 100%

---

## 0. Relatório revisor (AUDIT — marketing)

```
Modo: AUDIT
Lote: marketing/ (+ ui map layers + release IPA)
Profundidade: PADRÃO
```

### Achados

| ID | Severidade | Achado | Evidência |
|---|---|---|---|
| MKT-TTL-01 | P0 | TTL público 6/4/2 meses **não implementado** | `MarketingCase` sem `publico_ate` / filtro |
| MKT-TTL-02 | P0 | Expiração não deve apagar — só tirar do público; renovação owner | regra produto documentada; código ausente |
| MKT-LIB-01 | P1 | UI sem “liberar público” / renovar pós-publicação | `MarketingCaseSheet` read-only; seletor só nomes de metal |
| MKT-DOC-01 | OK | Tamanho + zoom confirmados no código | `marketing_case_marker.dart` |
| MKT-IPA-01 | Gate | IPA 171 só após green | `pubspec 1.34.0+170`, `AGENTIPA.md` |

### Premissas travadas

1. Ouro **6 meses**, Prata **4**, Bronze **2** no público.  
2. Expirar = **ocultar do público**, nunca hard delete.  
3. Owner (produtor ou consultor) pode **renovar**.  
4. Tamanho/zoom já corretos — não mexer em `MarketingCaseMarker` sem necessidade.  
5. Liberação pública anônima permanece alinhada a **Ouro** no RLS atual (Opção A do doc), salvo ADR+migration para Prata/Bronze públicos.

---

## 1. Etapas de implementação (ordem anti-erro)

### Etapa A — Domínio + persistência TTL (alvo 35%)

**Objetivo:** modelar janela pública sem apagar dados.

**Arquivos típicos:**
- `lib/modules/marketing/domain/entities/marketing_case.dart`
- `lib/modules/marketing/domain/enums/plano_marketing.dart` (helper `publicMonths`)
- `lib/modules/marketing/data/repositories/marketing_case_repository_impl.dart`
- Migration Supabase: `publico_ate TIMESTAMPTZ` (e opcional `liberado_em`)
- Cache SQLite JSON já embute campos novos via `toJson`/`fromJson`

**Regras:**
- Ao publicar/liberar/renovar: `publico_ate = now + months(tier)`
- Soft-hide: filtro `now <= publico_ate` nas superfícies **públicas**
- Owner continua lendo case com `publico_ate` passado

**Checklist A**
- [ ] Campos no modelo + JSON  
- [ ] Migration + RLS select público considera `publico_ate` (Ouro)  
- [ ] Testes de cálculo 6/4/2  
- [ ] `arch_check` Exit 0  

### Etapa B — Filtros de mapa / público (alvo 60%)

**Objetivo:** expirado some do público; próprio/vínculo intactos.

**Arquivos:**
- `lib/modules/marketing/domain/marketing_case_visibility.dart`
- `lib/ui/components/map/widgets/isolated_marker_layers.dart`
- `lib/ui/screens/public_map_screen.dart`
- `lib/modules/marketing/presentation/widgets/ouro_map_background.dart`

**Checklist B**
- [ ] Mapa anônimo: só liberados **e** dentro do TTL  
- [ ] Produtor terceiros: só público ativo (Ouro + TTL)  
- [ ] Owner vê o próprio pin mesmo expirado  
- [ ] Testes de filtro  

### Etapa C — UI liberação + renovação (alvo 85%)

**Objetivo:** produtor e consultor entendem e controlam liberação.

**Arquivos:**
- `case_selectors_widget.dart` — copy (prazo + tamanho/alcance)  
- `novo_case_sheet.dart` — setar `publico_ate` na publicação  
- `marketing_case_sheet.dart` — owner: status TTL + botão Renovar / alterar tier  

**Checklist C**
- [ ] Copy com 6/4/2 meses  
- [ ] Renovar só owner  
- [ ] Sem alterar `smart_button.dart` / tema  
- [ ] Testes widget/smoke  

### Etapa D — Validação 100% (alvo 95%)

```bash
flutter analyze lib/modules/marketing/ lib/ui/components/map/widgets/isolated_marker_layers.dart lib/ui/screens/public_map_screen.dart
flutter test test/modules/marketing/ test/core/access/producer_content_visibility_test.dart
./tool/arch_check.sh
```

**Checklist D**
- [ ] Analyze limpo  
- [ ] Testes verdes  
- [ ] `arch_check` Exit 0  
- [ ] Checklist §8 do MD de regras 100%  

### Etapa E — IPA 171 (alvo 100%) — só após D

Conforme `AGENTIPA.md`:

1. `pubspec.yaml`: `version: 1.34.0+171`  
2. Gerar IPA (`flutter build ipa` / fluxo oficial do repo)  
3. Validar `CFBundleVersion=171` e `SUPABASE_URL` no binário (padrão dos IPAs 168–170)  
4. Atualizar histórico em `AGENTIPA.md` com IPA 171  
5. **Nunca** reutilizar 170  

**Checklist E**
- [ ] Build number 171 > 170  
- [ ] IPA em `build/ios/ipa/`  
- [ ] `AGENTIPA.md` atualizado  

---

## 2. Fora de escopo

- Hard delete por TTL  
- Unificar `marketing_pins` legado  
- Alterar Design System / `smart_button.dart`  
- IPA antes da Etapa D green  

---

## 3. Progresso

| Fase | % | Status |
|---|---|---|
| Doc TTL 6/4/2 + soft-hide + renovar | 15% | **Feito** (MD regras) |
| Etapa A persistência | 35% | Pendente |
| Etapa B filtros | 60% | Pendente |
| Etapa C UI | 85% | Pendente |
| Etapa D validação | 95% | Pendente |
| Etapa E IPA 171 | 100% | Pendente |

**Progresso atual: ~15%** (documentação). Código TTL/liberação/IPA ainda não iniciados.
