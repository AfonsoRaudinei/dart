import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/settings_repository.dart';
import '../../domain/settings_models.dart';

// --- Repository Provider ---
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError(
    'settingsRepositoryProvider must be overridden in main.dart',
  );
});

// --- Profile Provider ---
class ProfileNotifier extends StateNotifier<ProfileState> {
  final SettingsRepository _repository;

  ProfileNotifier(this._repository) : super(const ProfileState()) {
    _load();
  }

  void _load() {
    state = _repository.loadProfile();
  }

  Future<void> updateImage(ImageSource source) async {
    final newPath = await _repository.pickAndSaveImage(source);
    if (newPath != null) {
      final newState = state.copyWith(imagePath: newPath);
      state = newState;
      await _repository.saveProfile(newState);
      await _repository.syncProfilePhoto(newPath);
    }
  }

  Future<void> toggleUseAsAppIcon(bool value) async {
    final newState = state.copyWith(useAsAppIcon: value);
    state = newState;
    await _repository.saveProfile(newState);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final repo = ref.watch(settingsRepositoryProvider);
  return ProfileNotifier(repo);
});

class ReportBrandingNotifier extends StateNotifier<ReportBrandingState> {
  final SettingsRepository _repository;

  ReportBrandingNotifier(this._repository)
    : super(const ReportBrandingState()) {
    _load();
    refreshRemote();
  }

  void _load() {
    state = _repository.loadReportBranding();
  }

  Future<void> updateBrandName(String? value) async {
    final normalized = value?.trim();
    final next = state.copyWith(
      brandName: normalized != null && normalized.isNotEmpty ? normalized : '',
    );
    state = next;
    state = await _repository.saveReportBranding(next);
  }

  Future<void> updateLogo(ImageSource source) async {
    final newPath = await _repository.pickAndSaveReportLogo(source);
    if (newPath == null) return;
    final next = state.copyWith(logoPath: newPath);
    state = next;
    state = await _repository.saveReportBranding(next);
  }

  Future<void> clearLogo() async {
    final next = state.copyWith(logoPath: '');
    state = next;
    state = await _repository.saveReportBranding(next);
  }

  Future<void> reset() async {
    state = const ReportBrandingState();
    state = await _repository.saveReportBranding(state);
  }

  Future<void> refreshRemote() async {
    final remote = await _repository.loadRemoteReportBranding();
    if (remote == null) return;
    state = remote;
  }
}

final reportBrandingProvider =
    StateNotifierProvider<ReportBrandingNotifier, ReportBrandingState>((ref) {
      final repo = ref.watch(settingsRepositoryProvider);
      return ReportBrandingNotifier(repo);
    });

// --- Theme Provider ---
class ThemeNotifier extends StateNotifier<String> {
  // 'green', 'blue', 'black'
  final SettingsRepository _repository;

  ThemeNotifier(this._repository) : super('green') {
    state = _repository.loadTheme();
  }

  Future<void> setTheme(String theme) async {
    state = theme;
    await _repository.saveTheme(theme);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return ThemeNotifier(repo);
});

// --- Storage Provider ---
final storageUsageProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getStorageUsage();
});
