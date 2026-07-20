import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:soloforte_app/modules/settings/data/models/user_profile_audit_entry.dart';
import 'package:soloforte_app/modules/settings/data/settings_repository.dart';
import 'package:soloforte_app/modules/settings/domain/entities/user_profile.dart';
import 'package:soloforte_app/modules/settings/domain/repositories/i_user_profile_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/modules/settings/presentation/screens/edit_profile_screen.dart';
import 'package:soloforte_app/modules/settings/presentation/screens/settings_screen.dart';

class _FakeUserProfileRepository implements IUserProfileRepository {
  _FakeUserProfileRepository(this.currentProfile);

  UserProfile? currentProfile;
  int updateCalls = 0;
  UserProfile? lastUpdated;
  Map<String, String?>? lastChangedFields;
  bool throwOnGet = false;
  bool throwOnUpdate = false;

  @override
  Future<UserProfile?> getCurrentProfile() async {
    if (throwOnGet) throw Exception('falha ao carregar');
    return currentProfile;
  }

  @override
  Future<List<UserProfileAuditEntry>> getAuditTrail({int limit = 20}) async =>
      const [];

  @override
  Future<void> updateProfile({
    required UserProfile updated,
    required Map<String, String?> changedFields,
  }) async {
    updateCalls += 1;
    if (throwOnUpdate) throw Exception('falha controlada');
    lastUpdated = updated;
    lastChangedFields = Map<String, String?>.from(changedFields);
    currentProfile = updated;
  }
}

UserProfile _profile({
  String email = 'raudyneyb@gmail.com',
  String? fullName = 'Raudyney',
  String? phone = '63999999999',
  String? role = 'produtor',
  String? creaNumber,
}) {
  final now = DateTime(2026, 6, 17);
  return UserProfile(
    id: 'user-1',
    email: email,
    fullName: fullName,
    phone: phone,
    role: role,
    creaNumber: creaNumber,
    createdAt: now,
    updatedAt: now,
  );
}

GoRouter _router({required Widget settings}) => GoRouter(
  initialLocation: AppRoutes.settingsEditProfile,
  routes: [
    GoRoute(path: AppRoutes.settings, builder: (_, __) => settings),
    GoRoute(
      path: AppRoutes.settingsEditProfile,
      builder: (_, __) => const EditProfileScreen(),
    ),
  ],
);

