import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/fields/data/repositories/field_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

class _FakeFieldRepo extends FieldRepository {
  _FakeFieldRepo({required this.all, required this.byFarm});

  final List<Talhao> all;
  final List<Talhao> byFarm;
  var getAllCalls = 0;
  var getByFarmCalls = 0;

  @override
  Future<List<Talhao>> getAllFields() async {
    getAllCalls++;
    return all;
  }

  @override
  Future<List<Talhao>> getFieldsByFarmId(String farmId) async {
    getByFarmCalls++;
    return byFarm;
  }
}

void main() {
  test('produtor sem fazenda no mapa não chama getAllFields', () async {
    final repo = _FakeFieldRepo(
      all: [
        Talhao(
          id: 'leak',
          name: 'Confidencial',
          areaHa: 1,
          crop: '—',
          harvest: '—',
        ),
      ],
      byFarm: const [],
    );

    final container = ProviderContainer(
      overrides: [
        fieldRepositoryProvider.overrideWithValue(repo),
        currentUserRoleProvider.overrideWithValue(UserRole.produtor),
        selectedFarmIdProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final fields = await container.read(mapFieldsProvider.future);
    expect(fields, isEmpty);
    expect(repo.getAllCalls, 0);
    expect(repo.getByFarmCalls, 0);
  });

  test('produtor com fazenda selecionada usa só getFieldsByFarmId', () async {
    final repo = _FakeFieldRepo(
      all: [
        Talhao(
          id: 'leak',
          name: 'Confidencial',
          areaHa: 1,
          crop: '—',
          harvest: '—',
        ),
      ],
      byFarm: [
        Talhao(
          id: 'own',
          name: 'Meu talhão',
          areaHa: 2,
          crop: '—',
          harvest: '—',
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        fieldRepositoryProvider.overrideWithValue(repo),
        currentUserRoleProvider.overrideWithValue(UserRole.produtor),
        selectedFarmIdProvider.overrideWith((ref) => 'farm-own'),
      ],
    );
    addTearDown(container.dispose);

    final fields = await container.read(mapFieldsProvider.future);
    expect(fields, hasLength(1));
    expect(fields.first.id, 'own');
    expect(repo.getAllCalls, 0);
    expect(repo.getByFarmCalls, 1);
  });

  test('consultor sem fazenda ainda usa getAllFields', () async {
    final repo = _FakeFieldRepo(
      all: [
        Talhao(
          id: 'c1',
          name: 'Cliente A',
          areaHa: 1,
          crop: '—',
          harvest: '—',
        ),
      ],
      byFarm: const [],
    );

    final container = ProviderContainer(
      overrides: [
        fieldRepositoryProvider.overrideWithValue(repo),
        currentUserRoleProvider.overrideWithValue(UserRole.consultor),
        selectedFarmIdProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final fields = await container.read(mapFieldsProvider.future);
    expect(fields, hasLength(1));
    expect(repo.getAllCalls, 1);
  });
}
