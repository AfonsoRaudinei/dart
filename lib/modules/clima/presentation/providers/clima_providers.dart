import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soloforte_app/core/contracts/i_user_location_lookup_provider.dart';
import 'package:soloforte_app/core/permissions/location_permission_gate.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

import 'package:soloforte_app/modules/clima/data/datasources/clima_local_datasource.dart';
import 'package:soloforte_app/modules/clima/data/datasources/google_weather_remote_datasource.dart';
import 'package:soloforte_app/modules/clima/data/datasources/openweather_remote_datasource.dart';
import 'package:soloforte_app/modules/clima/data/repositories/clima_repository_impl.dart';
import 'package:soloforte_app/modules/clima/domain/entities/alerta_meteorologico.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/domain/repositories/i_clima_repository.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

part 'clima_providers.g.dart';

// ─── Coordenada tipada ────────────────────────────────────────────────────────

typedef ClimaLatLon = ({double lat, double lon});

/// Brasília como fallback quando GPS não está disponível.
const ClimaLatLon _kDefaultLocation = (lat: -15.7801, lon: -47.9292);

// ─── Tab ─────────────────────────────────────────────────────────────────────

/// 0 = atual · 1 = 24h · 2 = 7 dias
final climaTabIndexProvider = StateProvider<int>((ref) => 0);

/// Unidade de temperatura preferida pelo usuário (persiste na sessão).
final climaUnidadeProvider =
    StateProvider<ClimaUnidade>((ref) => ClimaUnidade.celsius);

// ─── Repository ───────────────────────────────────────────────────────────────

@riverpod
IClimaRepository climaRepository(Ref ref) {
  return ClimaRepositoryImpl(
    remote: GoogleWeatherRemoteDatasource(
      fallback: OpenWeatherRemoteDatasource(),
    ),
    local: ClimaLocalDatasource(),
  );
}

// ─── Localização — estado de fallback ────────────────────────────────────────

/// Estado de fallback quando GPS falha no módulo clima.
enum ClimaLocationFallback {
  none, // Usando localização real (mapa ou GPS direto)
  userDenied, // Usuário negou permissão
  timeout, // GPS não respondeu a tempo
  unavailable, // Serviço GPS desabilitado
}

final climaLocationFallbackProvider = StateProvider<ClimaLocationFallback>(
  (ref) => ClimaLocationFallback.none,
);

/// Obtém coordenadas para o clima.
/// Prioridade 1: userPositionProvider (já populado pelo mapa).
/// Prioridade 2: GPS direto (usuário ainda não navegou no mapa).
/// Fallback: Brasília-DF com estado de erro exposto na UI.
@riverpod
Future<ClimaLatLon> climaLocation(Ref ref) async {
  // PASSO 1 — Tentar posição já conhecida pelo mapa
  final lookup = ref.watch(userLocationLookupProvider);
  final mapPosition = lookup.getUserLatLng();

  if (mapPosition != null) {
    AppLogger.debug('[CLIMA] Usando posição do mapa: $mapPosition',
        tag: 'ClimaLocation');
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.none;
    return (lat: mapPosition.latitude, lon: mapPosition.longitude);
  }

  // PASSO 2 — GPS direto (mapa ainda não foi aberto nesta sessão)
  AppLogger.debug('[CLIMA] Posição do mapa indisponível, tentando GPS direto…',
      tag: 'ClimaLocation');

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    AppLogger.warning('[CLIMA] Serviço GPS desabilitado — usando Brasília',
        tag: 'ClimaLocation');
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.unavailable;
    return _kDefaultLocation;
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await LocationPermissionGate.request();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    AppLogger.warning('[CLIMA] Permissão GPS negada — usando Brasília',
        tag: 'ClimaLocation');
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.userDenied;
    return _kDefaultLocation;
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    AppLogger.debug(
        '[CLIMA] GPS direto obtido: ${pos.latitude}, ${pos.longitude}',
        tag: 'ClimaLocation');
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.none;
    return (lat: pos.latitude, lon: pos.longitude);
  } on TimeoutException catch (e) {
    AppLogger.warning('[CLIMA] Timeout GPS — usando Brasília',
        tag: 'ClimaLocation', error: e);
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.timeout;
    return _kDefaultLocation;
  } catch (e) {
    AppLogger.warning('[CLIMA] Erro GPS não tratado — usando Brasília',
        tag: 'ClimaLocation', error: e);
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.unavailable;
    return _kDefaultLocation;
  }
}

// ─── Dados climáticos ─────────────────────────────────────────────────────────

@riverpod
Future<ClimaAtual> climaAtual(Ref ref) async {
  final loc = await ref.watch(climaLocationProvider.future);
  return ref.watch(climaRepositoryProvider).getClimaAtual(
    lat: loc.lat,
    lon: loc.lon,
  );
}

@riverpod
Future<List<PrevisaoHoraria>> previsaoHoraria(Ref ref) async {
  final loc = await ref.watch(climaLocationProvider.future);
  return ref.watch(climaRepositoryProvider).getPrevisaoHoraria(
    lat: loc.lat,
    lon: loc.lon,
  );
}

@riverpod
Future<List<PrevisaoDiaria>> previsaoSemanal(Ref ref) async {
  final loc = await ref.watch(climaLocationProvider.future);
  return ref.watch(climaRepositoryProvider).getPrevisaoSemanal(
    lat: loc.lat,
    lon: loc.lon,
  );
}

@riverpod
Future<List<AlertaMeteorologico>> alertasClima(Ref ref) async {
  final loc = await ref.watch(climaLocationProvider.future);
  return ref.watch(climaRepositoryProvider).getAlertas(
    lat: loc.lat,
    lon: loc.lon,
  );
}
