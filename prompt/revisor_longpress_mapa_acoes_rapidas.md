# PROMPT — REVISOR: Long Press no Mapa → Ações Rápidas

**Agente:** Engenheiro Sênior Flutter/Dart — Revisor Independente  
**Feature:** `feat_longpress_mapa_acoes_rapidas.md`  
**Data:** Ago/2026  

---

## Papel

Revisão pós-implementação. Leitura e verificação apenas. Zero execução de correção sem aprovação.

Regra: item só conta 100% sem ressalva.

## Resultado da revisão (Ago/2026)

| Rodada | % | Nota |
|---|---|---|
| 1ª | 99% | Item 2.4 parcial — `!mapReady` retornava `true` |
| 2ª (pós-fix) | **100%** | L336 `return false` — gesto ignorado até mapa pronto |

**Recomendação final:** QA físico liberado. Merge/`cherry-pick` em `main` bloqueado até os 10 cenários.

## Checklist (100 pts)

1. Remoção do `+` (15)  
2. Long press + hit-test + guard sheet (25)  
3. AbsorbPointer local (10)  
4. Hint progressivo + prefs (20)  
5. PreferencesService existente (10)  
6. arch_check / analyze / integridade (15)  
7. Testes de regressão da feature (5)  

## Dívida registrada (não bloqueia merge desta feature)

- 4 falhas pré-existentes em `test/ui/components/map/` (occurrence host / isolated markers) — fora do escopo deste prompt  
