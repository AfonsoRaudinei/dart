# Cursor Desktop — Sync Local (MacBook)

Documento espelho do fluxo oficial. Ver detalhes completos em [`prompt/FLUXO_OFICIAL_CURSOR_DESKTOP.md`](../prompt/FLUXO_OFICIAL_CURSOR_DESKTOP.md).

## Resumo

1. **Cloud Agent** → implementa + push/merge na `main` remota
2. **Cursor Desktop (Mac)** → `git pull origin main` + validação Flutter

## Sync rápido no Mac

```bash
cd ~/appdart
git fetch origin && git checkout release/build-156 && git pull origin release/build-156
flutter pub get
git log -1 --oneline && git status
```

> **Não mergear `origin/main` diretamente** — arquiteturas divergentes.  
> Ver: `prompt/PROMPT_CODEX_RESOLVER_MERGE_BUILD156.md`

## Quando usar Desktop

- Sincronizar MacBook após Cloud Agent
- `flutter run`, build iOS, testes em dispositivo real
