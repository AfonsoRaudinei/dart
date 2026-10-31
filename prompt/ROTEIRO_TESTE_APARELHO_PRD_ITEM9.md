# PRD Item 9 — Roteiro de teste em aparelho (gate loja)

**Obrigatório antes de TestFlight / Play internal.** Marcar data, build (IPA/ APK), dispositivo e iOS/Android.

**Base:** `origin/main` @ commit anotado abaixo após sync.

---

## Pré-requisitos

- [ ] Build debug ou release assinado a partir da `main` mergeada (não branch WIP)
- [ ] Conta de teste com: talhão **MultiPolygon**, talhão com **furo**, ≥1 **case marketing publicado**
- [ ] Modo avião disponível para teste offline

---

## A — Visita ativa + geometria (lotes 8–9)

| # | Cenário | Passos | OK? | Notas |
|---|---------|--------|-----|-------|
| A1 | MultiPolygon no mapa | Iniciar visita · talhão com 2+ partes · zoom/pan | ⬜ | Contorno e área coerentes |
| A2 | Furo no talhão | Mesma visita ou outro talhão com anel interno · render no mapa | ⬜ | Interior do furo não preenchido como talhão |
| A3 | Hit / seleção | Toque dentro de cada parte e fora do furo | ⬜ | Seleciona talhão certo |
| A4 | Geofence (se visita ativa) | Entrar/sair do perímetro | ⬜ | Comportamento esperado visitas |

---

## B — Offline-first

| # | Cenário | Passos | OK? | Notas |
|---|---------|--------|-----|-------|
| B1 | Cold start offline | Modo avião · matar app · abrir | ⬜ | Mapa/consultoria local; sem crash boot |
| B2 | Visita offline | Com visita já iniciada · avião · navegar mapa | ⬜ | |
| B3 | Sync ao voltar rede | Desligar avião · aguardar sync tier | ⬜ | Sem perda de sessão |

---

## C — Marketing + plano (Prompt 10 + 11)

| # | Cenário | Passos | OK? | Notas |
|---|---------|--------|-----|-------|
| C1 | Plano ativo | Pins visíveis no mapa privado | ⬜ | |
| C2 | Plano expirado/inativo (simular data ou conta teste) | Pins **somem** no mapa · cases **permanecem** em Relatórios | ⬜ | Status não vira rascunho sozinho |
| C3 | Relatórios | Aba Marketing · case publicado oculto no mapa | ⬜ | Chip/subtitle **«Oculto no mapa»** (âmbar) |
| C4 | Long-press mapa | Com pin oculto · long-press no ponto antigo | ⬜ | Não tratar como área ocupada (#334 P2) |

---

## D — Drawing (lote 7 + 6a)

| # | Cenário | Passos | OK? | Notas |
|---|---------|--------|-----|-------|
| D1 | Salvar talhão sem cliente | Tentar concluir desenho sem cliente | ⬜ | SnackBar «Selecione o Cliente primeiro» · sem `SELF` |
| D2 | Polígono com furo (se desenhar) | Import/desenho com furo válido | ⬜ | Validação aceita/rejeita conforme produto |

---

## Encerramento

- [ ] Todos os blocos críticos (A1–A2, B1, C2–C3) **OK** → liberar build loja
- [ ] Falha registrada (screenshot + passos) → issue/PR antes de loja

**Executor:** Raudinei · **Agente não substitui** este gate.
