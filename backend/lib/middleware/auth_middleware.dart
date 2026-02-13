import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

/// Middleware para validação de autenticação via Bearer token.
///
/// Em produção, usar JWT, OAuth2, ou similar.
class AuthMiddleware {
  // TODO: Substituir por validação real (JWT, banco de dados, etc.)
  static const String _validAdminToken = 'admin-secret-token-2026';
  static const String _validAppToken = 'app-client-token-2026';

  /// Middleware para proteger endpoints admin (CRUD flags).
  static Middleware adminAuth() {
    return (Handler handler) {
      return (Request request) async {
        final authHeader = request.headers['authorization'];

        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response.forbidden(
            jsonEncode({'error': 'Missing or invalid Authorization header'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        final token = authHeader.substring(7);

        if (token != _validAdminToken) {
          return Response.forbidden(
            jsonEncode({'error': 'Invalid admin token'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Token válido → prosseguir
        return handler(request);
      };
    };
  }

  /// Middleware para proteger endpoints de app client (leitura flags).
  static Middleware appAuth() {
    return (Handler handler) {
      return (Request request) async {
        final authHeader = request.headers['authorization'];

        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response.forbidden(
            jsonEncode({'error': 'Missing or invalid Authorization header'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        final token = authHeader.substring(7);

        if (token != _validAppToken && token != _validAdminToken) {
          return Response.forbidden(
            jsonEncode({'error': 'Invalid client token'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Token válido → prosseguir
        return handler(request);
      };
    };
  }

  /// Middleware opcional: Rate limiting simples (em memória).
  static Middleware rateLimit({int maxRequests = 100, Duration window = const Duration(minutes: 1)}) {
    final Map<String, List<DateTime>> requestLog = {};

    return (Handler handler) {
      return (Request request) async {
        final clientIp = request.headers['x-forwarded-for'] ?? 
                         request.context['shelf.io.connection_info']?.toString() ?? 
                         'unknown';

        // Limpar entradas antigas
        final now = DateTime.now();
        final cutoff = now.subtract(window);
        requestLog[clientIp]?.removeWhere((time) => time.isBefore(cutoff));

        // Verificar limite
        final requests = requestLog[clientIp] ?? [];
        if (requests.length >= maxRequests) {
          return Response(
            429,
            body: jsonEncode({'error': 'Rate limit exceeded'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Registrar request
        requests.add(now);
        requestLog[clientIp] = requests;

        return handler(request);
      };
    };
  }
}

/// Middleware para logging de requests.
Middleware requestLogger() {
  return (Handler handler) {
    return (Request request) async {
      final startTime = DateTime.now();
      print('➡️  ${request.method} ${request.url}');

      final response = await handler(request);

      final duration = DateTime.now().difference(startTime);
      print('⬅️  ${response.statusCode} (${duration.inMilliseconds}ms)');

      return response;
    };
  };
}

/// Middleware para CORS (Cross-Origin Resource Sharing).
Middleware corsHeaders() {
  return createMiddleware(
    requestHandler: (Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      return null;
    },
    responseHandler: (Response response) {
      return response.change(headers: _corsHeaders);
    },
  );
}

final Map<String, String> _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};
