import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/i_marketing_pin_repository.dart';
import '../../data/repositories/marketing_pin_repository_impl.dart';
import '../../data/services/marketing_pin_sync_service.dart';
import '../../domain/models/marketing_pin.dart';

// Repositório que acessa dados diretamente (ou pelo Supabase, ou sqlite)
final marketingPinRepositoryProvider = Provider<IMarketingPinRepository>((ref) {
  return MarketingPinRepositoryImpl(Supabase.instance.client);
});

// Serviço responsável pelo sincronismo (fetch -> decodifica -> cache SQLite)
final marketingPinSyncServiceProvider = Provider<MarketingPinSyncService>((
  ref,
) {
  final repository = ref.watch(marketingPinRepositoryProvider);
  return MarketingPinSyncService(repository);
});

// Provider consumido que fornece a lista de pins em si, mantendo o estado vivo em memória
final marketingPinsProvider = FutureProvider.autoDispose<List<MarketingPin>>((
  ref,
) async {
  // KeepAlive para que os pins permaneçam mesmo trafegando por rotas/modulos Splash -> Dashboard -> Map
  ref.keepAlive();

  final syncService = ref.watch(marketingPinSyncServiceProvider);

  // Tenta um fetch manual no repository primeiro para dados atualizados
  final repo = ref.read(marketingPinRepositoryProvider);
  try {
    final fresh = await repo.fetchMarketingPins();
    await repo.clearCache();
    await repo.saveToCache(fresh);
    return fresh;
  } catch (e) {
    debugPrint("Voltando a origem do cache de pin: $e");
    return syncService.getPins();
  }
});
