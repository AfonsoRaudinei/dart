import 'dart:typed_data';

import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';

import '../data/quick_photo_repository.dart';
import 'quick_photo_record.dart';

/// Resolve o `visit_session_id` a persistir.
///
/// Id explícito vence. Sem id, usa a sessão ativa. Sem sessão ou erro: `null`.
Future<String?> resolveVisitSessionIdForPhoto(
  IVisitSessionLookup lookup, {
  String? explicit,
}) async {
  if (explicit != null && explicit.isNotEmpty) return explicit;
  try {
    final session = await lookup.getActiveSession();
    if (session != null && session.isActive) return session.id;
  } catch (_) {
    // Lookup falhou: grava sem sessão, não bloqueia.
  }
  return null;
}

/// Persiste foto rápida/inversão vegetal injetando a sessão ativa, se houver.
///
/// Sem sessão ativa o save segue com [visitSessionId] nulo — não bloqueia.
class SaveQuickPhoto {
  SaveQuickPhoto(this._repository, this._sessionLookup);

  final QuickPhotoRepository _repository;
  final IVisitSessionLookup _sessionLookup;

  Future<QuickPhotoRecord> execute({
    required Uint8List bytes,
    required String localPath,
    double? lat,
    double? lng,
    String? visitSessionId,
    QuickPhotoType type = QuickPhotoType.normal,
  }) async {
    final resolvedId = await resolveVisitSessionIdForPhoto(
      _sessionLookup,
      explicit: visitSessionId,
    );
    return _repository.uploadAndInsert(
      bytes: bytes,
      localPath: localPath,
      lat: lat,
      lng: lng,
      visitSessionId: resolvedId,
      type: type,
    );
  }
}
