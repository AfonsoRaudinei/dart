import 'package:file_picker/file_picker.dart';
import 'i_file_picker.dart';

/// Implementação real de [IFilePicker] usando o plugin `file_picker`.
///
/// Em produção, este adapter é injetado pelo provider.
/// Em testes unitários, usa-se [FakeFilePicker] no lugar.
class FilePickerAdapter implements IFilePicker {
  const FilePickerAdapter();

  @override
  Future<PlatformFile?> pickSingleFile({
    required List<String> allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }
}
