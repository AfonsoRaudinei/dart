import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../storage/feature_flag_storage.dart';

/// Routes públicas para leitura de feature flags (app clients).
class FeatureFlagRoutes {
  final FeatureFlagStorage _storage;

  FeatureFlagRoutes(this._storage);

  Router get router {
    final router = Router();

    // GET /feature-flags - Retorna todas as flags
    router.get('/feature-flags', _getAllFlags);

    // GET /feature-flags/<key> - Retorna flag específica
    router.get('/feature-flags/<key>', _getFlag);

    return router;
  }

  /// GET /api/feature-flags
  Future<Response> _getAllFlags(Request request) async {
    try {
      final flags = await _storage.getAllFlags();
      
      return Response.ok(
        jsonEncode({'flags': flags}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch flags: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/feature-flags/<key>
  Future<Response> _getFlag(Request request, String key) async {
    try {
      final flag = await _storage.getFlag(key);

      if (flag == null) {
        return Response.notFound(
          jsonEncode({'error': 'Flag not found: $key'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'flag': flag}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch flag: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
