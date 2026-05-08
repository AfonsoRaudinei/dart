import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado global efêmero indicando se MapController está pronto para uso.
///
/// Guard crítico: operações que dependem de _mapController.camera só podem
/// executar se este provider == true.
///
/// Ciclo de vida:
/// - false: inicial (MapController ainda não disponível)
/// - true: após FlutterMap onMapReady callback
/// - autoDispose: sim (reseta a cada saída/entrada do mapa)
///
/// Migração ADR-032 F1: substitui campo privado _isMapReady da _PrivateMapScreenState.
final mapReadyStateProvider = StateProvider.autoDispose<bool>((ref) => false);
