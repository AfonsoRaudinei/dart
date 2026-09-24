import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_radar_overlay_controller_provider.dart';
import 'package:soloforte_app/core/permissions/location_permission_gate.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/clima/domain/entities/alerta_meteorologico.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_current_widgets.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_forecast_widgets.dart';
import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_city_selection_sheet.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_settings_sheet.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_shared_widgets.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Root Screen ──────────────────────────────────────────────────────────────

class ClimaScreen extends ConsumerWidget {
  const ClimaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(climaTabIndexProvider);
    final fallback = ref.watch(climaLocationFallbackProvider);

    return Scaffold(
      backgroundColor: context.climaBg,
      body: SafeArea(
        child: Column(
          children: [
            if (fallback != ClimaLocationFallback.none)
              _ClimaFallbackBanner(state: fallback),
            const _ClimaChrome(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: switch (tab) {
                  1 => const _HoraryView(key: ValueKey('horaria')),
                  2 => const _WeeklyView(key: ValueKey('semanal')),
                  _ => const _CurrentView(key: ValueKey('atual')),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chrome persistente (título, cidade, toggle) ──────────────────────────────

class _ClimaChrome extends ConsumerWidget {
  const _ClimaChrome();

  Future<void> _refreshCurrentLocation(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    await ref.read(climaSelectedCityProvider.notifier).clear();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ref.read(climaManualLocationProvider.notifier).state = null;
      ref.read(climaLocationFallbackProvider.notifier).state =
          ClimaLocationFallback.unavailable;
      _invalidateWeather(ref);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await LocationPermissionGate.request();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ref.read(climaManualLocationProvider.notifier).state = null;
      ref.read(climaLocationFallbackProvider.notifier).state =
          ClimaLocationFallback.userDenied;
      _invalidateWeather(ref);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      ref.read(climaManualLocationProvider.notifier).state = (
        lat: position.latitude,
        lon: position.longitude,
      );
      ref.read(climaLocationFallbackProvider.notifier).state =
          ClimaLocationFallback.none;
    } on TimeoutException {
      ref.read(climaManualLocationProvider.notifier).state = null;
      ref.read(climaLocationFallbackProvider.notifier).state =
          ClimaLocationFallback.timeout;
    } catch (_) {
      ref.read(climaManualLocationProvider.notifier).state = null;
      ref.read(climaLocationFallbackProvider.notifier).state =
          ClimaLocationFallback.unavailable;
    }

    _invalidateWeather(ref);
  }

  void _invalidateWeather(WidgetRef ref) {
    ref.invalidate(climaLocationProvider);
    ref.invalidate(climaAtualProvider);
    ref.invalidate(alertasClimaProvider);
    ref.invalidate(previsaoHorariaProvider);
    ref.invalidate(previsaoSemanalProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(climaTabIndexProvider);
    final climaAsync = ref.watch(climaAtualProvider);
    final horariaAsync = ref.watch(previsaoHorariaProvider);
    final semanalAsync = ref.watch(previsaoSemanalProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clima',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.37,
                  color: context.climaTextPrimary,
                ),
              ),
              Row(
                children: [
                  ClimaIconBtn(
                    icon: Icons.my_location_outlined,
                    onTap: () => _refreshCurrentLocation(ref),
                  ),
                  const SizedBox(width: 8),
                  ClimaIconBtn(
                    icon: Icons.tune_outlined,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showClimaSettings(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: climaAsync.when(
            data: (ClimaAtual clima) => Row(
              children: [
                Expanded(
                  child: ClimaLocationRow(
                    cidade: clima.cidade,
                    atualizadoEm: clima.atualizadoEm,
                    padding: EdgeInsets.zero,
                    onTap: () => showClimaCitySelection(context, ref),
                  ),
                ),
                const SizedBox(width: 10),
                _shareButton(
                  tab: tab,
                  clima: clima,
                  horaria: horariaAsync,
                  semanal: semanalAsync,
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        // Toggle persistente: Agora | 24h | 7 dias (sem emoji; sem chips no rodapé).
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: ClimaPeriodToggle(),
        ),
      ],
    );
  }

  Widget _shareButton({
    required int tab,
    required ClimaAtual clima,
    required AsyncValue<List<PrevisaoHoraria>> horaria,
    required AsyncValue<List<PrevisaoDiaria>> semanal,
  }) {
    final semanalData = semanal.asData?.value ?? const <PrevisaoDiaria>[];
    return switch (tab) {
      1 => horaria.maybeWhen(
        data: (previsoes) => ClimaShareButton(
          payload: ClimaSharePayloadHoraria(
            cidadeLabel: clima.cidade,
            previsoes: previsoes.take(24).toList(),
            fonte: clima.fonte,
            contextoSemanal: semanalData,
          ),
        ),
        orElse: () => const SizedBox(width: 44, height: 44),
      ),
      2 => semanal.maybeWhen(
        data: (previsoes) => ClimaShareButton(
          payload: ClimaSharePayloadSemanal(
            cidadeLabel: clima.cidade,
            previsoes: previsoes,
            fonte: clima.fonte,
          ),
        ),
        orElse: () => const SizedBox(width: 44, height: 44),
      ),
      _ => ClimaShareButton(
        payload: ClimaSharePayloadAtual(
          clima,
          contextoSemanal: semanalData,
        ),
      ),
    };
  }
}

// ─── Fallback Banner ──────────────────────────────────────────────────────────
class _ClimaFallbackBanner extends StatelessWidget {
  const _ClimaFallbackBanner({required this.state});

  final ClimaLocationFallback state;

  @override
  Widget build(BuildContext context) {
    final (String message, IconData icon, Color color) = switch (state) {
      ClimaLocationFallback.userDenied => (
        'Permissão de localização negada. Exibindo Brasília-DF.',
        Icons.location_off_outlined,
        Colors.orange,
      ),
      ClimaLocationFallback.timeout => (
        'GPS não respondeu. Exibindo Brasília-DF.',
        Icons.access_time_outlined,
        Colors.amber,
      ),
      ClimaLocationFallback.unavailable => (
        'GPS desabilitado. Exibindo Brasília-DF.',
        Icons.gps_off_outlined,
        Colors.redAccent,
      ),
      ClimaLocationFallback.none => ('', Icons.check, Colors.transparent),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Current View ─────────────────────────────────────────────────────────────

class _CurrentView extends ConsumerWidget {
  const _CurrentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final climaAsync = ref.watch(climaAtualProvider);
    final alertasAsync = ref.watch(alertasClimaProvider);
    final unidade = ref.watch(climaUnidadeProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: climaAsync.when(
            data: (ClimaAtual clima) => Column(
              children: [
                ClimaCurrentWeatherCard(clima: clima, unidade: unidade),
                alertasAsync.when(
                  data: (List<AlertaMeteorologico> alertas) {
                    final ativos = alertas.where((a) => a.ativo).toList();
                    return ativos.isEmpty
                        ? const SizedBox.shrink()
                        : ClimaAlertasBanner(alertas: ativos);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                ClimaDetailsCard(clima: clima),
                const _ClimaMapRadarButton(),
              ],
            ),
            loading: () => const ClimaLoadingCenter(),
            error: (e, _) => ClimaErrorState(message: e.toString()),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: kFabSafeArea)),
      ],
    );
  }
}

class _ClimaMapRadarButton extends ConsumerWidget {
  const _ClimaMapRadarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: context.climaTint,
            side: BorderSide(color: context.climaDivider),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(radarOverlayControllerProvider).setEnabled(
              true,
              preferSatelliteLayer: true,
            );
            context.go(AppRoutes.map);
          },
          icon: const Icon(Icons.map_outlined, size: 20),
          label: const Text(
            'Ver chuva no mapa',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ─── 24h View ─────────────────────────────────────────────────────────────────

class _HoraryView extends ConsumerWidget {
  const _HoraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previsaoAsync = ref.watch(previsaoHorariaProvider);
    final unidade = ref.watch(climaUnidadeProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: previsaoAsync.when(
            data: (p) => ClimaHoraryContent(
              previsoes: p.take(24).toList(),
              unidade: unidade,
            ),
            loading: () => const ClimaLoadingCenter(),
            error: (e, _) => ClimaErrorState(message: e.toString()),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: kFabSafeArea)),
      ],
    );
  }
}

// ─── 7 Dias View ──────────────────────────────────────────────────────────────

class _WeeklyView extends ConsumerWidget {
  const _WeeklyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previsaoAsync = ref.watch(previsaoSemanalProvider);
    final unidade = ref.watch(climaUnidadeProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: previsaoAsync.when(
            data: (p) => ClimaWeeklyContent(previsoes: p, unidade: unidade),
            loading: () => const ClimaLoadingCenter(),
            error: (e, _) => ClimaErrorState(message: e.toString()),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: kFabSafeArea)),
      ],
    );
  }
}
