import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

/// Implementação do repositório NDVI.
///
/// Estratégia:
/// 1. Verifica cache local (SQLite, validade 24h).
/// 2. Se cache válido → retorna sem chamada remota.
/// 3. Se cache inválido ou ausente → chama Edge Function.
/// 4. Em caso de falha remota → tenta retornar último cache (modo offline).
/// 5. Persiste novo dado remoto no cache antes de retornar.
class NdviRepositoryImpl implements INdviRepository {
  final NdviRemoteDatasource _remote;
  final NdviLocalDatasource _local;

  const NdviRepositoryImpl({
    required NdviRemoteDatasource remote,
    required NdviLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<NdviImage?> fetchNdvi({
    required String areaId,
    required List<double> bbox,
    DateTime? date,
    String source = 'auto',
  }) async {
    final dateStr = date != null
        ? '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}'
        : null;

    // ── 1. Verificar cache local ────────────────────────────────────────────
    if (dateStr != null) {
      final cached = await _local.get(areaId: areaId, date: dateStr);
      if (cached != null) return cached.toEntity();
    }

    // ── 2. Chamada remota ───────────────────────────────────────────────────
    final remoteModel = await _remote.fetchNdvi(
      areaId: areaId,
      bbox: bbox,
      date: dateStr,
      source: source,
    );

    if (remoteModel != null) {
      // ── 3. Persistir no cache ──────────────────────────────────────────
      final saved = await _local.save(remoteModel);
      return saved.toEntity();
    }

    // ── 4. Fallback offline: retorna último cache disponível ─────────────
    final fallback = await _local.getLatest(areaId);
    return fallback?.toEntity();
  }

  @override
  Future<NdviImage?> getCachedNdvi({
    required String areaId,
    required String date,
  }) async {
    final cached = await _local.get(areaId: areaId, date: date);
    return cached?.toEntity();
  }
}
