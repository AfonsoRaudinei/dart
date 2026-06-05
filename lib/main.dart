import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/contracts/i_client_lookup_provider.dart';
import 'core/contracts/i_agenda_ai_launcher_provider.dart';
import 'core/contracts/i_farm_lookup_provider.dart';
import 'core/contracts/i_visit_client_lookup_provider.dart';
import 'core/contracts/i_visit_session_lookup_provider.dart';
import 'core/contracts/i_active_visit_context_lookup_provider.dart';
import 'core/contracts/i_occurrence_read_provider.dart';
import 'core/contracts/i_agenda_session_bridge_provider.dart';
import 'core/contracts/i_field_lookup_provider.dart';
import 'core/contracts/i_field_lookup_geofence_provider.dart';
import 'core/contracts/i_opportunity_lookup_provider.dart';
import 'core/contracts/i_agenda_observable.dart';
import 'core/contracts/i_agenda_observable_provider.dart';
import 'core/contracts/i_report_writer_provider.dart';
import 'core/contracts/i_user_location_lookup_provider.dart';
import 'modules/dashboard/infra/location_lookup_adapter.dart';
import 'core/database/database_helper.dart';
import 'core/infra/preferences_service.dart';
import 'core/router/app_router.dart';
import 'core/services/sync_orchestrator.dart';
import 'core/utils/app_logger.dart';
import 'app/sync_registration.dart';
import 'modules/consultoria/clients/data/clients_repository.dart';
import 'modules/consultoria/clients/infra/client_lookup_adapter.dart';
import 'modules/consultoria/clients/infra/farm_lookup_adapter.dart';
import 'modules/consultoria/clients/infra/visit_client_lookup_adapter.dart';
import 'modules/consultoria/clients/infra/active_visit_context_lookup_adapter.dart';
import 'modules/consultoria/fields/data/repositories/field_repository.dart';
import 'modules/consultoria/fields/infra/field_lookup_geofence_adapter.dart';
import 'modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'modules/consultoria/occurrences/infra/occurrence_read_adapter.dart';
import 'modules/agenda/data/repositories/agenda_repository.dart';
import 'modules/agenda/infra/agenda_session_bridge_adapter.dart';
import 'modules/agenda/presentation/providers/agenda_provider.dart';
import 'modules/agenda_ai/infra/agenda_ai_launcher_adapter.dart';
import 'modules/consultoria/relatorios/infra/report_writer_adapter.dart';
import 'modules/carteira/data/opportunity_lookup_impl.dart';
import 'modules/carteira/data/repositories/carteira_repository_impl.dart';
import 'modules/visitas/data/repositories/visit_repository.dart';
import 'modules/visitas/infra/visit_session_lookup_adapter.dart';
import 'modules/drawing/infra/field_lookup_adapter.dart';
import 'modules/drawing/presentation/providers/drawing_provider.dart';
import 'modules/map/presentation/providers/visit_completion_observer.dart';
import 'modules/settings/data/settings_repository.dart';
import 'modules/settings/presentation/providers/settings_providers.dart';
import 'ui/theme/premium/premium_app_theme.dart';

