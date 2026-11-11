import '../../../../core/infra/preferences_service.dart';
import '../../../components/map/map_sheet_state.dart';
import '../providers/map_armed_mode_provider.dart';
import 'map_long_press_prefs.dart';

/// Condições para exibir o hint de long press (sem efeitos colaterais).
bool mapLongPressHintEnvironmentReady({
  required PreferencesService prefs,
  required bool mapReady,
  required ArmedMode armedMode,
  required MapSheetState? sheetState,
  required bool isModalOpen,
}) {
  if (!shouldShowMapLongPressHint(prefs)) return false;
  if (!mapReady) return false;
  if (armedMode != ArmedMode.none) return false;
  if (sheetState != null) return false;
  if (isModalOpen) return false;
  return true;
}
