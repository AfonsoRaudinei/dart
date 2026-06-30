import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Adapter para backend de feature flags.
///
/// Em produção (`ENV=production` ou `ENV=staging`), conectará ao endpoint real.
/// Em desenvolvimento (`ENV=development`), usa mock local.
class FeatureFlagBackendAdapter {
  static const String _backendUrl = 'https://api.soloforte.com/feature-flags';
  static const Duration _requestTimeout = Duration(seconds: 8);

  /// Verdadeiro quando o ambiente não é produção — lido de [AppConfig].
  static bool get _isDevelopment => !AppConfig.isProduction;

  /// Busca flags do backend.
  ///
  /// Em desenvolvimento, retorna mock.
  /// Em produção, faz HTTP request.
  Future<Map<String, dynamic>> fetchFlags() async {
    if (_isDevelopment) {
      return _mockBackendResponse();
    }

    final response = await http
        .get(Uri.parse(_backendUrl))
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            'Feature flags request timed out after ${_requestTimeout.inSeconds}s',
          ),
        );

    if (response.statusCode != 200) {
      throw StateError(
        'Feature flags backend returned HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Feature flags payload must be a JSON object',
      );
    }
    if (decoded['flags'] is! List) {
      throw const FormatException('Feature flags payload missing "flags" list');
    }

    return decoded;
  }

  /// Mock do backend para desenvolvimento.
  ///
  /// Simula delay de rede e retorna configuração inicial.
  Future<Map<String, dynamic>> _mockBackendResponse() async {
    // Simular latência de rede
    await Future.delayed(const Duration(milliseconds: 200));

    // Configuração inicial: Drawing disponível 100% para consultores
    return {
      'flags': [
        {
          'key': 'drawing_v1',
          'enabled': true,
          'rollout_percentage': 100,
          'allowed_roles': ['consultor', 'produtor'], // Permitir ambos em dev
          'version': 1,
          'min_app_version': null,
        },
        {
          'key': 'agenda_ai_v1',
          'enabled': true,
          'rollout_percentage': 100,
          'allowed_roles': ['consultor', 'produtor'],
          'version': 1,
          'min_app_version': null,
        },
      ],
    };
  }

  /// Simula rollout progressivo (para testes).
  ///
  /// Útil para validar comportamento em diferentes fases.
  Future<Map<String, dynamic>> _mockRolloutPhase(int phase) async {
    await Future.delayed(const Duration(milliseconds: 200));

    switch (phase) {
      case 1: // Fase 1 — Interno (5% consultores)
        return {
          'flags': [
            {
              'key': 'drawing_v1',
              'enabled': true,
              'rollout_percentage': 5,
              'allowed_roles': ['consultor'],
              'version': 1,
            },
          ],
        };

      case 2: // Fase 2 — Beta (25% ambos)
        return {
          'flags': [
            {
              'key': 'drawing_v1',
              'enabled': true,
              'rollout_percentage': 25,
              'allowed_roles': ['consultor', 'produtor'],
              'version': 2,
            },
          ],
        };

      case 3: // Fase 3 — Expansão (60%)
        return {
          'flags': [
            {
              'key': 'drawing_v1',
              'enabled': true,
              'rollout_percentage': 60,
              'allowed_roles': null,
              'version': 3,
            },
          ],
        };

      case 4: // Fase 4 — Total (100%)
        return {
          'flags': [
            {
              'key': 'drawing_v1',
              'enabled': true,
              'rollout_percentage': 100,
              'allowed_roles': null,
              'version': 4,
            },
          ],
        };

      default: // Kill switch
        return {
          'flags': [
            {
              'key': 'drawing_v1',
              'enabled': false,
              'rollout_percentage': 0,
              'version': 999,
            },
          ],
        };
    }
  }

  /// Simula kill switch (para testes de emergência).
  Future<Map<String, dynamic>> mockKillSwitch() async {
    return _mockRolloutPhase(0);
  }
}
