import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/avaliacao_bloco.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/avaliacao_lado.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_media_ref.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Serviço de gerenciamento de fotos para Marketing Cases.
///
/// Offline-first:
///   1. Captura via câmera/galeria
///   2. Persiste cópia em `documents/media/marketing/`
///   3. Tenta upload ao Supabase Storage; se falhar, mantém path local
///   4. No sync (`saveCase`), resolve paths locais → URLs públicas
class MarketingPhotoService {
  static const _bucket = 'marketing-cases';
  static const _maxDimension = 1200;
  static const _quality = 85;
  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  MarketingPhotoService(this._supabase);

  /// Abre o seletor e retorna URL remota **ou** path local (offline).
  /// Retorna `null` se o usuário cancelar.
  Future<String?> pickAndUpload({
    required BuildContext context,
    String? folder,
  }) => pickAndResolve(context: context, folder: folder);

  /// Captura + persiste local; tenta upload e cai para path local se offline.
  Future<String?> pickAndResolve({
    required BuildContext context,
    String? folder,
  }) async {
    final source = await _showSourceDialog(context);
    if (source == null) return null;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: _maxDimension.toDouble(),
      maxHeight: _maxDimension.toDouble(),
      imageQuality: _quality,
    );
    if (picked == null) return null;

    final tempFile = File(picked.path);
    final fileSize = await tempFile.length();
    if (fileSize > _maxFileSizeBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto muito grande (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB). Máximo: 5 MB.',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }

    final localPath = await persistLocalCopy(tempFile.path);
    if (localPath == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar a foto localmente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    try {
      final remoteUrl = await _upload(File(localPath), folder: folder);
      if (remoteUrl != null && remoteUrl.isNotEmpty) return remoteUrl;
    } catch (e, st) {
      AppLogger.warning(
        'Upload de foto marketing falhou — mantendo path local',
        tag: 'MarketingPhoto',
        error: e,
      );
      AppLogger.debug('$st', tag: 'MarketingPhoto');
    }

    return localPath;
  }

  /// Copia arquivo temporário para `documents/media/marketing/`.
  Future<String?> persistLocalCopy(String sourcePath) async {
    try {
      if (sourcePath.isEmpty) return null;
      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(directory.path, 'media', 'marketing'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      var ext = p.extension(source.path).replaceFirst('.', '').toLowerCase();
      if (ext.isEmpty || ext == 'heic' || ext == 'heif') ext = 'jpg';
      final newPath = p.join(mediaDir.path, 'mkt_${_uuid.v4()}.$ext');
      final saved = await source.copy(newPath);
      return saved.path;
    } catch (e, st) {
      AppLogger.warning(
        'Erro ao persistir foto marketing local',
        tag: 'MarketingPhoto',
        error: e,
      );
      AppLogger.debug('$st', tag: 'MarketingPhoto');
      return null;
    }
  }

  /// Se [ref] for local, tenta upload; se remoto, devolve intacto.
  /// Em falha de rede, devolve o path local (não perde a mídia).
  Future<String?> resolveMediaRef(String? ref, {String? folder}) async {
    if (ref == null || ref.trim().isEmpty) return ref;
    if (MarketingMediaRef.isRemoteUrl(ref)) return ref;

    final path = MarketingMediaRef.toFilePath(ref);
    if (path == null) return ref;
    final file = File(path);
    if (!await file.exists()) {
      AppLogger.warning(
        'Foto local ausente no sync: $path',
        tag: 'MarketingPhoto',
      );
      return ref;
    }

    try {
      final url = await _upload(file, folder: folder);
      return (url != null && url.isNotEmpty) ? url : ref;
    } catch (e, st) {
      AppLogger.warning(
        'Falha ao resolver foto local no sync',
        tag: 'MarketingPhoto',
        error: e,
      );
      AppLogger.debug('$st', tag: 'MarketingPhoto');
      return ref;
    }
  }

  /// Resolve todas as fotos locais de um case antes do upsert remoto.
  /// Se ainda restar path local, lança [StateError] para o caller manter
  /// `pending_sync` sem enviar URLs inválidas ao Supabase.
  Future<MarketingCase> resolveCaseMedia(MarketingCase marketingCase) async {
    final fotoPrincipal = await resolveMediaRef(
      marketingCase.fotoPrincipalUrl,
      folder: 'resultado',
    );
    final fotoAntes = await resolveMediaRef(
      marketingCase.fotoAntesUrl,
      folder: 'antes_depois',
    );
    final fotoDepois = await resolveMediaRef(
      marketingCase.fotoDepoisUrl,
      folder: 'antes_depois',
    );

    final resolvedAvaliacoes = <AvaliacaoBloco>[];
    for (final bloco in marketingCase.avaliacoes) {
      final ladoAUrl = await resolveMediaRef(
        bloco.ladoA.fotoUrl,
        folder: 'avaliacoes',
      );
      final ladoBUrl = await resolveMediaRef(
        bloco.ladoB.fotoUrl,
        folder: 'avaliacoes',
      );
      resolvedAvaliacoes.add(
        AvaliacaoBloco(
          id: bloco.id,
          caseId: bloco.caseId,
          ordem: bloco.ordem,
          layout: bloco.layout,
          colapsado: bloco.colapsado,
          ladoA: AvaliacaoLado(
            label: bloco.ladoA.label,
            fotoUrl: ladoAUrl,
            tipoCultura: bloco.ladoA.tipoCultura,
            observacoes: bloco.ladoA.observacoes,
          ),
          ladoB: AvaliacaoLado(
            label: bloco.ladoB.label,
            fotoUrl: ladoBUrl,
            tipoCultura: bloco.ladoB.tipoCultura,
            observacoes: bloco.ladoB.observacoes,
          ),
        ),
      );
    }

    final resolved = MarketingCase.fromJson({
      ...marketingCase.toJson(),
      'foto_principal_url': fotoPrincipal,
      'foto_antes_url': fotoAntes,
      'foto_depois_url': fotoDepois,
      'avaliacoes': resolvedAvaliacoes.map((e) => e.toJson()).toList(),
    });

    final stillLocal = [
      resolved.fotoPrincipalUrl,
      resolved.fotoAntesUrl,
      resolved.fotoDepoisUrl,
      ...resolved.avaliacoes.expand(
        (b) => [b.ladoA.fotoUrl, b.ladoB.fotoUrl],
      ),
    ].any(MarketingMediaRef.isLocalPath);

    if (stillLocal) {
      throw StateError(
        'Fotos locais ainda não enviadas — case permanece pending_sync.',
      );
    }

    return resolved;
  }

  /// Faz upload do arquivo para o Supabase Storage.
  Future<String?> _upload(File file, {String? folder}) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) {
      throw StateError('Usuario nao autenticado.');
    }

    // FIX: image_picker no iOS pode retornar path sem extensão.
    var ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    if (ext.isEmpty || ext == 'heic' || ext == 'heif') ext = 'jpg';
    final mimeType = switch (ext) {
      'jpg' => 'image/jpeg',
      'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    final name = '${_uuid.v4()}.$ext';
    final safeFolder = folder?.replaceAll(RegExp(r'(^/+|/+$)'), '');
    final path = safeFolder != null && safeFolder.isNotEmpty
        ? '$userId/$safeFolder/$name'
        : '$userId/$name';

    try {
      await _supabase.storage
          .from(_bucket)
          .upload(
            path,
            file,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      return _supabase.storage.from(_bucket).getPublicUrl(path);
    } on StorageException catch (e, st) {
      AppLogger.error(
        'MarketingPhotoService upload error',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        'MarketingPhotoService unexpected error',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<ImageSource?> _showSourceDialog(BuildContext context) async {
    return showSoloForteSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Selecionar foto',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.blue.shade600,
                ),
              ),
              title: const Text('Câmera'),
              subtitle: const Text('Tirar nova foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: Colors.purple.shade600,
                ),
              ),
              title: const Text('Galeria'),
              subtitle: const Text('Escolher da biblioteca de fotos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
