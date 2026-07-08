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

### Parte B — MacBook (quando agente local OU usuário)

```bash
cd ~/Developer/SoloForte   # ou caminho real do clone no Mac
git fetch origin
git checkout main
git pull origin main
git status && git log -1 --oneline
```

> **Cloud Agent não consegue executar Parte B** — não há acesso ao filesystem do Mac.

### Parte C — Encerramento obrigatório na resposta

O agente **sempre informa**:
- Commit SHA na `main`
- Confirmação `git push origin main` executado
- Instrução única para MacBook: `git pull origin main` (até existir worker local)

---

## Repo

- GitHub: `github.com/AfonsoRaudinei/dart`
- Branch principal: `main`
- Prefixo de branches do agente: `cursor/<nome>-ffb4`

---

## Histórico de decisões

| Data | Decisão |
|---|---|
| Jul/2026 | GNSS multi-constelação via `geolocator` — OS delega constelações |
| Jul/2026 | Check-in bloqueado se precisão > 30m |
| Jul/2026 | Agente sempre executa terminal; sync remoto obrigatório |
| Jul/2026 | MacBook pull local **não acessível** via Cloud Agent — documentado |
