# Android — SCHEDULE_EXACT_ALARM (Play Console)

Documentação operacional para declarar e justificar o uso de alarmes exatos na Google Play Console.

**Escopo:** lembretes de eventos da agenda agronômica (`AgendaNotificationService`).

---

## Por que a permissão existe

| Item | Detalhe |
|---|---|
| Permissão | `android.permission.SCHEDULE_EXACT_ALARM` |
| Manifest | `android/app/src/main/AndroidManifest.xml` |
| Código | `lib/modules/agenda/data/services/agenda_notification_service.dart` |
| Plugin | `flutter_local_notifications` + receivers `ScheduledNotificationReceiver` / `ScheduledNotificationBootReceiver` |
| Uso | Notificações **30 min antes** e **no início** de eventos da agenda |

A permissão é necessária no Android 12+ para disparar lembretes no horário planejado (`AndroidScheduleMode.exactAllowWhileIdle`).

---

## Comportamento de fallback (obrigatório na revisão)

O app **não depende exclusivamente** de exact alarms:

1. `_androidScheduleMode()` chama `canScheduleExactNotifications()`.
2. Se negado, tenta `requestExactAlarmsPermission()`.
3. Se ainda negado, usa `AndroidScheduleMode.inexactAllowWhileIdle`.

Ou seja: o usuário que desabilitar alarmes exatos no sistema continua recebendo lembretes (com possível atraso).

---

## Onde declarar na Play Console

1. **Play Console** → app SoloForte → **App content**
2. **Sensitive app permissions** (ou **Policy** → **App permissions**)
3. Localizar **Alarms & reminders** / **Alarmes e lembretes**
4. Declarar uso de `SCHEDULE_EXACT_ALARM`

Se a Play Console solicitar **Permission declaration form** para alarmes:

- **Feature:** Agenda / lembretes de eventos de campo
- **User benefit:** Consultor recebe alerta antes e no início de visitas planejadas
- **Core functionality:** Sim — parte do módulo agenda offline-first

---

## Texto sugerido (justificativa — copiar/adaptar)

**Português (interno):**

> O SoloForte agenda lembretes locais para eventos da agenda agronômica (30 minutos antes e no horário de início). A permissão SCHEDULE_EXACT_ALARM garante pontualidade dos alertas em Android 12+. Se o usuário negar alarmes exatos nas configurações do sistema, o app continua funcionando com alarmes inexatos (inexactAllowWhileIdle). Não usamos alarmes exatos para publicidade, analytics ou tracking.

**English (Play Console form, se exigido):**

> SoloForte schedules local notifications for agronomic calendar events (30-minute reminder and event start). SCHEDULE_EXACT_ALARM is required on Android 12+ to deliver time-sensitive field reminders. If the user denies exact alarms in system settings, the app falls back to inexact scheduling. Exact alarms are not used for ads, analytics, or cross-app tracking.

---

## Teste manual recomendado (Android 12+)

Pré-requisito: device ou emulador API 31+.

1. Criar evento na agenda com início **> 35 minutos** no futuro.
2. Confirmar notificação de lembrete (30 min antes) e de início.
3. Em **Configurações → Apps → SoloForte → Alarmes e lembretes**, desabilitar alarmes exatos.
4. Criar novo evento futuro.
5. ✅ Esperado: lembrete ainda é agendado (modo inexact); app não crasha.

---

## Checklist de release Android

```
[ ] SCHEDULE_EXACT_ALARM presente no manifest
[ ] AgendaNotificationService com fallback inexactAllowWhileIdle
[ ] Declaração preenchida na Play Console (Alarms & reminders)
[ ] ./tool/release_store_check.sh → Exit 0
[ ] flutter build appbundle --release OK
```

---

## Referências no repositório

- `docs/android/RELEASE.md` — minify R8 + resumo da permissão
- `tool/release_store_check.sh` — gate automatizado
- `lib/modules/agenda/domain/services/i_agenda_notification_service.dart` — contrato DIP

---

## Quando remover a permissão

Remover `SCHEDULE_EXACT_ALARM` **somente** se o produto abandonar lembretes com horário exato e aceitar apenas notificações inexatas. Isso degradaria UX de agenda em Android 12+.
