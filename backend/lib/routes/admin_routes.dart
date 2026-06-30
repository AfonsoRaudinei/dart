import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../storage/feature_flag_storage.dart';

/// Routes administrativas para gerenciar feature flags (CRUD protegido).
class AdminRoutes {
  final FeatureFlagStorage _storage;

  AdminRoutes(this._storage);

  Router get router {
    final router = Router();

    // POST /flags - Criar nova flag
    router.post('/flags', _createFlag);

    // PUT /flags/<key> - Atualizar flag existente
    router.put('/flags/<key>', _updateFlag);

    // DELETE /flags/<key> - Deletar flag
    router.delete('/flags/<key>', _deleteFlag);

    // GET /flags - Listar todas (com metadados admin)
    router.get('/flags', _listFlags);

    return router;
  }

  /// POST /admin/flags
  Future<Response> _createFlag(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // Validação básica
      if (!data.containsKey('key') || !data.containsKey('enabled')) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing required fields: key, enabled'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Adicionar metadados
      data['created_at'] = DateTime.now().toIso8601String();
      data['version'] ??= 1;

      final success = await _storage.upsertFlag(data);

      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to create flag'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response(
        201,
        body: jsonEncode({'message': 'Flag created', 'flag': data}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Invalid request: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// PUT /admin/flags/<key>
  Future<Response> _updateFlag(Request request, String key) async {
    try {
      final existing = await _storage.getFlag(key);
      if (existing == null) {
        return Response.notFound(
          jsonEncode({'error': 'Flag not found: $key'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;

      // Mesclar com existente
      final updated = {...existing, ...updates};
      updated['key'] = key; // Garantir que key não muda
      updated['updated_at'] = DateTime.now().toIso8601String();
      updated['version'] = (updated['version'] as int? ?? 1) + 1;

      final success = await _storage.upsertFlag(updated);

      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to update flag'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'message': 'Flag updated', 'flag': updated}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Invalid request: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// DELETE /admin/flags/<key>
  Future<Response> _deleteFlag(Request request, String key) async {
    try {
      final success = await _storage.deleteFlag(key);

      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to delete flag'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'message': 'Flag deleted', 'key': key}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete flag: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /admin/flags
  Future<Response> _listFlags(Request request) async {
    try {
      final flags = await _storage.getAllFlags();

      return Response.ok(
        jsonEncode({
          'flags': flags,
          'total': flags.length,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to list flags: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
