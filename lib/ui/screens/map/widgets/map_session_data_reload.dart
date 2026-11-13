import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';

/// Relê desenhos e talhões quando a conta entra e quando o sync termina.
///
/// O pull do login grava no SQLite. A lista em memória do mapa não acompanha
/// sozinha. Desenhos com `user_id` vazio, feitos sem sessão, passam para a
/// conta que acabou de entrar.
class MapSessionDataReload extends ConsumerStatefulWidget {
  const MapSessionDataReload({super.key});

  @override
  ConsumerState<MapSessionDataReload> createState() =>
      _MapSessionDataReloadState();
}

class _MapSessionDataReloadState extends ConsumerState<MapSessionDataReload> {
  String? _adoptedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _adoptFor(ref.read(sessionControllerProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionControllerProvider, (previous, next) {
      _adoptFor(next);
    });
    ref.listen(syncOrchestratorProvider, (previous, next) {
      if (previous?.isSyncing == true && !next.isSyncing) {
        unawaited(_reloadMapData());
      }
    });
    return const SizedBox.shrink();
  }

  void _adoptFor(SessionState session) {
    if (session is! SessionAuthenticated) {
      _adoptedUserId = null;
      return;
    }
    final userId = session.user.id.trim();
    if (userId.isEmpty || userId == _adoptedUserId) return;
    _adoptedUserId = userId;
    unawaited(_claimAndReload(userId));
  }

  Future<void> _claimAndReload(String userId) async {
    try {
      await ref.read(drawingLocalStoreProvider).adoptOrphanDrawings(userId);
    } catch (error) {
      if (_adoptedUserId == userId) _adoptedUserId = null;
      AppLogger.warning(
        'Falha ao atribuir desenhos locais à conta',
        tag: 'MapSessionDataReload',
        error: error,
      );
      return;
    }
    if (!mounted || _adoptedUserId != userId) return;
    await _reloadMapData();
  }

  Future<void> _reloadMapData() async {
    if (!mounted) return;
    await ref.read(drawingControllerProvider).loadFeatures();
    if (!mounted) return;
    ref.invalidate(mapFieldsProvider);
  }
}
