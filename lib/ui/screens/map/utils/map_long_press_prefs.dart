import '../../../../core/infra/preferences_service.dart';

/// Chave local de onboarding do long press no mapa (SharedPreferences).
const String kMapLongPressUsedAtKey = 'map_longpress_used_at';

bool hasUsedMapLongPress(PreferencesService prefs) {
  final value = prefs.getString(kMapLongPressUsedAtKey);
  return value != null && value.isNotEmpty;
}

Future<void> markMapLongPressUsed(PreferencesService prefs) {
  return prefs.setString(
    kMapLongPressUsedAtKey,
    DateTime.now().toIso8601String(),
  );
}
