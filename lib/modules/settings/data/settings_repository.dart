import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/settings_models.dart';
import '../../../core/utils/app_logger.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const _keyProfileImage = 'profile_image_path';
  static const _keyUseAsAppIcon = 'profile_use_as_icon';
  static const _keyReportBrandName = 'report_brand_name';
  static const _keyReportLogoPath = 'report_logo_path';
  static const _reportBrandingBucket = 'report-branding';
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

  ReportBrandingState loadReportBranding() {
    return ReportBrandingState(
      brandName: _prefs.getString(_keyReportBrandName),
      logoPath: _prefs.getString(_keyReportLogoPath),
    );
  }

  Future<ReportBrandingState> saveReportBranding(
    ReportBrandingState branding,
  ) async {
    var effective = branding;
    final brandName = branding.brandName?.trim();
    if (brandName != null && brandName.isNotEmpty) {
      await _prefs.setString(_keyReportBrandName, brandName);
    } else {
      await _prefs.remove(_keyReportBrandName);
    }

    final logoPath = branding.logoPath?.trim();
    if (logoPath != null && logoPath.isNotEmpty) {
      await _prefs.setString(_keyReportLogoPath, logoPath);
    } else {
      await _prefs.remove(_keyReportLogoPath);
    }

    try {
      final remoteLogo = await _syncReportBrandingRemote(branding);
      if (remoteLogo != null && remoteLogo.trim().isNotEmpty) {
        effective = branding.copyWith(logoPath: remoteLogo);
        await _prefs.setString(_keyReportLogoPath, remoteLogo);
      }
    } catch (e) {
      AppLogger.warning(
        'Marca de relatório salva localmente. Sync pendente.',
        tag: 'Settings',
        error: e,
      );
    }

    return effective;
  }

  Future<ReportBrandingState?> loadRemoteReportBranding() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return null;

      final row = await client
          .from('perfis')
          .select('report_brand_name, report_logo_url')
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return null;

      final remote = ReportBrandingState(
        brandName: (row['report_brand_name'] as String?)?.trim(),
        logoPath: (row['report_logo_url'] as String?)?.trim(),
      );
      await _persistReportBrandingLocal(remote);
      return remote;
    } catch (e) {
      AppLogger.warning(
        'Falha ao carregar marca remota de relatório',
        tag: 'Settings',
        error: e,
      );
      return null;
    }
  }

  String loadTheme() {
    return _prefs.getString(_keyTheme) ?? 'green';
  }

  Future<void> saveTheme(String theme) async {
    await _prefs.setString(_keyTheme, theme);
  }

  Future<String?> pickAndSaveImage(ImageSource source) async {
    return _pickAndSaveImage(source, prefix: 'profile_pic');
  }

  Future<String?> pickAndSaveReportLogo(ImageSource source) async {
    return _pickAndSaveImage(source, prefix: 'report_logo');
  }

  Future<String?> _syncReportBrandingRemote(
    ReportBrandingState branding,
  ) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final logoPath = branding.logoPath?.trim();
    var logoUrl = logoPath;
    if (logoPath != null &&
        logoPath.isNotEmpty &&
        !logoPath.startsWith('http') &&
        File(logoPath).existsSync()) {
      logoUrl = await _uploadReportLogo(logoPath, user.id);
    }

    await client
        .from('perfis')
        .update({
          'report_brand_name': branding.brandName?.trim(),
          'report_logo_url': logoUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);

    return logoUrl;
  }

  Future<String> _uploadReportLogo(String localPath, String userId) async {
    final ext = localPath.contains('.') ? localPath.split('.').last : 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = '$userId/$fileName';

    await Supabase.instance.client.storage
        .from(_reportBrandingBucket)
        .upload(
          storagePath,
          File(localPath),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return Supabase.instance.client.storage
        .from(_reportBrandingBucket)
        .getPublicUrl(storagePath);
  }

  Future<void> _persistReportBrandingLocal(ReportBrandingState branding) async {
    final brandName = branding.brandName?.trim();
    if (brandName != null && brandName.isNotEmpty) {
      await _prefs.setString(_keyReportBrandName, brandName);
    } else {
      await _prefs.remove(_keyReportBrandName);
    }

    final logoPath = branding.logoPath?.trim();
    if (logoPath != null && logoPath.isNotEmpty) {
      await _prefs.setString(_keyReportLogoPath, logoPath);
    } else {
      await _prefs.remove(_keyReportLogoPath);
    }
  }

  Future<String?> _pickAndSaveImage(
    ImageSource source, {
    required String prefix,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(
      pickedFile.path,
    ).copy('${appDir.path}/$fileName');

    return savedImage.path;
  }

  Future<void> syncProfilePhoto(String localPath) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final ext = localPath.contains('.') ? localPath.split('.').last : 'jpg';
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = 'avatars/$fileName';

      await client.storage
          .from('avatars')
          .upload(
            storagePath,
            File(localPath),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = client.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      await client
          .from('perfis')
          .update({
            'photo_url': publicUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (e) {
      AppLogger.warning(
        'Erro ao sincronizar foto de perfil',
        tag: 'Settings',
        error: e,
      );
    }
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
    } catch (e) {
      AppLogger.warning(
        'Erro ao calcular espaço usado em disco',
        tag: 'Settings',
        error: e,
      );
    }
    return total;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
