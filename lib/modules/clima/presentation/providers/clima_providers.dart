import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soloforte_app/core/config/clima_config.dart';
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

const _climaUnavailableMessage =
    'Previsão indisponível. Verifique sua conexão.';

class ClimaForecastUnavailableException implements Exception {
  const ClimaForecastUnavailableException();

  @override
  String toString() => _climaUnavailableMessage;
}

Future<T> _loadClimaData<T>(Future<T> Function() load) async {
  if (ClimaConfig.googleWeatherApiKey.isEmpty &&
      ClimaConfig.openWeatherApiKey.isEmpty) {
    debugPrint(
      '[Clima] GOOGLE_WEATHER_API_KEY e OPENWEATHER_API_KEY ausentes.',
    );
    throw const ClimaForecastUnavailableException();
  }

  try {
    return await load();
  } catch (e, stackTrace) {
    debugPrint('[Clima] Falha ao carregar previsão: $e');
    Error.throwWithStackTrace(
      const ClimaForecastUnavailableException(),
      stackTrace,
    );
  }
}

// ─── Coordenada tipada ────────────────────────────────────────────────────────

typedef ClimaLatLon = ({double lat, double lon});
typedef ClimaSelectedCity = ({String nome, double lat, double lon});

/// Brasília como fallback quando GPS não está disponível.
const ClimaLatLon _kDefaultLocation = (lat: -15.7801, lon: -47.9292);

const List<ClimaSelectedCity> climaCityOptions = [
  (nome: 'Fortaleza, CE', lat: -3.7319, lon: -38.5267),
  (nome: 'Brasília, DF', lat: -15.7801, lon: -47.9292),
  (nome: 'São Paulo, SP', lat: -23.5505, lon: -46.6333),
  (nome: 'Rio de Janeiro, RJ', lat: -22.9068, lon: -43.1729),
  (nome: 'Belo Horizonte, MG', lat: -19.9167, lon: -43.9345),
  (nome: 'Goiânia, GO', lat: -16.6869, lon: -49.2648),
  (nome: 'Palmas, TO', lat: -10.1840, lon: -48.3336),
  (nome: 'Porto Nacional, TO', lat: -10.7081, lon: -48.4172),
  (nome: 'Teresina, PI', lat: -5.0892, lon: -42.8019),
  (nome: 'São Luís, MA', lat: -2.5307, lon: -44.3068),
  (nome: 'Natal, RN', lat: -5.7945, lon: -35.2110),
  (nome: 'João Pessoa, PB', lat: -7.1195, lon: -34.8450),
  (nome: 'Recife, PE', lat: -8.0476, lon: -34.8770),
  (nome: 'Maceió, AL', lat: -9.6498, lon: -35.7089),
  (nome: 'Aracaju, SE', lat: -10.9472, lon: -37.0731),
  (nome: 'Salvador, BA', lat: -12.9777, lon: -38.5016),
];

// ─── Tab ─────────────────────────────────────────────────────────────────────

/// 0 = atual · 1 = 24h · 2 = 7 dias
final climaTabIndexProvider = StateProvider<int>((ref) => 0);

/// Unidade de temperatura preferida pelo usuário (persiste na sessão).
final climaUnidadeProvider = StateProvider<ClimaUnidade>(
  (ref) => ClimaUnidade.celsius,
);

/// Cidade escolhida manualmente pelo usuário.
final climaSelectedCityProvider = StateProvider<ClimaSelectedCity?>(
  (ref) => null,
);

/// Posição obtida explicitamente pelo botão "minha localização".
final climaManualLocationProvider = StateProvider<ClimaLatLon?>((ref) => null);

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
/// Prioridade 1: cidade escolhida manualmente.
/// Prioridade 2: posição obtida pelo botão "minha localização".
/// Prioridade 3: localização já conhecida pelo mapa.
/// Prioridade 4: GPS direto (usuário ainda não navegou no mapa).
/// Fallback: Brasília-DF com estado de erro exposto na UI.
@riverpod
Future<ClimaLatLon> climaLocation(Ref ref) async {
  final selectedCity = ref.watch(climaSelectedCityProvider);
  if (selectedCity != null) {
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.none;
    return (lat: selectedCity.lat, lon: selectedCity.lon);
  }

  final manualLocation = ref.watch(climaManualLocationProvider);
  if (manualLocation != null) {
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.none;
    return manualLocation;
  }

  // PASSO 1 — Tentar posição já conhecida pelo mapa
  final lookup = ref.watch(userLocationLookupProvider);
  final mapPosition = lookup.getUserLatLng();

  if (mapPosition != null) {
    AppLogger.debug(
      '[CLIMA] Usando posição do mapa: $mapPosition',
      tag: 'ClimaLocation',
    );
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.none;
    return (lat: mapPosition.latitude, lon: mapPosition.longitude);
  }

  // PASSO 2 — GPS direto (mapa ainda não foi aberto nesta sessão)
  AppLogger.debug(
    '[CLIMA] Posição do mapa indisponível, tentando GPS direto…',
    tag: 'ClimaLocation',
  );

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    AppLogger.warning(
      '[CLIMA] Serviço GPS desabilitado — usando Brasília',
      tag: 'ClimaLocation',
    );
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
    AppLogger.warning(
      '[CLIMA] Permissão GPS negada — usando Brasília',
      tag: 'ClimaLocation',
    );
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
      tag: 'ClimaLocation',
    );
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.none;
    return (lat: pos.latitude, lon: pos.longitude);
  } on TimeoutException catch (e) {
    AppLogger.warning(
      '[CLIMA] Timeout GPS — usando Brasília',
      tag: 'ClimaLocation',
      error: e,
    );
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.timeout;
    return _kDefaultLocation;
  } catch (e) {
    AppLogger.warning(
      '[CLIMA] Erro GPS não tratado — usando Brasília',
      tag: 'ClimaLocation',
      error: e,
    );
    ref.read(climaLocationFallbackProvider.notifier).state =
        ClimaLocationFallback.unavailable;
    return _kDefaultLocation;
  }
}

// ─── Dados climáticos ─────────────────────────────────────────────────────────

@riverpod
Future<ClimaAtual> climaAtual(Ref ref) async {
  final loc = await ref.watch(climaLocationProvider.future);
  return _loadClimaData(
    () => ref
        .watch(climaRepositoryProvider)
        .getClimaAtual(lat: loc.lat, lon: loc.lon),
  );
}

@riverpod
Future<List<PrevisaoHoraria>> previsaoHoraria(Ref ref) async {
  final loc = await ref.watch(climaLocationProvider.future);
  return _loadClimaData(
    () => ref
        .watch(climaRepositoryProvider)
        .getPrevisaoHoraria(lat: loc.lat, lon: loc.lon),
  );
}

@riverpod
Future<List<PrevisaoDiaria>> previsaoSemanal(Ref ref) async {
  final loc = await ref.watch(climaLocationProvider.future);
  return _loadClimaData(
    () => ref
        .watch(climaRepositoryProvider)
        .getPrevisaoSemanal(lat: loc.lat, lon: loc.lon),
  );
}

@riverpod
Future<List<AlertaMeteorologico>> alertasClima(Ref ref) async {
  final loc = await ref.watch(climaLocationProvider.future);
  return _loadClimaData(
    () => ref
        .watch(climaRepositoryProvider)
        .getAlertas(lat: loc.lat, lon: loc.lon),
  );
}
