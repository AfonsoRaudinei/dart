import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feature_flag_model.dart';
import 'feature_flag_resolver.dart';
import 'feature_flag_service.dart';
import 'feature_flag_backend_adapter.dart';

/// Provider para SharedPreferences (singleton)
final sharedPreferencesProvider = Provider<Future<SharedPreferences>>((ref) {
  return SharedPreferences.getInstance();
});

/// Provider para FeatureFlagBackendAdapter
final featureFlagBackendProvider = Provider<FeatureFlagBackendAdapter>((ref) {
  return FeatureFlagBackendAdapter();
});

/// Provider para FeatureFlagService
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  final backend = ref.watch(featureFlagBackendProvider);
  
  return FeatureFlagService(
    fetchFromBackend: backend.fetchFlags,
    getPreferences: () => SharedPreferences.getInstance(),
  );
});

/// Provider para FeatureFlagResolver (stateless)
final featureFlagResolverProvider = Provider<FeatureFlagResolver>((ref) {
  return const FeatureFlagResolver();
});

/// Provider para a flag drawing_v1 (reativo)
final drawingFlagProvider = FutureProvider<FeatureFlag>((ref) async {
  final service = ref.watch(featureFlagServiceProvider);
  return service.getDrawingFlag();
});

/// Provider para verificar se Drawing está habilitado para usuário atual
/// 
/// Parâmetros necessários via family:
/// - userId: ID do usuário
/// - role: Papel do usuário ('consultor' | 'produtor')
final isDrawingEnabledProvider = FutureProvider.family<bool, FeatureFlagUser>(
  (ref, user) async {
    final flag = await ref.watch(drawingFlagProvider.future);
    final resolver = ref.watch(featureFlagResolverProvider);
    
    return resolver.isDrawingEnabled(flag, user);
  },
);

/// Provider para iniciar background updates do FeatureFlagService
/// 
/// Deve ser iniciado no main() ou na raiz do app.
final featureFlagBackgroundUpdatesProvider = Provider<void>((ref) {
  final service = ref.watch(featureFlagServiceProvider);
  
  // Iniciar background updates
  service.startBackgroundUpdates();
  
  // Cleanup quando provider for disposed
  ref.onDispose(() {
    service.stopBackgroundUpdates();
  });
});
