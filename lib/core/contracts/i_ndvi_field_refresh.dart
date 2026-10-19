/// Limpa cache NDVI local de um talhão e dispara novo fetch. ADR-045.
abstract interface class INdviFieldRefresh {
  Future<void> clearCacheAndReload(String fieldId);
}
