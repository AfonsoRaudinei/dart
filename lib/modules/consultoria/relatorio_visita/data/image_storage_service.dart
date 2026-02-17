import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();

  factory ImageStorageService() => _instance;

  ImageStorageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Captura uma imagem da câmera e salva no diretório de documentos do app.
  /// Retorna o caminho absoluto do arquivo salvo ou null se cancelado.
  Future<String?> captureAndSaveImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75, // Compressão leve (qualidade 75)
      );

      if (pickedFile == null) return null;

      final savedFile = await _saveToAppDirectory(File(pickedFile.path));
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ Erro ao capturar/salvar imagem: $e');
      return null;
    }
  }

  /// Salva uma cópia do arquivo no diretório de documentos da aplicação
  Future<File> _saveToAppDirectory(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(directory.path, 'media'));

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final newFileName = 'img_${const Uuid().v4()}.jpg';
    final newPath = p.join(mediaDir.path, newFileName);

    return await sourceFile.copy(newPath);
  }

  /// Remove um arquivo local pelo seu caminho
  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Imagem deletada fisicamente: $path');
      }
    } catch (e) {
      debugPrint('❌ Erro ao deletar imagem: $e');
    }
  }
}
