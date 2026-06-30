import 'dart:convert';
import 'dart:io';

/// Storage para Feature Flags usando arquivo JSON.
///
/// Em produção, substituir por banco de dados real (PostgreSQL, MongoDB, etc.).
class FeatureFlagStorage {
  final String _filePath;

  FeatureFlagStorage({String? filePath})
      : _filePath = filePath ?? 'data/feature_flags.json';

  /// Retorna todas as flags.
  Future<List<Map<String, dynamic>>> getAllFlags() async {
    try {
      final file = File(_filePath);
      
      if (!await file.exists()) {
        // Criar arquivo com flags padrão se não existir
        await _createDefaultFlags();
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return (data['flags'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Erro ao ler flags: $e');
      return [];
    }
  }

  /// Retorna uma flag específica por key.
  Future<Map<String, dynamic>?> getFlag(String key) async {
    final flags = await getAllFlags();
    try {
      return flags.firstWhere((flag) => flag['key'] == key);
    } catch (e) {
      return null;
    }
  }

  /// Cria ou atualiza uma flag.
  Future<bool> upsertFlag(Map<String, dynamic> flag) async {
    try {
      final flags = await getAllFlags();
      final index = flags.indexWhere((f) => f['key'] == flag['key']);

      if (index >= 0) {
        // Atualizar existente
        flags[index] = flag;
      } else {
        // Criar nova
        flags.add(flag);
      }

      await _writeFlags(flags);
      return true;
    } catch (e) {
      print('❌ Erro ao upsert flag: $e');
      return false;
    }
  }

  /// Deleta uma flag por key.
  Future<bool> deleteFlag(String key) async {
    try {
      final flags = await getAllFlags();
      flags.removeWhere((flag) => flag['key'] == key);
      await _writeFlags(flags);
      return true;
    } catch (e) {
      print('❌ Erro ao deletar flag: $e');
      return false;
    }
  }

  /// Escreve flags no arquivo.
  Future<void> _writeFlags(List<Map<String, dynamic>> flags) async {
    final file = File(_filePath);
    final data = {'flags': flags, 'updated_at': DateTime.now().toIso8601String()};
    await file.writeAsString(jsonEncode(data));
  }

  /// Cria arquivo com flags padrão.
  Future<void> _createDefaultFlags() async {
    final defaultFlags = [
      {
        'key': 'drawing_v1',
        'enabled': true,
        'rollout_percentage': 100,
        'allowed_roles': ['consultor', 'produtor'],
        'version': 1,
        'min_app_version': null,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    final file = File(_filePath);
    await file.create(recursive: true);
    await _writeFlags(defaultFlags);
    print('✅ Arquivo de flags criado: $_filePath');
  }
}
