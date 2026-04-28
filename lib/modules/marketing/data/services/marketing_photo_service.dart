import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Serviço de gerenciamento de fotos para Marketing Cases.
///
/// Responsabilidades:
///   1. Capturar imagem via câmera ou galeria
///   2. Comprimir para ≤1200px, qualidade 85% (sem dependência extra)
///   3. Fazer upload ao Supabase Storage bucket `marketing-cases`
///   4. Retornar a URL pública
class MarketingPhotoService {
  static const _bucket = 'marketing-cases';
  static const _maxDimension = 1200;
  static const _quality = 85;
  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  MarketingPhotoService(this._supabase);

  /// Abre o seletor de origem (câmera ou galeria) e retorna a URL pública.
  /// Retorna `null` se o usuário cancelar.
  Future<String?> pickAndUpload({
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

    // Validar tamanho
    final file = File(picked.path);
    final fileSize = await file.length();
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

    return _upload(file, folder: folder);
  }

  /// Faz upload do arquivo para o Supabase Storage.
  Future<String?> _upload(File file, {String? folder}) async {
    try {
      // FIX: image_picker no iOS pode retornar path sem extensão (ex: arquivo
      // temporário). p.extension() retorna '' nesses casos, gerando path inválido
      // ("uuid.") e contentType inválido ("image/"), causando StorageException.
      // Fallback seguro para 'jpg'. HEIC normalizado para 'jpg' (MIME padrão).
      var ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      if (ext.isEmpty || ext == 'heic' || ext == 'heif') ext = 'jpg';
      // FIX: 'image/jpg' é MIME inválido — Supabase Storage exige 'image/jpeg'.
      // Mapeamento explícito ext → MIME type válido (RFC 2046 / IANA).
      final mimeType = switch (ext) {
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final name = '${_uuid.v4()}.$ext';
      final path = folder != null ? '$folder/$name' : name;

      await _supabase.storage
          .from(_bucket)
          .upload(
            path,
            file,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e, st) {
      debugPrint('MarketingPhotoService upload error: $e\n$st');
      rethrow;
    } catch (e) {
      debugPrint('MarketingPhotoService unexpected error: $e');
      return null;
    }
  }

  /// Diálogo de escolha de origem (Câmera / Galeria)
  Future<ImageSource?> _showSourceDialog(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
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
