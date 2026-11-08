import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../modules/map/presentation/providers/map_location_mode_provider.dart';

/// Tempo em que N, S, L e O ficam visíveis ao entrar em norte travado.
const Duration kMapCardinalFlashDuration = Duration(seconds: 3);

/// Fade final, contido em [kMapCardinalFlashDuration].
const Duration kMapCardinalFlashFadeDuration = Duration(milliseconds: 400);

/// Abaixo dos toggles do topo (safe + 12 + botão 48) e do chip de município
/// (safe + 52 + pílula).
const double _kNorthTopBelowSafeArea = 96;

const double _kWestInset = 16;

const double _kEastGapFromActionColumn = 12;

const double _kEastRightInset =
    kMapActionColumnRightInset +
    kMapActionColumnButtonSize +
    _kEastGapFromActionColumn;

/// Letras N/S/L/O nas bordas do mapa, só na entrada de [MapLocationMode.northLocked].
///
/// Some sozinho. Não aparece em idle nem em following. [IgnorePointer] para
/// não roubar toque do mapa nem da coluna de ações.
class MapCardinalFlashOverlay extends ConsumerStatefulWidget {
  const MapCardinalFlashOverlay({super.key});

  @override
  ConsumerState<MapCardinalFlashOverlay> createState() =>
      _MapCardinalFlashOverlayState();
}

class _MapCardinalFlashOverlayState
    extends ConsumerState<MapCardinalFlashOverlay> {
  Timer? _fadeTimer;
  Timer? _hideTimer;
  bool _visible = false;
  bool _opaque = true;

  @override
  void initState() {
    super.initState();
    if (ref.read(mapLocationModeProvider) == MapLocationMode.northLocked) {
      _armFlash(rebuild: false);
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _fadeTimer?.cancel();
    _hideTimer?.cancel();
    _fadeTimer = null;
    _hideTimer = null;
  }

  void _armFlash({required bool rebuild}) {
    _cancelTimers();
    _visible = true;
    _opaque = true;
    _fadeTimer = Timer(
      kMapCardinalFlashDuration - kMapCardinalFlashFadeDuration,
      () {
        if (!mounted) return;
        setState(() => _opaque = false);
      },
    );
    _hideTimer = Timer(kMapCardinalFlashDuration, () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
    if (rebuild) setState(() {});
  }

  void _dismissFlash() {
    _cancelTimers();
    if (!_visible) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MapLocationMode>(mapLocationModeProvider, (previous, next) {
      if (next == MapLocationMode.northLocked &&
          previous != MapLocationMode.northLocked) {
        _armFlash(rebuild: true);
        return;
      }
      if (previous == MapLocationMode.northLocked &&
          next != MapLocationMode.northLocked) {
        _dismissFlash();
      }
    });

    if (!_visible) return const SizedBox.shrink();

    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _opaque ? 1 : 0,
          duration: kMapCardinalFlashFadeDuration,
          curve: Curves.easeOut,
          child: Stack(
            children: [
              Positioned(
                top: safeTop + _kNorthTopBelowSafeArea,
                left: 0,
                right: 0,
                child: const Center(
                  child: _CardinalPill('N', semanticsLabel: 'Norte'),
                ),
              ),
              Positioned(
                bottom: safeBottom + kFabSafeArea,
                left: 0,
                right: 0,
                child: const Center(
                  child: _CardinalPill('S', semanticsLabel: 'Sul'),
                ),
              ),
              const Positioned(
                right: _kEastRightInset,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _CardinalPill('L', semanticsLabel: 'Leste'),
                ),
              ),
              const Positioned(
                left: _kWestInset,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _CardinalPill('O', semanticsLabel: 'Oeste'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardinalPill extends StatelessWidget {
  const _CardinalPill(this.letter, {required this.semanticsLabel});

  final String letter;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
