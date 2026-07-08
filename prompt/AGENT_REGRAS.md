# Regras do Agente — SoloForte

## Terminal — SEMPRE executar daqui

O agente **DEVE executar todos os comandos de terminal no ambiente do Cursor** (`/workspace`), nunca apenas listar instruções para o usuário copiar.

### Obrigatório em toda tarefa com Git

```bash
git fetch origin
git checkout <branch>
git pull origin <branch>
# ... implementação ...
git add ...
git commit -m "..."
git push -u origin <branch>
# Entrega concluída — SEMPRE mergear na main:
git checkout main
git pull origin main
git merge <branch>
git push origin main
```

### Proibido

- Dizer "rode no seu MacBook" sem antes ter executado push/merge no remoto
- Deixar alterações só locais sem commit/push
- Parar para perguntar se deve executar comandos óbvios de entrega
- Encerrar tarefa sem sincronizar (ver seção MacBook abaixo)

---

## MacBook — SEMPRE sincronizar

**Regra do Raudinei:** ao final de **toda** tarefa, o MacBook deve ficar sincronizado. O agente **executa** — não delega.

### Pipeline obrigatório de encerramento (toda tarefa)

```bash
# 1. Remoto atualizado (agente executa sempre)
git fetch origin
git checkout main
git pull origin main
git push origin main

# 2. Confirmar estado limpo
git status
git log -1 --oneline
```

Se houve implementação na tarefa, **antes** do passo 1:

```bash
git add .
git commit -m "..."
git push -u origin <branch>
git checkout main
git pull origin main
git merge <branch>
git push origin main
```

### MacBook local

- O agente **não acessa** o terminal físico do MacBook quando roda na nuvem.
- **Equivalente obrigatório na nuvem:** `main` remota 100% atualizada via push (passos acima).
- Quando o workspace **for o MacBook local** (Cursor Desktop): executar também `git pull origin main` no diretório do projeto antes de encerrar.
- **Nunca** encerrar resposta sem confirmar: branch, commit SHA e `main` remota sincronizada.

### Checklist de encerramento (obrigatório)

- [ ] Commit feito
- [ ] Push da branch feito
- [ ] Merge na `main` feito
- [ ] `git push origin main` executado
- [ ] `git status` limpo
- [ ] Commit SHA informado ao usuário

---

## Diagnóstico vs Implementação

- Prompts marcados como **DIAGNÓSTICO**: somente leitura, sem alterar código
- Quando o usuário disser **"Pode executar"**: implementar, commitar, push, mergear e sincronizar

---

## GNSS / Localização

- Pacote: `geolocator` — multi-constelação delegada ao OS/chipset
- Settings unificados: `lib/modules/dashboard/domain/location_settings.dart`
- Controller legado: `LocationController` (não reescrever para @riverpod sem ADR)
- Check-in bloqueado se precisão > 30m (`soloforteGnssMaxCheckInAccuracyMeters`)