Future<void> main() async {
  // ✅ ensureInitialized() dentro do runZonedGuarded resolve zone mismatch.
  // runZonedGuarded é iniciado ANTES do ensureInitialized para que
  // ambos estejam na mesma zona.
  await runZonedGuarded(
    () async {
      // 🔒 Binding inicializado dentro da zona — resolve zone mismatch
      WidgetsFlutterBinding.ensureInitialized();

      // 🛡 IPA-124: desabilitar download HTTP de fontes GoogleFonts.
      // Sem isso, o app tentava baixar a fonte Inter da internet no primeiro
      // frame — em rede lenta ou offline causava freeze de UI.
      // As fontes do sistema (San Francisco no iOS) são usadas como fallback.
      GoogleFonts.config.allowRuntimeFetching = false;

      // 🛡 Erros do framework Flutter exibidos em vez de tela preta
      FlutterError.onError = FlutterError.presentError;
      ErrorWidget.builder = (details) {
        final message = details.exceptionAsString();
        return _BootErrorApp(error: message);
      };

      // 🛡 IPA-109: mostra splash nativo imediatamente enquanto o boot
      // assíncrono acontece. Elimina o frame preto entre o LaunchScreen
      // nativo do iOS e o primeiro frame do Flutter.
      runApp(const _BootSplashApp());

      try {
        // 1. Validação fail-fast de variáveis de ambiente
        AppConfig.validate();

        // 2. Locale pt_BR para DateFormat
        await initializeDateFormatting('pt_BR', null);

        // 3. Supabase com timeout explícito
        // 🛡 IPA-109: timeout aumentado de 15s → 30s.
        // Em redes 4G/3G lentas 15s era insuficiente, causando queda
        // prematura no _BootErrorApp com tela de erro desnecessária.
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException(
            'Supabase demorou mais de 30s para inicializar. '
            'Verifique sua conexão.',
          ),
        );

        // 4. SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final preferencesService = PreferencesService(prefs);
        final clientsRepository = ClientsRepository();
        final fieldRepository = FieldRepository();
        final visitSessionLookup = VisitSessionLookupAdapter(VisitRepository());

        // 5. App principal
        runApp(
          ProviderScope(
            overrides: [
              preferencesServiceProvider.overrideWithValue(preferencesService),
              settingsRepositoryProvider.overrideWithValue(
                SettingsRepository(prefs),
              ),
              // ADR-015: implementação concreta de IClientLookup
              clientLookupProvider.overrideWithValue(
                ClientLookupAdapter(clientsRepository),
              ),
              agendaAiLauncherProvider.overrideWithValue(
                const AgendaAiLauncherAdapter(),
              ),
              opportunityLookupProvider.overrideWith((ref) {
                return OpportunityLookupImpl(
                  repository: CarteiraRepositoryImpl(),
                  db: DatabaseHelper.instance,
                );
              }),
              // Contrato de fazendas para módulos desacoplados (drawing/).
              iFarmLookupProvider.overrideWithValue(
                FarmLookupAdapter(clientsRepository),
              ),
              // ADR-020: implementação concreta de IVisitClientLookup
              visitClientLookupProvider.overrideWithValue(
                VisitClientLookupAdapter(clientsRepository, fieldRepository),
              ),
              // ADR-020: implementação concreta de IVisitSessionLookup
              visitSessionLookupProvider.overrideWithValue(visitSessionLookup),
              activeVisitContextLookupProvider.overrideWithValue(
                ActiveVisitContextLookupAdapter(
                  visitSessionLookup,
                  clientsRepository,
                  fieldRepository,
                ),
              ),
              // ADR-024: implementação concreta de IOccurrenceRead
              occurrenceReadProvider.overrideWithValue(
                OccurrenceReadAdapter(OccurrenceRepository()),
              ),
              // ADR-024: implementação concreta de IAgendaSessionBridge
              agendaSessionBridgeProvider.overrideWithValue(
                AgendaSessionBridgeAdapter(AgendaRepository()),
              ),
              // ADR-024: IFieldLookup para geofence_controller (consultoria/fields)
              iFieldLookupGeofenceProvider.overrideWithValue(
                FieldLookupGeofenceAdapter(fieldRepository),
              ),
              // ADR-022: IFieldLookup para NDVI via DrawingLocalStore.
              iFieldLookupProvider.overrideWith((ref) {
                return FieldLookupAdapter(ref.watch(drawingLocalStoreProvider));
              }),
              // ADR-025: AgendaObservableState neutro para visit_completion_observer
              agendaObservableProvider.overrideWith((ref) {
                final agendaState = ref.watch(agendaProvider);
                return AgendaObservableState(
                  sessions: agendaState.sessions
                      .map(
                        (s) => AgendaSessionData(
                          id: s.id,
                          startAtReal: s.startAtReal,
                          endAtReal: s.endAtReal,
                          createdBy: s.createdBy,
                        ),
                      )
                      .toList(),
                  events: agendaState.events
                      .map(
                        (e) => AgendaEventData(
                          id: e.id,
                          clienteId: e.clienteId,
                          visitSessionId: e.visitSessionId,
                          fazendaId: e.fazendaId,
                          talhaoId: e.talhaoId,
                        ),
                      )
                      .toList(),
                );
              }),
              // ADR-025: IReportWriter para visit_completion_observer (DT-025-7)
              reportWriterProvider.overrideWith(
                (ref) => ReportWriterAdapter(ref),
              ),
              // Contrato de localização do usuário para módulo clima/
              userLocationLookupProvider.overrideWith(
                (ref) => LocationLookupAdapter(ref),
              ),
            ],
            child: const SoloForteApp(),
          ),
        );
      } catch (error) {
        // 🛡 Qualquer falha no boot → tela de erro amigável
        // Nunca tela preta, nunca processo silencioso
        runApp(_BootErrorApp(error: error));
      }
    },
    (error, stack) {
      // 🛡 Erros assíncronos não capturados após o boot
      AppLogger.error(
        'Erro assíncrono não capturado após o boot',
        tag: 'Main',
        error: error,
        stackTrace: stack,
      );
      // Não chamar runApp aqui (zona diferente pode disparar "Zone mismatch").
      // O app já está renderizado; apenas registramos o erro global.
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
    // Inicializa VisitCompletionObserver (ADR-010): detecta conclusão de visita → gera RelatorioTecnico.
    // keepAlive: true garante que o listener persiste durante toda a sessão.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final orchestrator = ref.read(syncOrchestratorProvider);
        registerSyncModules(orchestrator);
        // 🛡 IPA-109: sync em background — não bloqueia o primeiro frame.
        // SyncPriority.immediate forçava as 31 migrações SQLite durante
        // a renderização inicial, causando tela preta (FALHA-1 removida).
        orchestrator.triggerSync(SyncPriority.background);
        ref.read(
          visitCompletionObserverProvider,
        ); // ADR-010: ativa listener agenda → relatorio
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'SoloForte',
      theme: PremiumAppTheme.themeFor(themeMode),
      darkTheme: PremiumAppTheme.darkTheme,
      themeMode: PremiumAppTheme.themeModeFor(themeMode),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Fallback para erro crítico durante build do router
      builder: (context, child) {
        if (child == null) {
          return const Scaffold(
            // 🛡 IPA-123: background branco explícito no fallback do builder
            backgroundColor: Colors.white,
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

/// Widget de splash exibido imediatamente no início do boot.
/// Elimina o frame preto entre o LaunchScreen nativo do iOS e o primeiro
/// frame do Flutter, enquanto Supabase/SharedPreferences inicializam.
/// Usa apenas recursos nativos (sem fontes/assets externos) para garantir
/// exibição correta em qualquer condição de build.
class _BootSplashApp extends StatelessWidget {
  const _BootSplashApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF34C759),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Carregando...',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 14,
                  fontFamily:
                      null, // fonte do sistema — sem dependência de assets
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de fallback exibido quando o boot falha.
/// Garante que o usuário veja uma mensagem clara em vez de tela preta.
class _BootErrorApp extends StatelessWidget {
  final Object error;
  const _BootErrorApp({required this.error});

  String get _friendlyMessage {
    final msg = error.toString();
    final lower = msg.toLowerCase();

    if (lower.contains('supabase_url') || lower.contains('supabase_anon_key')) {
      return 'Configuração incompleta.\nContate o suporte: suporte@soloforte.com';
    }
    if (lower.contains('timeout') || lower.contains('15s')) {
      return 'Servidor demorou para responder.\nVerifique sua conexão e tente novamente.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('host lookup')) {
      return 'Sem conexão com a internet.\nVerifique seu Wi-Fi ou dados móveis.';
    }
    if (lower.contains('certificate') || lower.contains('ssl')) {
      return 'Erro de segurança na conexão.\nContate o suporte: suporte@soloforte.com';
    }
    // Produção: mensagem genérica — não expor detalhes técnicos
    const isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      return 'Não foi possível inicializar o aplicativo.\nContate o suporte: suporte@soloforte.com';
    }
    // Debug: exibe o erro completo para o desenvolvedor
    return 'Erro de inicialização:\n\n$error';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // 🛡 IPA-109: fundo branco garante legibilidade mesmo se fontes
        // customizadas não forem embarcadas corretamente no bundle.
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: Color(0xFF888888),
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  // 🛡 fontFamily: null → usa fonte do sistema (San Francisco no iOS)
                  // garantindo que o texto seja exibido sem dependências de assets.
                  Text(
                    _friendlyMessage,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 15,
                      height: 1.6,
                      fontFamily: null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () {
                      // Hot restart não funciona em produção — orienta o usuário
                      // a fechar e reabrir o app manualmente
                    },
                    child: const Text(
                      'Feche e reabra o aplicativo',
                      style: TextStyle(
                        color: Color(0xFF34C759),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
