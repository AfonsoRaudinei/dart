import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_geofence_provider.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/visitas/domain/visit_route_generator.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';

import 'widgets/map_mark_sheet.dart';

/// Abre a ficha para escolher quantas paradas gerar no talhão ativo.
Future<void> showVisitSuggestedRouteSheet(BuildContext context, WidgetRef ref) {
  final session = ref.read(visitControllerProvider).valueOrNull;
  final areaId = session?.areaId;
  if (areaId == null || areaId.isEmpty) return Future.value();
  return showSoloForteSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const VisitSuggestedRouteSheet(),
  );
}

/// Marca ocorrência na parada corrente e, ao salvar, avança a rota.
Future<void> registerOccurrenceAtCurrentStop(
  BuildContext context,
  WidgetRef ref,
) async {
  final stop = ref.read(visitControllerProvider).valueOrNull?.currentRouteStop;
  if (stop == null || !context.mounted) return;
  await MapMarkSheet.show(
    context: context,
    ref: ref,
    position: LatLng(stop.lat, stop.lng),
    onOccurrenceCreated: (occurrenceId) {
      return ref
          .read(visitControllerProvider.notifier)
          .completeCurrentStop(occurrenceId: occurrenceId);
    },
  );
}

class VisitSuggestedRouteSheet extends ConsumerStatefulWidget {
  const VisitSuggestedRouteSheet({super.key});

  @override
  ConsumerState<VisitSuggestedRouteSheet> createState() =>
      _VisitSuggestedRouteSheetState();
}

class _VisitSuggestedRouteSheetState
    extends ConsumerState<VisitSuggestedRouteSheet> {
  int _count = 5;
  bool _busy = false;
  String? _error;

  Future<void> _generate() async {
    final session = ref.read(visitControllerProvider).valueOrNull;
    final areaId = session?.areaId;
    if (areaId == null || areaId.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final field = await ref
          .read(iFieldLookupGeofenceProvider)
          .findById(areaId);
      final stops = const VisitRouteGenerator().generate(
        geometryJson: field?.geometry,
        stopCount: _count,
      );
      if (!mounted) return;
      if (stops.length != _count) {
        setState(() {
          _busy = false;
          _error = field?.geometry == null
              ? 'Este talhão não tem polígono no mapa.'
              : 'Não foi possível distribuir $_count paradas dentro deste talhão.';
        });
        return;
      }
      await ref
          .read(visitControllerProvider.notifier)
          .saveSuggestedRoute(stops);
      if (!mounted) return;
      unawaited(
        ref.read(visitRouteNotificationPortProvider).ensurePermission(),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Não foi possível gerar a rota agora.';
      });
    }
  }

  Future<void> _cancelRoute() async {
    setState(() => _busy = true);
    await ref.read(visitControllerProvider.notifier).clearSuggestedRoute();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final visuals = SoloForteSheetVisuals.of(context);
    final hasRoute =
        ref.watch(visitControllerProvider).valueOrNull?.routeStops.isNotEmpty ??
        false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16 + kFabSafeArea),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rota sugerida',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: visuals.titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quantas paradas neste talhão?',
            style: TextStyle(fontSize: 13, color: visuals.subtitleColor),
          ),
          const SizedBox(height: 12),
          Text(
            '$_count paradas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: visuals.titleColor,
            ),
          ),
          Slider(
            value: _count.toDouble(),
            min: VisitRouteGenerator.minStops.toDouble(),
            max: VisitRouteGenerator.maxStops.toDouble(),
            divisions:
                VisitRouteGenerator.maxStops - VisitRouteGenerator.minStops,
            label: '$_count',
            onChanged: _busy
                ? null
                : (value) {
                    final next = value.round();
                    if (next == _count) return;
                    HapticFeedback.selectionClick();
                    setState(() => _count = next);
                  },
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(fontSize: 13, color: visuals.subtitleColor),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _generate,
            style: FilledButton.styleFrom(
              backgroundColor: visuals.ctaBackground,
              foregroundColor: visuals.ctaText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visuals.ctaRadius),
              ),
            ),
            child: Text(_busy ? 'Gerando…' : 'Gerar'),
          ),
          if (hasRoute) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _cancelRoute,
              style: OutlinedButton.styleFrom(
                foregroundColor: visuals.ghostText,
                side: BorderSide(color: visuals.ghostBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(visuals.ghostRadius),
                ),
              ),
              child: const Text('Cancelar rota'),
            ),
          ],
        ],
      ),
    );
  }
}
