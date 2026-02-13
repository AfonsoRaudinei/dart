import 'dart:async';

/// Adapter para backend de feature flags.
///
/// Em produção, conecta ao endpoint real.
/// Em desenvolvimento, usa mock local.
class FeatureFlagBackendAdapter {
  // TODO: Substituir por URL real do backend
  // ignore: unused_field
  static const String _backendUrl = 'https://api.soloforte.com/feature-flags';
  
  /// Modo de desenvolvimento (usa mock)
  static const bool _isDevelopment = true; // TODO: Configurar por ambiente

  /// Busca flags do backend.
  ///
  /// Em desenvolvimento, retorna mock.
  /// Em produção, faz HTTP request.
  Future<Map<String, dynamic>> fetchFlags() async {
    if (_isDevelopment) {
      return _mockBackendResponse();
    }

    // TODO: Implementar HTTP request real
    // try {
    //   final response = await http.get(Uri.parse(_backendUrl));
    //   if (response.statusCode == 200) {
    //     return jsonDecode(response.body) as Map<String, dynamic>;
    //   }
    //   throw Exception('Backend returned ${response.statusCode}');
    // } catch (e) {
    //   throw Exception('Failed to fetch flags: $e');
    // }

    return _mockBackendResponse();
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
