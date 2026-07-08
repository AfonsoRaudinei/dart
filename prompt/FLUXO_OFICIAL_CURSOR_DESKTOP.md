# Fluxo Oficial — Cursor Desktop + Sync MacBook

**Projeto:** SoloForte  
**Padrão:** Oficial (Jul/2026)  
**Owner:** Raudinei  
**Repo:** `github.com/AfonsoRaudinei/dart`  
**Branch principal:** `main`

---

## Objetivo

Garantir **serviço completo de sync**: código implementado pelo agente chega ao MacBook sem passos manuais esquecidos.

---

## Arquitetura de dois ambientes

```
┌─────────────────────────────────────────────────────────────┐
│  CLOUD AGENT (Cursor Mobile / Web / Cloud)                  │
│  Linux /workspace — VM remota                               │
│  ✅ git commit / push / merge / push main                   │
│  ❌ git pull no filesystem do MacBook                       │
└──────────────────────────┬──────────────────────────────────┘
                           │ git push origin main
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  GITHUB (origin)                                            │
│  Branch main = fonte da verdade remota                      │
└──────────────────────────┬──────────────────────────────────┘
                           │ git pull origin main
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  CURSOR DESKTOP (MacBook) — PADRÃO OFICIAL PARA SYNC LOCAL  │
│  macOS — pasta local do projeto                             │
│  ✅ git pull origin main                                    │
│  ✅ flutter run / build / test                              │
│  ✅ agente executa terminal no Mac                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Quando usar cada ambiente

| Tarefa | Cloud Agent | Cursor Desktop (Mac) |
|---|---|---|
| Implementar código | ✅ | ✅ |
| Diagnóstico / auditoria | ✅ | ✅ |
| Push + merge na `main` remota | ✅ | ✅ |
| `git pull` no MacBook | ❌ | ✅ **obrigatório** |
| `flutter run` no simulador/dispositivo | ❌ | ✅ |
| Build iOS (.ipa) | ❌ | ✅ |
| Testes em hardware real | ❌ | ✅ |

**Regra de ouro:** Cloud Agent implementa → Cursor Desktop sincroniza e valida localmente.

---

## Setup inicial no MacBook (uma vez)

### 1. Instalar Cursor Desktop

- Download: https://cursor.com
- macOS Apple Silicon ou Intel

### 2. Clonar o repositório

```bash
mkdir -p ~/Developer
cd ~/Developer
git clone https://github.com/AfonsoRaudinei/dart.git SoloForte
cd SoloForte
git checkout main
```

> Ajuste o caminho se preferir outra pasta (ex.: `~/Projects/SoloForte`).

### 3. Abrir no Cursor Desktop

```
File → Open Folder → ~/Developer/SoloForte
```

### 4. Verificar Flutter

```bash
flutter doctor
flutter pub get
```

---

## Fluxo oficial por tarefa

### Fase 1 — Cloud Agent (implementação)

O agente executa **sempre** no terminal:

```bash
git fetch origin
git checkout -b cursor/<nome-da-tarefa>-ffb4
git pull origin main

# ... implementação ...

git add .
git commit -m "feat: descrição clara"
git push -u origin cursor/<nome-da-tarefa>-ffb4

git checkout main
git pull origin main
git merge cursor/<nome-da-tarefa>-ffb4
git push origin main

git status
git log -1 --oneline
```

**Encerramento Cloud Agent:** informar commit SHA na `main`.

---

### Fase 2 — Cursor Desktop MacBook (sync local — OBRIGATÓRIO)

Abrir o projeto no Cursor Desktop e pedir ao agente:

> "Sincronize o MacBook"

O agente local executa:

```bash
git fetch origin
git checkout main
git pull origin main
git status
git log -1 --oneline
```

**Confirmação:** SHA local = SHA remoto informado pelo Cloud Agent.

---

### Fase 3 — Validação local (quando aplicável)

```bash
flutter pub get
flutter analyze
flutter test
flutter run   # simulador iOS ou Android
```

---

## Checklist de encerramento — serviço completo

- [ ] Cloud Agent: commit feito
- [ ] Cloud Agent: push branch feito
- [ ] Cloud Agent: merge na `main` feito
- [ ] Cloud Agent: `git push origin main` executado
- [ ] Cloud Agent: SHA informado (ex.: `52644ae`)
- [ ] **Cursor Desktop Mac: `git pull origin main` executado**
- [ ] **Cursor Desktop Mac: SHA local confere com remoto**
- [ ] (Opcional) `flutter run` / testes locais OK

---

## Comandos rápidos (MacBook)

```bash
# Sync diário — rodar ao abrir o projeto
cd ~/Developer/SoloForte
git pull origin main
flutter pub get

# Verificar se está atualizado
git log -1 --oneline
git status
```

---

## Prefixo de branches do agente

```
cursor/<descricao-curta>-ffb4
```

Exemplos:
- `cursor/gnss-multi-constellation-fixes-ffb4`
- `cursor/gnss-checkin-accuracy-block-ffb4`

---

## Arquivos de referência do agente

| Arquivo | Função |
|---|---|
| `prompt/AGENT_MEMORIA.md` | Memória persistente — preferências Raudinei |
| `prompt/AGENT_REGRAS.md` | Regras operacionais do agente |
| `prompt/FLUXO_OFICIAL_CURSOR_DESKTOP.md` | Este documento |
| `.cursor/rules/agent-terminal.mdc` | Regra Cursor alwaysApply |
| `.cursor/rules/cursor-desktop-sync.mdc` | Regra para workspace local Mac |

---

## FAQ

**P: Posso usar só Cloud Agent e pular o Desktop?**  
R: Para código remoto sim; para rodar no Mac/simulador/dispositivo, **não**.

**P: O Cloud Agent consegue fazer git pull no Mac?**  
R: **Não.** Máquinas diferentes. O Desktop local completa o serviço.

**P: Preciso fazer algo manual no Mac?**  
R: Abrir Cursor Desktop e pedir sync — o agente local executa os comandos.

**P: E se esquecer o pull no Mac?**  
R: O código estará no GitHub mas o Mac ficará desatualizado. Sempre conferir SHA.

---

## Histórico

| Data | Evento |
|---|---|
| Jul/2026 | Fluxo oficial Cursor Desktop adotado como padrão SoloForte |
