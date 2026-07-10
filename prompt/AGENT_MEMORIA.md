# Memória do Agente — SoloForte (Raudinei)

> Arquivo persistente de preferências e fatos operacionais.  
> O agente **DEVE ler** este arquivo no início de tarefas com Git/deploy.

---

## Preferências do Raudinei

1. **Sempre executar comandos no terminal daqui** — nunca só passar instruções para copiar
2. **Sempre sincronizar MacBook** ao encerrar tarefa — serviço completo
3. **Não parar para perguntar** se deve executar git push/merge/pull óbvios
4. **Salvar regras** em `prompt/` + `.cursor/rules/` para persistir entre sessões

---

## Dois ambientes — limitação técnica real

| Ambiente | Onde roda | Terminal | `git pull` no MacBook? |
|---|---|---|---|
| **Cloud Agent** | Linux `/workspace` (VM Cursor) | ✅ Sim | ❌ **Não** — máquina diferente |
| **Cursor Desktop (MacBook)** | macOS, pasta local do projeto | ✅ Sim | ✅ **Sim** — mesmo filesystem |

### Conclusão

- **Daqui (Cloud Agent):** o agente executa `git pull/push/merge` no **repositório remoto (GitHub)**. Isso **prepara** o MacBook, mas **não substitui** o pull local.
- **No MacBook:** só é possível quando o agente roda **localmente** no Cursor Desktop com o workspace aberto na pasta do projeto.

---

## Serviço completo de sync (pipeline obrigatório)

### Parte A — Cloud Agent executa SEMPRE (daqui)

```bash
git fetch origin
git checkout main
git pull origin main
# se houve código:
git add . && git commit -m "..." && git push -u origin <branch>
git checkout main && git pull origin main
git merge <branch> && git push origin main
git status && git log -1 --oneline
```

### Parte B — MacBook (`~/appdart`, branch `release/build-156`)

```bash
cd ~/appdart
git fetch origin
git checkout release/build-156
git pull origin release/build-156
git status && git log -1 --oneline
```

> **Não mergear `origin/main`** — usar port cirúrgico GNSS.  
> Ver `prompt/PROMPT_CODEX_RESOLVER_MERGE_BUILD156.md`

### Parte C — Encerramento obrigatório na resposta

O agente **sempre informa**:
- Commit SHA na `main`
- Confirmação `git push origin main` executado
- Próximo passo: **Cursor Desktop Mac** executa Fase 2 (ver fluxo oficial)

---

## Padrão oficial — Cursor Desktop MacBook

**Documento canônico:** `prompt/FLUXO_OFICIAL_CURSOR_DESKTOP.md`

| Fase | Ambiente | Ação |
|---|---|---|
| 1 | Cloud Agent | Implementar + push/merge `main` remota |
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
