import 'dart:convert';
import 'dart:io';

/// Inicializa feature flags para um ambiente específico
void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Usage: dart run scripts/init_flags.dart [staging|production]');
    exit(1);
  }

  final environment = args[0];
  if (environment != 'staging' && environment != 'production') {
    print('❌ Environment must be staging or production');
    exit(1);
  }

  print('🎌 Initializing flags for $environment...');

  // Carregar config do ambiente
  final configFile = File('config/$environment.json');
  if (!configFile.existsSync()) {
    print('❌ Config file not found: ${configFile.path}');
    exit(1);
  }

  final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final flags = config['feature_flags'] as List<dynamic>;
  final storagePath = config['storage']['path'] as String;

  // Criar estrutura de storage
  final storageData = {
    'flags': flags,
    'environment': environment,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };

  // Escrever arquivo de flags
  final storageFile = File(storagePath);
  storageFile.parent.createSync(recursive: true);
  storageFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(storageData),
  );

  print('✅ Initialized ${flags.length} flags');
  print('📁 Storage: $storagePath');
  print('');

  // Listar flags inicializadas
  print('📋 Flags initialized:');
  for (final flag in flags) {
    final key = flag['key'];
    final enabled = flag['enabled'];
    final rollout = flag['rollout_percentage'];
    final roles = (flag['allowed_roles'] as List).join(', ');
    
    final status = enabled 
        ? (rollout == 100 ? '🟢 100%' : '🟡 $rollout%') 
        : '🔴 OFF';
    
    print('  $status $key [$roles]');
  }
}
