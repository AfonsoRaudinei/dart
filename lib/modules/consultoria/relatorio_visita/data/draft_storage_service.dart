import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/infra/preferences_service.dart';
import '../../../../core/utils/app_logger.dart';
import 'visita_model.dart';

class DraftStorageService {
  const DraftStorageService(this._prefs);

  final PreferencesService _prefs;
  static const String _key = 'draft_visita';

  Future<void> saveDraft(VisitaModel model) async {
    try {
      await _prefs.setString(_key, jsonEncode(model.toJson()));
      AppLogger.debug('Draft salvo (auto): ${model.id}', tag: 'DraftStorage');
    } catch (e) {
      AppLogger.warning('Erro ao salvar draft', tag: 'DraftStorage', error: e);
    }
  }

  Future<VisitaModel?> loadDraft() async {
    try {
      final jsonString = _prefs.getString(_key);
      if (jsonString == null) return null;
      return VisitaModel.fromJson(jsonDecode(jsonString));
    } catch (e) {
      AppLogger.warning(
        'Erro ao carregar draft',
        tag: 'DraftStorage',
        error: e,
      );
      return null;
    }
  }

  Future<void> clearDraft() async {
    await _prefs.remove(_key);
    AppLogger.debug('Draft limpo', tag: 'DraftStorage');
  }
}

/// Provider de [DraftStorageService].
final draftStorageServiceProvider = Provider<DraftStorageService>((ref) {
  return DraftStorageService(ref.read(preferencesServiceProvider));
});
