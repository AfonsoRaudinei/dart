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
