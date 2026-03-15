import '../entities/categoria_global.dart';
import '../entities/cliente_categoria.dart';

abstract class ICarteiraRepository {
  Future<List<CategoriaGlobal>> getCategorias(String userId);
  Future<void> saveCategoria(CategoriaGlobal categoria);
  Future<void> updateCategoria(CategoriaGlobal categoria);
  Future<void> desativarCategoria(String id);

  Future<List<ClienteCategoria>> getCategoriasDoCliente(
    String userId,
    String clienteId,
  );
  Future<List<ClienteCategoria>> getTodosRegistros(String userId);
  Future<void> upsertClienteCategoria(ClienteCategoria registro);
  Future<void> seedCategoriasIniciais(String userId);
}
