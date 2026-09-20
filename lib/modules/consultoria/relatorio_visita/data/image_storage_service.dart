import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/local_media_path_resolver.dart';

class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();

  factory ImageStorageService() => _instance;

  ImageStorageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Captura uma imagem da câmera e salva no diretório de documentos do app.
  /// Retorna o caminho relativo (`media/img_….jpg`) ou null se cancelado.
  Future<String?> captureAndSaveImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75, // Compressão leve (qualidade 75)
      );

      if (pickedFile == null) return null;

      final savedFile = await _saveToAppDirectory(File(pickedFile.path));
      return toStoredPath(savedFile.path);
    } catch (e) {
      AppLogger.warning(
        'Erro ao capturar/salvar imagem',
        tag: 'ImageStorage',
        error: e,
      );
      return null;
    }
  }

  /// Copia um arquivo (ex.: path temporário do ImagePicker) para `documents/media`.
  /// Retorna path relativo (`media/img_….jpg`) para persistência estável no SQLite.
  Future<String?> persistLocalCopy(String sourcePath) async {
    try {
      if (sourcePath.isEmpty) return null;
      final resolved = await resolveLocalPath(sourcePath);
      final source = File(resolved ?? sourcePath);
      if (!await source.exists()) return null;
      final saved = await _saveToAppDirectory(source);
      return toStoredPath(saved.path);
    } catch (e) {
      AppLogger.warning(
        'Erro ao persistir cópia local da imagem',
        tag: 'ImageStorage',
        error: e,
      );
      return null;
    }
  }

  /// Converte path absoluto em relativo ao diretório de documentos (`media/…`).
  String toStoredPath(String absoluteOrRelativePath) =>
      LocalMediaPathResolver.toStoredPath(absoluteOrRelativePath);

  /// Resolve path armazenado (relativo ou absoluto legado) para path absoluto existente.
  Future<String?> resolveLocalPath(String stored) =>
      LocalMediaPathResolver.resolveLocalPath(stored);

  /// Salva uma cópia do arquivo no diretório de documentos da aplicação.
  Future<File> _saveToAppDirectory(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(
      p.join(directory.path, LocalMediaPathResolver.mediaSegment),
    );

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final newFileName = 'img_${const Uuid().v4()}.jpg';
    final newPath = p.join(mediaDir.path, newFileName);

    return await sourceFile.copy(newPath);
  }

  /// Remove um arquivo local pelo seu caminho (relativo ou absoluto).
  Future<void> deleteImage(String path) async {
    try {
      final resolved = await resolveLocalPath(path);
      final file = File(resolved ?? path);
      if (await file.exists()) {
        await file.delete();
        AppLogger.debug('Imagem deletada: $path', tag: 'ImageStorage');
      }
    } catch (e) {
      AppLogger.warning(
        'Erro ao deletar imagem',
        tag: 'ImageStorage',
        error: e,
      );
    }
  }
}
