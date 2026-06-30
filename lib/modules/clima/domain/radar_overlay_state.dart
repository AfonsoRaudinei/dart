import 'entities/radar_fetch_result.dart';

enum ClimaRadarOverlayState {
  disabled,
  loading,
  active,
  noPrecipitation,
  unavailable,
  offline,
}

/// Mensagens de banner do overlay de radar (Fase 3 — UX diferenciada).
class ClimaRadarOverlayMessages {
  ClimaRadarOverlayMessages._();

  static const loading = 'Carregando radar…';
  static const activePrefix = 'Chuva ativa · atualizado';
  static const noPrecipitation =
      'Nenhuma precipitação detectada nesta região agora';
  static const unavailable = 'Radar temporariamente indisponível';
  static const offline = 'Conecte-se à internet para ver o radar';
}

ClimaRadarOverlayState resolveClimaRadarOverlayState({
  required bool enabled,
  required bool isOnline,
  required bool isLoading,
  ClimaRadarFetchResult? result,
}) {
  if (!enabled) return ClimaRadarOverlayState.disabled;
  if (!isOnline) return ClimaRadarOverlayState.offline;
  if (isLoading) return ClimaRadarOverlayState.loading;
  if (result == null) return ClimaRadarOverlayState.unavailable;
  if (result.hasFrames) return ClimaRadarOverlayState.active;
  if (result.status == ClimaRadarFetchStatus.emptyManifest) {
    return ClimaRadarOverlayState.noPrecipitation;
  }
  return ClimaRadarOverlayState.unavailable;
}

String climaRadarBannerMessage({
  required ClimaRadarOverlayState state,
  String activeAgeLabel = '',
}) {
  return switch (state) {
    ClimaRadarOverlayState.loading => ClimaRadarOverlayMessages.loading,
    ClimaRadarOverlayState.active =>
      '${ClimaRadarOverlayMessages.activePrefix} $activeAgeLabel'.trim(),
    ClimaRadarOverlayState.noPrecipitation =>
      ClimaRadarOverlayMessages.noPrecipitation,
    ClimaRadarOverlayState.offline => ClimaRadarOverlayMessages.offline,
    ClimaRadarOverlayState.unavailable =>
      ClimaRadarOverlayMessages.unavailable,
    ClimaRadarOverlayState.disabled => '',
  };
}
