# Memória do Agente — SoloForte (Raudinei)

> Arquivo persistente de preferências e fatos operacionais.  
> **Canônico neste path.** `prompt/AGENT_MEMORIA.md` é apenas redirecionamento.
> O agente **DEVE ler** este arquivo no início de tarefas com Git/deploy.

---

## Preferências do Raudinei

1. **Sempre executar comandos no terminal daqui** — nunca só passar instruções para copiar
2. **Sempre sincronizar MacBook** ao encerrar tarefa — serviço completo
3. **Não parar para perguntar** se deve executar git push da **branch** ou pull óbvios. Merge na `main` segue o gate (revisor + path crítico + auto-merge). P0/P1/P2 e path crítico **param**.
4. **Salvar regras** em `.agent/` + `.cursor/rules/` (canônico); `prompt/` só para prompts de execução
5. **Correção não é entrega enquanto não estiver em `origin/main`** — auto-merge armado não conta (REGRA-ENTREGA-1, ver `AGENTS.md`)

### Hook local (uma vez, humano)

Agentes **não** rodam `git config`. No clone:

```bash
git config core.hooksPath tool/hooks
```

O hook `tool/hooks/pre-push` recusa `main` e `release/*`. Cadeado: `docs/03_ENFORCEMENT/supervisor-merge-gate.md`.

---

## Dois ambientes — limitação técnica real

| Ambiente | Onde roda | Terminal | `git pull` no MacBook? |
|---|---|---|---|
| **Cloud Agent** | Linux `/workspace` (VM Cursor) | ✅ Sim | ❌ **Não** — máquina diferente |
| **Cursor Desktop (MacBook)** | macOS, pasta local do projeto | ✅ Sim | ✅ **Sim** — mesmo filesystem |

### Conclusão

- **Daqui (Cloud Agent):** o agente faz push da **branch** e o supervisor arma auto-merge do PR. Isso **prepara** o MacBook, mas **não substitui** o pull local. Nunca `git push origin main`.
- **No MacBook:** só é possível quando o agente roda **localmente** no Cursor Desktop com o workspace aberto na pasta do projeto.

---

## Serviço completo de sync (pipeline obrigatório)

### Parte A — Cloud Agent executa SEMPRE (daqui)

```bash
git fetch origin
git checkout main
git pull origin main
# se houve código (executor):
git push -u origin <branch>
# supervisor: PR + gh pr merge --auto --rebase — nunca git push origin main
git status && git log -1 --oneline
```

### Parte B — MacBook (pasta local do projeto)

**Path:** a pasta **não** é necessariamente `~/appdart` (esse path pode não existir). Usar o diretório do clone onde o Cursor Desktop já está aberto (prompt costuma mostrar `... appdart %`).

**Preferência atual (IPA 209+ / pin-norte / coluna direita):**

```bash
# já dentro da pasta do projeto:
git fetch origin
git checkout main
git pull origin main
flutter pub get
git status && git log -1 --oneline
# esperado: SHA = origin/main (ex.: ddf7f56+)
# depois: flutter run  OU  archive IPA novo — hot restart nao basta
```

