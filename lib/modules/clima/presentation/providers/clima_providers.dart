import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soloforte_app/core/config/clima_config.dart';
import 'package:soloforte_app/core/contracts/i_user_location_lookup_provider.dart';
import 'package:soloforte_app/core/permissions/location_permission_gate.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';

import 'package:soloforte_app/modules/clima/data/datasources/clima_local_datasource.dart';
import 'package:soloforte_app/modules/clima/data/datasources/google_weather_remote_datasource.dart';
import 'package:soloforte_app/modules/clima/data/datasources/openweather_remote_datasource.dart';
import 'package:soloforte_app/modules/clima/data/repositories/clima_repository_impl.dart';
import 'package:soloforte_app/modules/clima/domain/entities/alerta_meteorologico.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/domain/repositories/i_clima_repository.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

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
    AppLogger.warning(
      'GOOGLE_WEATHER_API_KEY e OPENWEATHER_API_KEY ausentes.',
      tag: 'Clima',
    );
    throw const ClimaForecastUnavailableException();
  }

  try {
    return await load();
  } catch (e, stackTrace) {
    AppLogger.error('Falha ao carregar previsão', tag: 'Clima', error: e);
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

const String kClimaSelectedCityPrefsKey = 'clima_selected_city_v1';

// ─── Tab ─────────────────────────────────────────────────────────────────────

/// 0 = atual · 1 = 24h · 2 = 7 dias
final climaTabIndexProvider = StateProvider<int>((ref) => 0);

/// Unidade de temperatura preferida pelo usuário (persiste na sessão).
final climaUnidadeProvider = StateProvider<ClimaUnidade>(
  (ref) => ClimaUnidade.celsius,
);

/// Cidade escolhida manualmente (IBGE) — persistida em SharedPreferences.
class ClimaSelectedCityController extends StateNotifier<ClimaSelectedCity?> {
  ClimaSelectedCityController(this._prefs) : super(_loadFromPrefs(_prefs));

  final PreferencesService _prefs;

  static ClimaSelectedCity? _loadFromPrefs(PreferencesService prefs) {
    final raw = prefs.getString(kClimaSelectedCityPrefsKey);
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    final lat = double.tryParse(parts[1]);
    final lon = double.tryParse(parts[2]);
    if (lat == null || lon == null) return null;
    return (nome: parts[0], lat: lat, lon: lon);
  }

  Future<void> select(ClimaSelectedCity city) async {
    state = city;
    await _prefs.setString(
      kClimaSelectedCityPrefsKey,
      '${city.nome}|${city.lat}|${city.lon}',
    );
  }

  Future<void> clear() async {
    state = null;
    await _prefs.remove(kClimaSelectedCityPrefsKey);
  }
}

final climaSelectedCityProvider =
    StateNotifierProvider<ClimaSelectedCityController, ClimaSelectedCity?>(
  (ref) => ClimaSelectedCityController(ref.watch(preferencesServiceProvider)),
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
