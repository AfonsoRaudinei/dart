import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/contracts/agenda_ai_recommendation_context.dart';
import '../../../../core/contracts/i_agenda_ai_launcher_provider.dart';
import '../../../../core/feature_flags/feature_flag_analytics.dart';
import '../../../../core/feature_flags/feature_flag_providers.dart';
import '../../../../core/feature_flags/feature_flag_resolver.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_models.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';

/// Único ponto de entrada do agente de agenda no app (mapa).
class MapAgendaAiButton extends ConsumerWidget {
  const MapAgendaAiButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sessão via provider (ADR-008): nunca tocar Supabase.instance no build —
    // quebra testes de widget e ignora o estado de bootstrap da sessão.
    final session = ref.watch(sessionControllerProvider);
    if (session is! SessionAuthenticated) {
      return const SizedBox.shrink();
    }
    final user = session.user;

    final role = user.userMetadata?['role']?.toString() ?? 'produtor';
    final ffUser = FeatureFlagUser(
      userId: user.id,
      role: role,
      appVersion: '1.1.0',
    );

    final enabledAsync = ref.watch(isAgendaAiEnabledProvider(ffUser));

    return enabledAsync.when(
      data: (enabled) {
        if (!enabled) return const SizedBox.shrink();
        return Tooltip(
          message: 'Agente de Visitas',
          child: GestureDetector(
            onTap: () => _openAgendaAi(context, ref, user.id),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/ia.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF34C759),
                    child: Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: 44, height: 44),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _openAgendaAi(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    HapticFeedback.selectionClick();

    final session = ref.read(sessionControllerProvider);
    final userRole = session is SessionAuthenticated
        ? (session.user.userMetadata?['role']?.toString() ?? 'produtor')
        : 'produtor';
    FeatureFlagAnalytics.trackAgendaAiAccess(
      userId: userId,
      userRole: userRole,
      wasEnabled: true,
    );
    FeatureFlagAnalytics.trackAgendaAiOpened(userId: userId);

    final launchContext = await _resolveLaunchContext(ref);

    if (!context.mounted) return;
    await ref.read(agendaAiLauncherProvider).showSheet(
          context,
          launchContext: launchContext,
        );
  }

  Future<AgendaAiLaunchContext?> _resolveLaunchContext(WidgetRef ref) async {
    final locationState = ref.read(locationStateProvider);
    if (locationState != LocationState.available) {
      return null;
    }

    LatLng? position = ref.read(locationStreamProvider).valueOrNull?.position;
    position ??= (await ref.read(initialLocationProvider.future))?.position;

    if (position == null) return null;

    return AgendaAiLaunchContext(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
