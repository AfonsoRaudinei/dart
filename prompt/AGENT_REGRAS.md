# Regras do Agente — SoloForte

## Terminal — SEMPRE executar daqui

O agente **DEVE executar todos os comandos de terminal no ambiente do Cursor** (`/workspace`), nunca apenas listar instruções para o usuário copiar.

---

## MacBook — Serviço completo de sync

### O que É possível daqui (Cloud Agent)

O Cloud Agent roda em **Linux na nuvem** (`/workspace`). Ele **executa**:

```bash
git fetch origin
git checkout main
git pull origin main
git push origin main          # após merge
git status && git log -1 --oneline
```

Isso mantém o **GitHub `main` atualizado** — pré-requisito para o MacBook receber o código.

### O que NÃO é possível daqui

```bash
# ❌ Cloud Agent NÃO consegue executar no MacBook:
cd ~/Developer/SoloForte && git pull origin main
```

Motivo: o MacBook é outra máquina. O agente na nuvem **não acessa** o terminal/filesystem local do Mac.

### O que É possível no MacBook

Quando o **Cursor Desktop** abre o projeto localmente, o agente local **pode e deve** executar:

```bash
git fetch origin
git checkout main
git pull origin main
git status && git log -1 --oneline
```

### Pipeline completo (obrigatório ao encerrar tarefa)

| Etapa | Quem executa | Comando |
|---|---|---|
| 1. Commit + push branch | Cloud Agent ✅ | `git push -u origin <branch>` |
| 2. Merge na main remota | Cloud Agent ✅ | `git merge && git push origin main` |
| 3. Pull no MacBook | Cursor Desktop local ✅ / Cloud ❌ | `git pull origin main` |

**Regra:** o agente **nunca encerra** sem completar etapas 1 e 2. Etapa 3: executar se workspace local; senão, indicar Fase 2 no Cursor Desktop Mac.

**Fluxo oficial completo:** `prompt/FLUXO_OFICIAL_CURSOR_DESKTOP.md`

### REGRA-ENTREGA-1 — correção só existe quando está na `main`

Commit + push numa branch de feature **não é entrega**. Toda correção de prompt só
conta como concluída quando o SHA aparece em `git log origin/main`. Ver `AGENTS.md`
(raiz) e `.agent/Prompt.md` para o checklist completo e o incidente que motivou a regra
(`302eeeb` ficou só em `cursor/fix-map-chrome-canonical-spacing` por dias).

---

## Memória persistente

Ler também: `prompt/AGENT_MEMORIA.md`

---

## Diagnóstico vs Implementação

- **DIAGNÓSTICO**: somente leitura
- **"Pode executar"**: implementar + sync remoto completo

---

## GNSS / Localização

- `geolocator` — multi-constelação via OS/chipset
- Settings: `lib/modules/dashboard/domain/location_settings.dart`
- Check-in bloqueado se precisão > 30m

---

## Relatórios HTML / Designer (corrigir sempre)

Ao tocar `assets/html_templates/**` ou `lib/core/html_templates/**`, ler e obedecer `.cursor/rules/soloforte-designer.mdc`:

| Regra | Ação |
|---|---|
| Logo SoloForte | Obrigatório no header de **todos** os HTML — imagem oficial, nunca emoji |
| Ícones genéricos | **Proibido** (⚠ 🌱 📊 SVG decorativos) — corrigir sempre que aparecer |
| Localização | Inline resumida (label + 📍), sem caixa gigante vazia |
| Rodapé | Só SoloForte + tagline — excluir ID, Sync, Sessão, meta técnica |

Validar após mudança: header com `logo-img` / `soloforte_logo`, zero `footer-meta` com ID/Sync, localização `.localizacao-inline`.

---

## Bottom sheets — REGRA-SHEET-BLAST-1 (IPA 210)

**Espelho de:** `.agent/AGENT_REGRAS.md` · **Auditoria:** `.agent/AUDITORIA_REGRESSAO_IPA210.md`

Ao tocar `lib/core/ui/sheets/`:

```bash
rg -l showSoloForteSheet lib/
rg -l 'backgroundColor: Colors.transparent' lib/
flutter test test/regression/sheets/soloforte_sheet_contract_test.dart
```

- **20+ callers** com `transparent` — não confiar na lista de 12 do prompt Fase 1
- **Proibido** inverter contrato `transparent` / `preserveMaterialDefaults` sem atualizar callers
- Conteúdo com `SoloForteSheetTokens.titleColor` (branco) não assume fundo escuro no tema Azul

---

## Coluna direita do mapa — REGRA-MAP-CHROME-1

- Usar `kMapActionColumnBottomInset` — **nunca** `mapSheetChromeInsetProvider`
- Gaps canônicos: 26dp (camadas↔+) · 16dp (+↔check-in)
- Teste: `flutter test test/regression/map/controls_overlay_regression_test.dart`
