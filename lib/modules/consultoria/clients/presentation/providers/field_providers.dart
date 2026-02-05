import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/modules/consultoria/fields/data/repositories/field_repository.dart';
import '../../domain/agronomic_models.dart';

// Repository Provider
final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  return FieldRepository();
});

// Selected Farm ID for Map Context
// This state should be managed by the UI (e.g., when user selects a farm)
final selectedFarmIdProvider = StateProvider<String?>((ref) => null);

// Fields for Selected Farm
final mapFieldsProvider = FutureProvider.autoDispose<List<Talhao>>((ref) async {
  final farmId = ref.watch(selectedFarmIdProvider);
  final repo = ref.read(fieldRepositoryProvider);

  if (farmId == null) {
    return repo.getAllFields();
  }

  return repo.getFieldsByFarmId(farmId);
});

// Selected Talhao ID on Map
final selectedTalhaoIdProvider = StateProvider<String?>((ref) => null);
