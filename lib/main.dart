import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/sync_service.dart';
import 'core/session/session_storage.dart';
import 'modules/settings/data/settings_repository.dart';
import 'modules/settings/presentation/providers/settings_providers.dart';
import 'modules/settings/presentation/theme/app_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabaseConfig) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  await NotificationService().init();

  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final sessionStorage = SessionStorage(secureStorage);
  await sessionStorage.init(legacyPrefs: prefs);

  runApp(
    ProviderScope(
      overrides: [
        sessionStorageProvider.overrideWith((ref) => sessionStorage),
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(prefs)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AppBootstrap(child: SoloForteApp()),
    ),
  );
}

/// Mantém serviços de infraestrutura vivos sem alterar fluxos de negócio.
class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncServiceProvider);
    return child;
  }
}

class SoloForteApp extends ConsumerWidget {
  const SoloForteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'SoloForte',
      theme: AppThemes.getTheme(themeMode),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
