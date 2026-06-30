# FIX — SECRET HARDCODED: OpenWeather API Key
## Correção de chave exposta em clima_config.dart

**Agente:** Engenheiro Sênior Flutter/Dart  
**Prioridade:** CRÍTICO — bloqueia push para o GitHub

---

## CONTEXTO

O GitHub Push Protection bloqueou o push da branch `release/v1.1`:
- commit: `fb3e1a3781f694311c26ef11b4ff6f5d5f158e46`
- path: `lib/core/config/clima_config.dart:9`

**Ação manual obrigatória:** Revogar a chave atual no painel OpenWeather
e gerar uma nova antes de usar em produção.
URL: https://home.openweathermap.org/api_keys

---

## ESCOPO

🚫 Proibido reescrever histórico git  
🚫 Proibido alterar outros arquivos além do necessário  

---

*Prompt gerado para: SoloForte App — Correção de secret exposto*  
*Commit com secret: fb3e1a3 — path: lib/core/config/clima_config.dart:9*