**Legado `release/build-156`:** só se o fluxo GNSS cirúrgico ainda exigir essa branch — **não mergear `origin/main` cego**; usar port. Pin/norte já portado (PR #62). Ver `prompt/PROMPT_CODEX_RESOLVER_MERGE_BUILD156.md`.

**zsh:** não cole comentários com parênteses na mesma linha do comando — zsh trata `(...)` como glob qualifier (`unknown file attribute`).

### Parte C — Encerramento obrigatório na resposta

O agente **sempre informa**:
- SHA em `origin/main` **ou** `auto-merge armado, pendente de CI — ainda não está na main` + URL do PR
- Nunca `git push origin main`
- Próximo passo: **Cursor Desktop Mac** executa Fase 2 (ver fluxo oficial)

---

## Padrão oficial — Cursor Desktop MacBook

**Documento canônico:** `prompt/FLUXO_OFICIAL_CURSOR_DESKTOP.md`

| Fase | Ambiente | Ação |
|---|---|---|
| 1 | Cloud Agent | Branch + PR + auto-merge rebase (nunca push em `main`) |
| 2 | **Cursor Desktop Mac** | `git pull origin main` + `flutter pub get` |
| 3 | Cursor Desktop Mac | Validar (`flutter run`, testes) |

**Adotado Jul/2026** como padrão oficial SoloForte para serviço completo de sync.

---

## Repo

- GitHub: `github.com/AfonsoRaudinei/dart`
- Branch principal: `main`
- Prefixo de branches do agente: `cursor/<nome>-ffb4`

---

## Relatórios HTML — branding (corrigir sempre)

Fonte canônica: `.cursor/rules/soloforte-designer.mdc`

1. **Logo SoloForte obrigatório** no header de **todos** os HTML (`{{report_header_signature}}` com `assets/images/soloforte_logo.png`)
2. **Nunca** ícones genéricos (⚠ 🌱 📊 SVG decorativos) no lugar da marca ou em cards
3. **Localização** sempre **inline resumida** (não bloco gigante vazio)
4. **Rodapé** só marca SoloForte + tagline — excluir ID / Sync / meta técnica

## Histórico de decisões

| Data | Decisão |
|---|---|
| Jul/2026 | GNSS multi-constelação via `geolocator` — OS delega constelações |
| Jul/2026 | Check-in bloqueado se precisão > 30m |
| Jul/2026 | Agente sempre executa terminal; sync remoto obrigatório |
| Jul/2026 | MacBook pull local **não acessível** via Cloud Agent — documentado |
| Jul/2026 | MacBook: pasta `~/appdart`, branch `release/build-156` — NÃO mergear main |
| Jul/2026 | Prompt Codex merge: `prompt/PROMPT_CODEX_RESOLVER_MERGE_BUILD156.md` |
| Jul/2026 | HTML reports: logo SoloForte no header; zero ícones genéricos; localização inline; rodapé sem ID/Sync |
| Ago/2026 | **Pin marketing + norte:** fix em `main` (PR #39/#61, `768e370`/`c33f7c9` + endurecimento). Course-up GNSS removido; `MarkerLayer(rotate:true)` + `topCenter`. Port cirúrgico em `release/build-156` (PR #62). **Dispositivo só atualiza após `git pull` + rebuild IPA (209+ / hot restart não basta se binário antigo).** |
| Ago/2026 | **Ocorrências mapa IPA 206:** pin atômico em `MapSheetState`; blindagem `.agent/PLANO_BLINDAGEM_OCORRENCIAS_MAPA.md` + REGRA-OCC-8..11 |
| Ago/2026 | **Coluna direita mapa:** posição travada via `kMapActionColumnBottomInset` (REGRA-MAP-CHROME-1) — sem `mapSheetChromeInsetProvider`; **IPA 208 sem o fix → 209+** |
| Ago/2026 | **Hardening coluna direita:** contrato 2 botões (layers/check-in, gap 16, draw comp 60, `kFabSafeArea` 76dp); testes integração FAB + BUG-009 widget + modo produtor; constantes mortas (26/12) removidas |
| Ago/2026 | **SheetSkin iOS (tema Azul):** cherry-pick `6230591` em `main` · `SoloForteThemeExtension` + `SoloForteSheetSkinIos` · tag `feat/sheet-skin-ios` · doc `design/sheets.md` |
| Ago/2026 | **Incidente REGRA-ENTREGA-1:** fix da coluna direita (gaps 26/16, commit `302eeeb`) ficou só na branch `cursor/fix-map-chrome-canonical-spacing`, sem merge na `main` — corrigido e regra endurecida em `AGENTS.md`/`AGENT_REGRAS.md`/`.agent/Prompt.md`: correção só conta como entregue quando está em `origin/main` |
| Ago/2026 | **Long press → ações rápidas (IPA 222):** botão `+` removido; gesto em área vazia abre `PublicationActionsBottomSheet` já com o `LatLng`; `ArmedMode.marketing` eliminado de ponta a ponta. Tap normal segue via `ArmedMode.occurrences` |
| Ago/2026 | **Incidente autoDispose (REGRA-AUTODISPOSE-1):** pin do long press e rascunho por pin morriam porque ninguém fazia `watch` nos providers `autoDispose`. Sintoma no app: Ocorrência abria "Marque o ponto no mapa" ignorando o gesto, e rascunho nunca voltava. Gravar rascunho em `dispose`/`deactivate` também lançava `StateError`. Fix: `watch` antes do early-return no host + provider de rascunho sem `autoDispose` + persistência a cada mutação |
| Ago/2026 | **Suíte de testes:** 13 → 2 falhas. As 11 fechadas eram testes obsoletos (campos em `ListView` lazy nunca construídos, `MarkerLayer` pré-ADR-035, rótulo do botão salvar virando spinner). Débito restante: `agenda/start_event_use_case` (rethrow intencional do espelho) e `drawing_selected_sheet` (rótulo do diálogo) |
| Ago/2026 | **Supervisor + cadeado de merge:** chat padrão não escreve `lib/`; executor/revisor separados; `main` só via PR rebase. Hook `tool/hooks/pre-push` (humano: `git config core.hooksPath tool/hooks` uma vez). Auto-merge armado não é entrega. Doc: `docs/03_ENFORCEMENT/supervisor-merge-gate.md` |
| Ago/2026 | **Restore pós-reinstall:** código #67/#68 + SQL carteira no live + IPA 224 (`bd1fabb`, `./build_testflight.sh` Exit 0). Placar **55%**. F2.4 falhou: live `clients`/carteira/relatórios/marketing cases ainda 0 após Sincronizar no 224 (install sem SQLite para push, ou push sem gravar). F3 wipe **proibida** neste aparelho. PRD: `docs/PRD_RESTORE_REINSTALL_IPA.md` · checklist: `.agent/CHECKLIST_RESTORE_REINSTALL.md`. Hot restart não basta. |
