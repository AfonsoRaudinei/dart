import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/modules/clima/domain/entities/alerta_meteorologico.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_current_widgets.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_forecast_widgets.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_settings_sheet.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_shared_widgets.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Root Screen ──────────────────────────────────────────────────────────────

class ClimaScreen extends ConsumerWidget {
  const ClimaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(climaTabIndexProvider);

    return Scaffold(
      backgroundColor: kClimaBg,
      body: SafeArea(
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
        // ── Título grande (Large Title iOS) ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Clima',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.37,
                    color: kClimaTextPrimary,
                  ),
                ),
                Row(
                  children: [
                    ClimaIconBtn(
                      icon: Icons.my_location_outlined,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.invalidate(climaLocationProvider);
                        ref.invalidate(climaAtualProvider);
                        ref.invalidate(alertasClimaProvider);
                      },
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
        ),

        // ── Dados principais ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: climaAsync.when(
            data: (ClimaAtual clima) => Column(
              children: [
                ClimaLocationRow(
                  cidade: clima.cidade,
                  atualizadoEm: clima.atualizadoEm,
                ),
                ClimaCurrentWeatherCard(clima: clima, unidade: unidade),
                ClimaDetailsCard(clima: clima),
              ],
            ),
            loading: () => const ClimaLoadingCenter(),
            error: (e, _) => ClimaErrorState(message: e.toString()),
          ),
        ),

        // ── Alertas ───────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: alertasAsync.when(
            data: (List<AlertaMeteorologico> alertas) {
              final ativos = alertas.where((a) => a.ativo).toList();
              return ativos.isEmpty
                  ? const SizedBox.shrink()
                  : ClimaAlertasBanner(alertas: ativos);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        // ── Tab chips ─────────────────────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: ClimaTabChips(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: kFabSafeArea)),
      ],
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
          child: ClimaSubViewHeader(
            title: 'Próximas 24 Horas',
            onBack: () => ref.read(climaTabIndexProvider.notifier).state = 0,
          ),
        ),
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
          child: ClimaSubViewHeader(
            title: 'Previsão Semanal',
            onBack: () => ref.read(climaTabIndexProvider.notifier).state = 0,
          ),
        ),
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

