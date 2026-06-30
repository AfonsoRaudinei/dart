# PROMPT 02 — DT-028: Migração `showRadarProvider` → `MapContext.clima`

**Especialização do agente:** Especialista em Riverpod + Arquitetura Map-First Flutter  
**Tipo:** REFATORAÇÃO INTERNA — Eliminação de dívida técnica, zero feature nova  
**Módulo:** `map/`  
**Rota afetada:** `/map` (alteração interna de estado — sem mudança de comportamento visual)

---

## CONTEXTO

`showRadarProvider` é um `StateProvider<bool>` avulso que controla a visibilidade do radar no mapa. O padrão arquitetural correto para contextos do mapa é o enum `MapContext` (ex: `MapContext.clima`, `MapContext.ndvi`, `MapContext.ocorrencias`). Manter `showRadarProvider` separado cria inconsistência no modelo de estado do mapa.

**DT-028 registrado:** migrar `showRadarProvider` → `MapContext.clima` via `armedModeProvider` ou provider de contexto equivalente.

---

## PASSO 0 — LOCALIZAÇÃO OBRIGATÓRIA

```bash
grep -rn "showRadarProvider" lib/ | sort
grep -rn "MapContext" lib/ | sort
grep -rn "armedModeProvider\|ArmedMode" lib/ | sort
find lib/ -name "map_context.dart" -o -name "armed_mode.dart" | sort
find lib/ -name "radar_layer*" | sort
```

Reporte todos os outputs. Quantos arquivos usam `showRadarProvider`? Liste todos.

---

## PASSO 1 — LEITURA (sem tocar nada)

### 1.1 `showRadarProvider`
- Onde está declarado? Tipo exato?
- Quem faz `ref.watch(showRadarProvider)`? Listar todos.
- Quem faz `ref.read(showRadarProvider.notifier).state = ...`? Listar todos.

### 1.2 `MapContext` enum
- Valores atuais do enum (listar todos)
- `MapContext.clima` já existe? Se não existe → deve ser criado como novo valor
- Como o `armedModeProvider` / contexto ativo é lido nos widgets?

### 1.3 `RadarLayerWidget`
- Qual prop/provider usa para decidir se renderiza?
- Está acoplado diretamente a `showRadarProvider`?

---

## PASSO 2 — PLANEJAMENTO

O agente deve propor o plano antes de executar:

**Opção A — `MapContext.clima` como contexto exclusivo:**
- `showRadarProvider` removido
- Radar ativo quando `ref.watch(activeMapContextProvider) == MapContext.clima`
- Botão de radar alterna `activeMapContextProvider` para `.clima` / `null`

**Opção B — `MapContext.clima` coexistindo com ArmedMode:**
- `showRadarProvider` removido
- `armedModeProvider` ganha valor `ArmedMode.clima` (se enum correto)
- Radar ativo quando `armedModeProvider == ArmedMode.clima`

**O agente deve:**
1. Ler o código real de `ArmedMode` e `MapContext`
2. Escolher a opção mais consistente com o padrão já em uso
3. **Reportar a escolha e aguardar confirmação antes de executar**

---

## PASSO 3 — EXECUÇÃO (somente após aprovação do plano)

Ordem de execução:

1. Adicionar `MapContext.clima` ao enum (se não existir) — 1 arquivo
2. Atualizar `RadarLayerWidget` para usar novo provider — 1 arquivo  
3. Atualizar botão de toggle do radar — 1 arquivo
4. Remover declaração de `showRadarProvider` — 1 arquivo
5. Remover todos os usos restantes (grep confirmou quais) — N arquivos

**Gate por arquivo:** `flutter analyze lib/` após cada arquivo tocado.  
**Não remover `showRadarProvider` antes de todos os consumidores estarem migrados.**

---

## PASSO 4 — RESTRIÇÕES ABSOLUTAS

❌ Não alterar comportamento visual do radar (deve continuar funcionando igual)  
❌ Não criar novo provider — usar infraestrutura existente  
❌ Não alterar `RadarLayerWidget` além do provider que assiste  
❌ Não tocar em módulos fora de `map/`  
❌ Não alterar rotas  

---

## PASSO 5 — VALIDAÇÃO FINAL

```bash
grep -rn "showRadarProvider" lib/
flutter analyze lib/
bash tool/arch_check.sh
```

Esperado:
- `showRadarProvider`: zero ocorrências
- `flutter analyze`: 0 novos erros
- `arch_check.sh`: Exit 0

**Responder:**

| Verificação | Resultado |
|---|---|
| showRadarProvider eliminado? | SIM |
| Radar ainda funciona visualmente? | SIM |
| Outros módulos alterados? | NÃO |
| arch_check.sh Exit 0? | SIM |

---

## ENCERRAMENTO

DT-028 encerrado. `showRadarProvider` eliminado.  
`MapContext.clima` é o único ponto de verdade para ativação do radar.
