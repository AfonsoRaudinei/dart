import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../infra/preferences_service.dart';

/// Guarda localmente a foto escolhida no cadastro enquanto o e-mail ainda
/// não foi confirmado (sem sessão não há como enviar ao Storage).
///
/// A imagem é copiada para um diretório estável do app (o arquivo do picker
/// vive em cache e pode ser apagado pelo SO) e o caminho fica em
/// [PreferencesService], indexado pelo e-mail normalizado — mesmo padrão de
/// `PendingSignupRoleStore`. Após o primeiro login confirmado,
/// `AuthService.ensureProfileComplete` envia a foto e chama [clear].
class PendingSignupAvatarStore {
  PendingSignupAvatarStore(
    this._preferences, {
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const _keyPrefix = 'auth.pending_signup_avatar.';
  static const _folderName = 'pending_signup_avatar';
  static const _ttl = Duration(days: 7);

  final PreferencesService _preferences;
  final Future<Directory> Function() _directoryProvider;

  /// Copia [source] para o armazenamento do app e registra para [email].
  /// Falhas são silenciosas para quem chama: a foto é opcional.
  Future<void> save({required String email, required File source}) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty || !await source.exists()) return;

    final base = await _directoryProvider();
    final folder = Directory(p.join(base.path, _folderName));
    await folder.create(recursive: true);

    final ext = p.extension(source.path);
    final target = File(
      p.join(
        folder.path,
        '${base64Url.encode(utf8.encode(normalizedEmail))}$ext',
      ),
    );

    // Substitui cadastro anterior com o mesmo e-mail.
    await _deleteStoredFile(normalizedEmail);
    await source.copy(target.path);

    await _preferences.setString(
      _keyFor(normalizedEmail),
      jsonEncode({
        'path': target.path,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  /// Caminho da foto pendente se existir, não expirou e o arquivo ainda está
  /// no disco. Entradas inválidas são limpas.
  Future<File?> readValid(String? email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) return null;

    final key = _keyFor(normalizedEmail);
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await clear(normalizedEmail);
        return null;
      }

      final path = decoded['path'] as String?;
      final createdAt = DateTime.tryParse(
        decoded['created_at'] as String? ?? '',
      )?.toUtc();
      final isExpired =
          createdAt == null ||
          DateTime.now().toUtc().difference(createdAt) > _ttl;

      if (path == null || path.isEmpty || isExpired) {
        await clear(normalizedEmail);
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        await clear(normalizedEmail);
        return null;
      }
      return file;
    } catch (_) {
      await clear(normalizedEmail);
      return null;
    }
  }

  Future<void> clear(String? email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) return;
    await _deleteStoredFile(normalizedEmail);
    await _preferences.remove(_keyFor(normalizedEmail));
  }

  Future<void> _deleteStoredFile(String normalizedEmail) async {
    final raw = _preferences.getString(_keyFor(normalizedEmail));
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      final path = decoded is Map<String, dynamic>
          ? decoded['path'] as String?
          : null;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      // Melhor esforço: arquivo órfão não bloqueia o fluxo.
    }
  }

  static String _normalizeEmail(String? email) =>
      (email ?? '').trim().toLowerCase();

  static String _keyFor(String email) => '$_keyPrefix$email';
}
