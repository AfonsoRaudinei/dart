# PROMPT 03 — ADR-027: VFX Pendentes (VFX-01, 02, 03, 05, 06)

**Especialização do agente:** Engenheiro Sênior Flutter/Dart — UI/UX + Design Tokens  
**Tipo:** FEATURE — Passes de polish visual em bottom sheets existentes  
**Módulo:** `map/` + módulos com bottom sheets  
**Rota afetada:** `/map` (sheets abertos sobre o mapa)

---

## CONTEXTO

ADR-027 (Bottom Sheets) definiu um conjunto de passes VFX para uniformizar visual e comportamento de todos os bottom sheets do app. **Fase 1 e VFX-07 a 11 + DRAWING já estão commitados.** Restam: VFX-01, VFX-02, VFX-03, VFX-05, VFX-06.

**Design Tokens estabelecidos (não alterar):**
```
Sheet background:     0xFF1C1C1E
Input background:     0xFF2C2C2E
Amber accent:         0xFFF59E0B
Hint text:            0xFF8E8E93
Divider:              0xFF3A3A3C
Coord chip bg:        0xFF1A2E1A
Coord chip text:      0xFF4ADE80
```

---

## PASSO 0 — LOCALIZAÇÃO OBRIGATÓRIA

```bash
# Identificar todos os bottom sheets do app
find lib/ -name "*sheet*.dart" | sort
find lib/ -name "*bottom_sheet*.dart" | sort

# Verificar quais VFX já foram aplicados (buscar pelo padrão de cor correto)
grep -rln "0xFF1C1C1E" lib/ | sort
grep -rln "0xFF2C2C2E" lib/ | sort
```

Reporte quais sheets **ainda não** têm `0xFF1C1C1E` como background — esses são os candidatos às VFX pendentes.

---

## PASSO 1 — MAPEAMENTO DAS VFX PENDENTES

Para cada VFX, o agente deve identificar o arquivo alvo e o trecho exato antes de executar:

### VFX-01 — Handle visual padronizado
- Todos os sheets devem ter o pill/handle no topo: `Container(width: 36, height: 4, decoration: BoxDecoration(color: Color(0xFF3A3A3C), borderRadius: BorderRadius.circular(2)))`
- Verificar quais sheets **não** têm esse handle ainda

### VFX-02 — Background do sheet
- `backgroundColor: const Color(0xFF1C1C1E)` no `showModalBottomSheet` ou no widget raiz do sheet
- Verificar quais sheets ainda usam cor padrão ou `Theme.of(context).scaffoldBackgroundColor`

### VFX-03 — Inputs com background correto
- Todos os `TextField` / `TextFormField` nos sheets devem ter `fillColor: const Color(0xFF2C2C2E)` e `filled: true`
- Verificar quais sheets ainda têm inputs sem fill ou com cor diferente

### VFX-05 — Tipografia de seção padronizada
- Headers de seção: `Text('SEÇÃO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: Color(0xFF8E8E93)))`
- Verificar quais sheets têm headers de seção com estilo diferente

### VFX-06 — Botão primário padronizado
- Botão de ação principal: border radius 12, cor amber `0xFFF59E0B`, texto preto, altura mínima 52px
- Verificar quais sheets têm botão primário fora desse padrão

---

## PASSO 2 — RELATÓRIO PRÉ-EXECUÇÃO (obrigatório antes de qualquer edit)

Produzir tabela:

| Sheet | VFX-01 | VFX-02 | VFX-03 | VFX-05 | VFX-06 |
|---|---|---|---|---|---|
| nome_do_sheet.dart | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ |

**Aguardar confirmação antes de executar.**

---

## PASSO 3 — EXECUÇÃO

Ordem: VFX por VFX, não sheet por sheet.  
Aplicar VFX-01 em todos os sheets pendentes → validar → VFX-02 → validar → etc.

**Gate por VFX:** `flutter analyze lib/` → 0 novos erros antes de prosseguir.

---

## PASSO 4 — RESTRIÇÕES ABSOLUTAS

❌ Não alterar lógica de negócio em nenhum sheet  
❌ Não alterar contratos de construtor dos sheets  
❌ Não criar sheets novos  
❌ Não alterar providers  
❌ Não tocar em `NovoCaseSheet` (será tratado pelo PROMPT 01)  
❌ Não tocar em sheets de drawing (já concluídos)  
✅ Apenas alterações visuais nos arquivos identificados no PASSO 1  

---

## PASSO 5 — VALIDAÇÃO FINAL

```bash
flutter analyze lib/
bash tool/arch_check.sh
```

Reproduzir no device/simulador e confirmar visualmente:
- Handle visível em todos os sheets
- Background escuro uniforme
- Inputs com fundo `0xFF2C2C2E`
- Headers de seção em estilo correto
- Botão primário com border radius e cor amber

**Responder:**

| VFX | Aplicado | Sheets afetados |
|---|---|---|
| VFX-01 | SIM/NÃO | lista |
| VFX-02 | SIM/NÃO | lista |
| VFX-03 | SIM/NÃO | lista |
| VFX-05 | SIM/NÃO | lista |
| VFX-06 | SIM/NÃO | lista |

---

## ENCERRAMENTO

ADR-027 VFX pendentes concluídos.  
Nenhum contrato, provider ou rota alterado.  
Design tokens do sistema aplicados uniformemente.