Future<GoRouter> _pumpEditProfile(
  WidgetTester tester, {
  required _FakeUserProfileRepository repo,
  Widget settings = const Scaffold(body: Text('settings-route')),
  bool authenticated = true,
}) async {
  final router = _router(settings: settings);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileRepositoryProvider.overrideWith((ref) => repo),
        sessionControllerProvider.overrideWith(
          authenticated
              ? _AuthenticatedSessionController.new
              : _PublicSessionController.new,
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renderiza campos editaveis e email somente leitura', (
    tester,
  ) async {
    final repo = _FakeUserProfileRepository(_profile());
    await _pumpEditProfile(tester, repo: repo);

    expect(find.text('Editar Perfil'), findsOneWidget);
    expect(find.text('raudyneyb@gmail.com'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Raudyney'), findsOneWidget);
    expect(find.text('63999999999'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'raudyneyb@gmail.com'),
      findsNothing,
    );
    expect(find.text('CREA / CFT'), findsNothing);
  });

  testWidgets('exibe perfil inexistente sem criar formulario', (tester) async {
    final repo = _FakeUserProfileRepository(null);
    await _pumpEditProfile(tester, repo: repo, authenticated: false);

    expect(find.text('Usuário não autenticado.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('erro de carregamento permite tentar novamente', (tester) async {
    final repo = _FakeUserProfileRepository(_profile())..throwOnGet = true;
    await _pumpEditProfile(tester, repo: repo);

    expect(find.text('Não foi possível carregar o perfil.'), findsOneWidget);
    repo.throwOnGet = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Raudyney'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('salvar alteracao atualiza nome e telefone e retorna', (
    tester,
  ) async {
    final repo = _FakeUserProfileRepository(_profile());
    final router = await _pumpEditProfile(tester, repo: repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'Novo Nome');
    await tester.enterText(find.byType(TextFormField).at(1), '63911112222');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(repo.lastUpdated?.fullName, 'Novo Nome');
    expect(repo.lastUpdated?.phone, '63911112222');
    expect(repo.lastChangedFields, containsPair('fullName', 'Raudyney'));
    expect(repo.lastChangedFields, containsPair('phone', '63999999999'));
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.settings);
  });

  testWidgets('apagar nome e telefone persiste valores nulos', (tester) async {
    final repo = _FakeUserProfileRepository(_profile());
    await _pumpEditProfile(tester, repo: repo);

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), '');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(repo.lastUpdated?.fullName, isNull);
    expect(repo.lastUpdated?.phone, isNull);
    expect(repo.lastChangedFields, containsPair('fullName', 'Raudyney'));
    expect(repo.lastChangedFields, containsPair('phone', '63999999999'));
  });

  testWidgets('consultor pode editar e apagar CREA CFT', (tester) async {
    final repo = _FakeUserProfileRepository(
      _profile(role: 'consultor', creaNumber: 'CREA-123'),
    );
    await _pumpEditProfile(tester, repo: repo);

    expect(find.text('CREA / CFT'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).at(2), '');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(repo.lastUpdated?.creaNumber, isNull);
    expect(repo.lastChangedFields, containsPair('creaNumber', 'CREA-123'));
  });

  testWidgets('consultor pode substituir CREA CFT', (tester) async {
    final repo = _FakeUserProfileRepository(
      _profile(role: 'consultor', creaNumber: 'CREA-123'),
    );
    await _pumpEditProfile(tester, repo: repo);

    await tester.enterText(find.byType(TextFormField).at(2), 'CFT-456');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(repo.lastUpdated?.creaNumber, 'CFT-456');
    expect(repo.lastChangedFields, containsPair('creaNumber', 'CREA-123'));
  });

  testWidgets('salvar sem alteracoes nao chama repositorio e retorna', (
    tester,
  ) async {
    final repo = _FakeUserProfileRepository(_profile());
    final router = await _pumpEditProfile(tester, repo: repo);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 0);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.settings);
  });

  testWidgets('cancelar retorna para settings via GoRouter', (tester) async {
    final repo = _FakeUserProfileRepository(_profile());
    final router = await _pumpEditProfile(tester, repo: repo);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 0);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.settings);
  });

  testWidgets('erro ao salvar mantem tela aberta e valores digitados', (
    tester,
  ) async {
    final repo = _FakeUserProfileRepository(_profile())..throwOnUpdate = true;
    final router = await _pumpEditProfile(tester, repo: repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'Nome pendente');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.settingsEditProfile,
    );
    expect(find.text('Nome pendente'), findsOneWidget);
    expect(find.textContaining('Erro ao salvar perfil'), findsOneWidget);
  });

  testWidgets(
    'SettingsScreen abre rota e exibe perfil atualizado ao retornar',
    (tester) async {
      final repo = _FakeUserProfileRepository(_profile(fullName: 'Raudyney'));
      final prefs = await SharedPreferences.getInstance();
      late final GoRouter router;
      router = GoRouter(
        initialLocation: AppRoutes.settings,
        routes: [
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsEditProfile,
            builder: (_, __) => const EditProfileScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWith((ref) => repo),
            settingsRepositoryProvider.overrideWith(
              (ref) => SettingsRepository(prefs),
            ),
            sessionControllerProvider.overrideWith(
              _AuthenticatedSessionController.new,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final editButton = find.widgetWithText(OutlinedButton, 'Editar perfil');
      await tester.ensureVisible(editButton);
      await tester.pump(const Duration(milliseconds: 500));
      expect(editButton, findsOneWidget);
      router.go(AppRoutes.settingsEditProfile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.settingsEditProfile,
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Nome Atualizado',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.updateCalls, 1);
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.settings,
      );
      expect(find.text('Nome Atualizado'), findsWidgets);
    },
  );
}

class _AuthenticatedSessionController extends SessionController {
  @override
  SessionState build() => SessionAuthenticated(
    User.fromJson(const {
      'id': 'user-1',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{'role': 'produtor'},
      'aud': 'authenticated',
      'created_at': '2026-07-20T12:00:00.000Z',
      'email': 'raudyneyb@gmail.com',
    })!,
  );
}

class _PublicSessionController extends SessionController {
  @override
  SessionState build() => const SessionPublic();
}
