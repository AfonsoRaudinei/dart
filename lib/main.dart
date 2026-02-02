import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/session/session_storage.dart';
import 'ui/theme/soloforte_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sessionStorageProvider.overrideWith((ref) => SessionStorage(prefs)),
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

    return MaterialApp.router(
      title: 'SoloForte',
      theme: SoloForteTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
