import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/session/session_storage.dart';
import 'modules/settings/data/settings_repository.dart';
import 'modules/settings/presentation/providers/settings_providers.dart';
import 'modules/settings/presentation/theme/app_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sessionStorageProvider.overrideWith((ref) => SessionStorage(prefs)),
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(prefs)),
      ],
      child: const SoloForteApp(),
    ),
  );
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
