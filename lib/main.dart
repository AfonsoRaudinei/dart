import 'dart:async';
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

  // Garante que erros no framework Flutter sejam visíveis em vez de tela preta.
  FlutterError.onError = FlutterError.presentError;

  // runZonedGuarded captura erros antes e depois do runApp.
  // Sem isso, um StateError em AppConfig.validate() mata o processo
  // silenciosamente e o iOS exibe tela preta sem nenhuma mensagem.
  await runZonedGuarded(
    () async {
      // Falha imediata e explícita se variáveis de ambiente não forem fornecidas.
      // Ver: lib/core/config/app_config.dart para instruções de uso.
      AppConfig.validate();

      // Timeout de 15s: Supabase v2 tenta recuperar sessão na rede durante
      // initialize(). Sem timeout, o iOS watchdog mata o processo (~20s)
      // antes de runApp() ser chamado, causando tela preta.
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          '[Supabase] initialize() excedeu 15s. Verifique a URL e a chave.',
        ),
      );

      // SharedPreferences inicializado uma única vez e injetado via Riverpod.
      // PreferencesService é o único ponto de acesso — sem getInstance() no app.
      final prefs = await SharedPreferences.getInstance();
      final preferencesService = PreferencesService(prefs);

      runApp(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
            settingsRepositoryProvider.overrideWithValue(
              SettingsRepository(prefs),
            ),
          ],
          child: const SoloForteApp(),
        ),
      );
    },
    (error, stack) {
      // Fallback visual: qualquer erro antes ou durante o boot é exibido
      // em vez de deixar o app preso na tela preta.
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erro de inicialização:\n\n$error',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class SoloForteApp extends ConsumerStatefulWidget {
  const SoloForteApp({super.key});

  @override
  ConsumerState<SoloForteApp> createState() => _SoloForteAppState();
}

class _SoloForteAppState extends ConsumerState<SoloForteApp> {
  @override
  void initState() {
    super.initState();
    // Inicializa SyncOrchestrator APÓS o primeiro frame para não bloquear renderização.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(syncOrchestratorProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'SoloForte',
      theme: AppThemes.getTheme(themeMode),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Fallback para erro crítico durante build do router
      builder: (context, child) {
        if (child == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Erro ao carregar aplicativo',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}
