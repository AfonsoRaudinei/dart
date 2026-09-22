# Prompt — QA visual fluxo talhão (tema Azul)

Use com agente **soloforte-designer-visual** ou no chat (supervisor).

## Pré-requisitos

- `origin/main` atualizado (ex.: `git pull origin main`)
- Settings → **Tema Azul**
- `flutter run` no device (não só hot restart após troca de branch)

## Roteiro (5 min)

1. **Cliente** → abrir cliente com fazenda e talhões
2. **Fazenda** → lista de talhões
3. Abrir **Ações do talhão** (menu curto)
4. Entrar **Dados do talhão** → editar campo → Salvar → ver **banner inline** (sem SnackBar)
5. Se disponível: **União** → handle + chip “Talhão principal”

## Checklist

Preencher tabela em `design/sheets.md` → **BLOCO 5** (5.1–5.14).

## Se falhar

Ler `.agent/AUDITORIA_CHATS_CLICKS_DESIGN_2026-09-22.md` — distinguir:

- Premium **mergeado** (#137, #143) vs **Auditoria de cliques** (#148 ainda aberto)

## Supervisor

Se FAIL com código correto na `main`: pedir screenshot + tema + SHA.  
Se expectativa era #148: briefar merge/review de PR #148, não reimplementar sheets.
