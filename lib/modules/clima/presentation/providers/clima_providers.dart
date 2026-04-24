import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soloforte_app/core/permissions/location_permission_gate.dart';

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

// ─── Localização ─────────────────────────────────────────────────────────────

/// Obtém coordenadas via GPS. Retorna Brasília como fallback.
@riverpod
Future<ClimaLatLon> climaLocation(Ref ref) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return _kDefaultLocation;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await LocationPermissionGate.request();
    if (permission == LocationPermission.denied) return _kDefaultLocation;
  }
  if (permission == LocationPermission.deniedForever) return _kDefaultLocation;

  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 25),
      ),
    );
    return (lat: pos.latitude, lon: pos.longitude);
  } catch (_) {
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
