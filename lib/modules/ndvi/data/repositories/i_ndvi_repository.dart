import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

/// Contrato do repositório NDVI.
///
/// Implementação: [NdviRepositoryImpl].
/// Dependências: [NdviRemoteDatasource] + [NdviLocalDatasource].
abstract class INdviRepository {
  /// Retorna imagem NDVI para [areaId] e [bbox].
  ///
  /// - [date] null → imagem mais recente disponível.
  /// - Estratégia: verifica cache local (< 24h); se inválido busca remoto e
  ///   persiste no cache.
  Future<NdviImage?> fetchNdvi({
    required String areaId,
    required List<double> bbox,
    DateTime? date,
    String source,
  });

  /// Retorna entrada do cache local para [areaId] e [date], se existir.
  Future<NdviImage?> getCachedNdvi({
    required String areaId,
    required String date,
  });
}
