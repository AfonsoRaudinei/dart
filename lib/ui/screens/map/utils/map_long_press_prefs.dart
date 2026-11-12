import '../../../../core/infra/preferences_service.dart';

/// Chave local: primeira vez que o usuário usou long press (ISO8601).
const String kMapLongPressUsedAtKey = 'map_longpress_used_at';

/// Contador de sessões em que o hint foi exibido (sem uso do gesto).
const String kMapLongPressHintSessionCountKey =
    'map_longpress_hint_session_count';

/// ISO8601 quando o usuário tocou em [kMapLongPressHintAcknowledgeLabel].
const String kMapLongPressHintAcknowledgedAtKey =
    'map_longpress_hint_acknowledged_at';

/// Máximo de sessões com hint antes de parar de exibir (sem uso do gesto).
const int kMapLongPressHintMaxSessions = 12;

/// Duração máxima do hint na tela antes do auto-dismiss (segundos).
const int kMapLongPressHintVisibleSeconds = 10;

/// Copy do hint progressivo (área livre — alinhado ao hit-test).
const String kMapLongPressHintMessage =
    'Toque e segure numa área livre do mapa para registrar uma ocorrência';

/// Label do botão que encerra o hint permanentemente.
const String kMapLongPressHintAcknowledgeLabel = 'Entendi';

/// Feedback curto quando long press cai sobre talhão, pin ou desenho.
const String kMapLongPressOccupiedFeedbackMessage =
    'Toque e segure numa área livre do mapa';

bool hasUsedMapLongPress(PreferencesService prefs) {
  final value = prefs.getString(kMapLongPressUsedAtKey);
  return value != null && value.isNotEmpty;
}

bool hasAcknowledgedMapLongPressHint(PreferencesService prefs) {
  final value = prefs.getString(kMapLongPressHintAcknowledgedAtKey);
  return value != null && value.isNotEmpty;
}

int mapLongPressHintSessionCount(PreferencesService prefs) {
  return prefs.getInt(kMapLongPressHintSessionCountKey) ?? 0;
}

/// Exibe hint enquanto o gesto nunca foi usado, não foi dispensado com
/// "Entendi" e ainda há sessões disponíveis.
bool shouldShowMapLongPressHint(PreferencesService prefs) {
  if (hasAcknowledgedMapLongPressHint(prefs)) return false;
  if (hasUsedMapLongPress(prefs)) return false;
  return mapLongPressHintSessionCount(prefs) < kMapLongPressHintMaxSessions;
}

/// Registra uma sessão de exibição do hint (uma vez por boot da tela do mapa).
Future<void> recordMapLongPressHintSession(PreferencesService prefs) {
  final count = mapLongPressHintSessionCount(prefs);
  if (count >= kMapLongPressHintMaxSessions) {
    return Future.value();
  }
  return prefs.setInt(kMapLongPressHintSessionCountKey, count + 1);
}

Future<void> markMapLongPressUsed(PreferencesService prefs) {
  return prefs.setString(
    kMapLongPressUsedAtKey,
    DateTime.now().toIso8601String(),
  );
}

Future<void> markMapLongPressHintAcknowledged(PreferencesService prefs) {
  return prefs.setString(
    kMapLongPressHintAcknowledgedAtKey,
    DateTime.now().toIso8601String(),
  );
}
