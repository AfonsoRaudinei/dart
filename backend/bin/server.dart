import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/storage/feature_flag_storage.dart';
import '../lib/routes/feature_flag_routes.dart';
import '../lib/routes/admin_routes.dart';
import '../lib/middleware/auth_middleware.dart';

void main(List<String> args) async {
  // Parse argumentos (porta, etc.)
  final port = int.tryParse(args.isNotEmpty ? args[0] : '8080') ?? 8080;

  // Inicializar storage
  final storage = FeatureFlagStorage();
  print('📦 Storage inicializado');

  // Criar routes
  final featureFlagRoutes = FeatureFlagRoutes(storage);
  final adminRoutes = AdminRoutes(storage);

  // Montar router principal
  final app = Router();

  // Routes públicas (com autenticação de app client)
  app.mount('/api/', 
    Pipeline()
      .addMiddleware(AuthMiddleware.appAuth())
      .addHandler(featureFlagRoutes.router),
  );

  // Routes administrativas (com autenticação de admin)
  app.mount('/admin/', 
    Pipeline()
      .addMiddleware(AuthMiddleware.adminAuth())
      .addHandler(adminRoutes.router),
  );

  // Health check (sem autenticação)
  app.get('/health', (Request request) {
    return Response.ok('{"status":"healthy"}', 
      headers: {'Content-Type': 'application/json'});
  });

  // 404 handler
  app.all('/<ignored|.*>', (Request request) {
    return Response.notFound('{"error":"Route not found"}',
      headers: {'Content-Type': 'application/json'});
  });

  // Pipeline global
  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(requestLogger())
      .addMiddleware(AuthMiddleware.rateLimit(maxRequests: 1000))
      .addHandler(app);

  // Iniciar servidor
  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    port,
  );

  print('');
  print('🚀 SoloForte Feature Flags Server');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📡 Listening on http://${server.address.host}:${server.port}');
  print('');
  print('📋 Endpoints:');
  print('   GET  /health                     (Health check)');
  print('   GET  /api/feature-flags          (Listar todas as flags)');
  print('   GET  /api/feature-flags/<key>    (Flag específica)');
  print('');
  print('🔐 Admin Endpoints (require admin token):');
  print('   GET    /admin/flags               (Listar com metadados)');
  print('   POST   /admin/flags               (Criar flag)');
  print('   PUT    /admin/flags/<key>         (Atualizar flag)');
  print('   DELETE /admin/flags/<key>         (Deletar flag)');
  print('');
  print('🔑 Tokens:');
  print('   App Client: app-client-token-2026');
  print('   Admin:      admin-secret-token-2026');
  print('');
  print('💡 Exemplo de uso:');
  print('   curl -H "Authorization: Bearer app-client-token-2026" \\');
  print('        http://localhost:$port/api/feature-flags');
  print('');
}
