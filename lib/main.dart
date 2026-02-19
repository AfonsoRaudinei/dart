import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/infra/preferences_service.dart';
import 'core/router/app_router.dart';
import 'core/services/sync_orchestrator.dart';
import 'modules/settings/data/settings_repository.dart';
import 'modules/settings/presentation/providers/settings_providers.dart';
import 'modules/settings/presentation/theme/app_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Falha imediata e explícita se variáveis de ambiente não forem fornecidas.
  // Ver: lib/core/config/app_config.dart para instruções de uso.
  AppConfig.validate();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // SharedPreferences inicializado uma única vez e injetado via Riverpod.
  // PreferencesService é o único ponto de acesso — sem getInstance() no app.
  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
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

    ref.read(syncOrchestratorProvider);

    return MaterialApp.router(
      title: 'SoloForte',
      theme: AppThemes.getTheme(themeMode),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
