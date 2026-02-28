import 'package:file_picker/file_picker.dart';

/// Abstração sobre FilePicker platform.
///
/// Permite injeção de fakes em testes unitários sem depender
/// do plugin real (que requer UI nativa).
abstract interface class IFilePicker {
  /// Abre o seletor de arquivos filtrando pelas extensões fornecidas.
  /// Retorna [PlatformFile] se o usuário selecionou um arquivo,
  /// ou null se cancelou.
  Future<PlatformFile?> pickSingleFile({
    required List<String> allowedExtensions,
  });
}
