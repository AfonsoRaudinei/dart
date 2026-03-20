import '../entities/categoria_global.dart';
import '../entities/cliente_categoria.dart';
import '../entities/carteira_safra.dart';
import '../entities/carteira_meta.dart';
import '../entities/carteira_lancamento.dart';

/// Interface do repositório de carteira.
///
/// Cobre: categorias, config global, safras, metas e lançamentos.
/// ADR-022 — SoloForte
abstract class ICarteiraRepository {
  // ── Categorias ──────────────────────────────────────────────────

  Future<List<CategoriaGlobal>> getCategorias(String userId);
  Future<void> saveCategoria(CategoriaGlobal categoria);
  Future<void> updateCategoria(CategoriaGlobal categoria);
  Future<void> desativarCategoria(String id);

  // ── ClienteCategoria (legado — retrocompat) ─────────────────────

  Future<List<ClienteCategoria>> getCategoriasDoCliente(
    String userId,
    String clienteId,
  );
  Future<List<ClienteCategoria>> getTodosRegistros(String userId);
  Future<void> upsertClienteCategoria(ClienteCategoria registro);
  Future<void> seedCategoriasIniciais(String userId);

  // ── Config global ───────────────────────────────────────────────

  Future<double> getValorGrao(String userId);
  Future<void> setValorGrao(String userId, double valor);

  // ── Safras ──────────────────────────────────────────────────────

  Future<List<CarteiraSafra>> getSafras(String userId);
  Future<CarteiraSafra?> getSafraAtiva(String userId);
  Future<void> saveSafra(CarteiraSafra safra);
  Future<void> ativarSafra(String safraId, String userId);

  // ── Metas ───────────────────────────────────────────────────────

  Future<List<CarteiraMeta>> getMetasBySafra(String safraId, String userId);
  Future<void> saveMeta(CarteiraMeta meta);
  Future<void> updateMeta(CarteiraMeta meta);

  // ── Lançamentos ─────────────────────────────────────────────────

  Future<List<CarteiraLancamento>> getLancamentos({
    required String userId,
    required String safraId,
    String? categoriaId,
    String? clienteId,
  });
  Future<void> saveLancamento(CarteiraLancamento lancamento);
  Future<void> deleteLancamento(String id, String userId);

  // ── Cálculos ────────────────────────────────────────────────────

  /// Soma de quantidade de todos os lançamentos de uma categoria numa safra.
  Future<double> getRealizadoBySafraCategoria(
    String safraId,
    String categoriaId,
    String userId,
  );

  /// Soma de quantidade dos lançamentos de um cliente, categoria e safra.
  Future<double> getRealizadoByClienteCategoriaSafra(
    String clienteId,
    String categoriaId,
    String safraId,
    String userId,
  );
}
