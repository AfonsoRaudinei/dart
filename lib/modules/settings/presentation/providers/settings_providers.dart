import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/settings_repository.dart';
import '../../domain/settings_models.dart';

class AccountProfileData {
  final String name;
  final String email;
  final String phone;
  final String role;

  const AccountProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });
}

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

final accountProfileProvider =
    FutureProvider.autoDispose<AccountProfileData>((ref) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return const AccountProfileData(
          name: 'Não informado',
          email: 'Não informado',
          phone: 'Não informado',
          role: 'Não informado',
        );
      }

      final email = (user.email ?? '').trim();
      String name =
          (user.userMetadata?['full_name']?.toString() ?? '').trim();
      String phone = (user.userMetadata?['phone']?.toString() ?? '').trim();
      String role = (user.userMetadata?['role']?.toString() ?? '').trim();

      try {
        final profile = await Supabase.instance.client
            .from('perfis')
            .select('name, phone, role')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          name = ((profile['name'] as String?) ?? name).trim();
          phone = ((profile['phone'] as String?) ?? phone).trim();
          role = ((profile['role'] as String?) ?? role).trim();
        }
      } catch (_) {
        // Ambientes legados podem não ter coluna `phone` em `perfis`.
        try {
          final profile = await Supabase.instance.client
              .from('perfis')
              .select('name, role')
              .eq('id', user.id)
              .maybeSingle();

          if (profile != null) {
            name = ((profile['name'] as String?) ?? name).trim();
            role = ((profile['role'] as String?) ?? role).trim();
          }
        } catch (_) {
          // manter fallback do auth metadata
        }
      }

      return AccountProfileData(
        name: name.isEmpty ? 'Não informado' : name,
        email: email.isEmpty ? 'Não informado' : email,
        phone: phone.isEmpty ? 'Não informado' : phone,
        role: role.isEmpty ? 'Não informado' : role,
      );
    });
