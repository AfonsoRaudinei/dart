import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'visita_model.dart';
import 'package:flutter/foundation.dart';

class DraftStorageService {
  static const String _key = 'draft_visita';

  Future<void> saveDraft(VisitaModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(model.toJson()));
      debugPrint('💾 Draft salvo (auto): ${model.id}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar draft: $e');
    }
  }

  Future<VisitaModel?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) return null;
      return VisitaModel.fromJson(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('❌ Erro ao carregar draft: $e');
      return null;
    }
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    debugPrint('🗑️ Draft limpo');
  }
}
