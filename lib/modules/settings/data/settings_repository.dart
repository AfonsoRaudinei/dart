import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/settings_models.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const _keyProfileImage = 'profile_image_path';
  static const _keyUseAsAppIcon = 'profile_use_as_icon';
  // Theme keys
  static const _keyTheme = 'app_theme_mode'; // 'green', 'blue', 'black'

  ProfileState loadProfile() {
    final path = _prefs.getString(_keyProfileImage);
    final useAsIcon = _prefs.getBool(_keyUseAsAppIcon) ?? false;
    return ProfileState(imagePath: path, useAsAppIcon: useAsIcon);
  }

  Future<void> saveProfile(ProfileState profile) async {
    if (profile.imagePath != null) {
      await _prefs.setString(_keyProfileImage, profile.imagePath!);
    } else {
      await _prefs.remove(_keyProfileImage);
    }
    await _prefs.setBool(_keyUseAsAppIcon, profile.useAsAppIcon);
  }

  String loadTheme() {
    return _prefs.getString(_keyTheme) ?? 'green';
  }

  Future<void> saveTheme(String theme) async {
    await _prefs.setString(_keyTheme, theme);
  }

  Future<String?> pickAndSaveImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_pic_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(
      pickedFile.path,
    ).copy('${appDir.path}/$fileName');

    return savedImage.path;
  }

  // Future methods for storage usage
  Future<Map<String, String>> getStorageUsage() async {
    // Placeholder - real implementation would measure directories
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();

    // Simple recursive size calc
    int dataSize = await _getDirSize(appDir);
    int cacheSize = await _getDirSize(tempDir);

    return {
      'mapas': '0 MB', // Placeholder for now or check flutter_map cache
      'dados': _formatSize(dataSize),
      'cache': _formatSize(cacheSize),
    };
  }

  Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int total = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
    } catch (_) {}
    return total;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
