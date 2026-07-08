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
# Se aprovado pelo usuário ou escopo concluído:
git checkout main
git pull origin main
git merge <branch>
git push origin main
```

### Proibido

- Dizer "rode no seu MacBook" sem antes ter executado push/merge no remoto
- Deixar alterações só locais sem commit/push
- Parar para perguntar se deve executar comandos óbvios de entrega

### MacBook do usuário

O agente **não acessa** o terminal local do MacBook. O fluxo correto é:

1. Agente executa tudo aqui → push/merge na `main` remota
2. Usuário só precisa de `git pull origin main` no Mac (se quiser sincronizar local)

---

## Diagnóstico vs Implementação

- Prompts marcados como **DIAGNÓSTICO**: somente leitura, sem alterar código
- Quando o usuário disser **"Pode executar"**: implementar, commitar, push e mergear

---

## GNSS / Localização

- Pacote: `geolocator` — multi-constelação delegada ao OS/chipset
- Settings unificados: `lib/modules/dashboard/domain/location_settings.dart`
- Controller legado: `LocationController` (não reescrever para @riverpod sem ADR)
- Check-in bloqueado se precisão > 30m (`soloforteGnssMaxCheckInAccuracyMeters`)
