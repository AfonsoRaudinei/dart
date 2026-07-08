# Cursor Desktop — Sync Local (MacBook)

Documento espelho do fluxo oficial. Ver detalhes completos em [`prompt/FLUXO_OFICIAL_CURSOR_DESKTOP.md`](../prompt/FLUXO_OFICIAL_CURSOR_DESKTOP.md).

## Resumo

1. **Cloud Agent** → implementa + push/merge na `main` remota
2. **Cursor Desktop (Mac)** → `git pull origin main` + validação Flutter

## Sync rápido no Mac

```bash
cd ~/Developer/SoloForte
git fetch origin && git checkout main && git pull origin main
flutter pub get
git log -1 --oneline && git status
```

## Quando usar Desktop

- Sincronizar MacBook após Cloud Agent
- `flutter run`, build iOS, testes em dispositivo real
