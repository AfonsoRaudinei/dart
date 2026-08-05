# Android release — SoloForte

## Minify / R8

Release builds usam `isMinifyEnabled = true` e `proguard-rules.pro` em `android/app/`.

Validar localmente:

```bash
flutter build apk --release
```

## SCHEDULE_EXACT_ALARM

Permissão necessária para lembretes de eventos da agenda com horário exato
(`AgendaNotificationService` + `flutter_local_notifications`).

Na Play Console, declarar uso em **Alarmes e lembretes** quando aplicável.
Fallback inexact permanece ativo se o usuário negar exact alarms.

**Guia completo (texto Play Console + checklist):**
`docs/android/SCHEDULE_EXACT_ALARM_PLAY_CONSOLE.md`

**Gate automatizado:**

```bash
./tool/release_store_check.sh
```
