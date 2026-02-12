import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/register_dto.dart';

part 'auth_service.g.dart';

@riverpod
class AuthService extends _$AuthService {
  @override
  void build() {}

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> register(RegisterDto dto) async {
    try {
      // 1. Criar usuário no Auth do Supabase
      final AuthResponse res = await _client.auth.signUp(
        email: dto.email,
        password: dto.password,
        data: {'full_name': dto.name, 'role': dto.role},
      );

      final userId = res.user?.id;
      if (userId == null) throw Exception('Falha ao criar usuário');

      String? photoUrl;

      // 2. Upload da imagem se existir
      if (dto.photo != null) {
        final fileExt = dto.photo!.path.split('.').last;
        final fileName =
            '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'avatars/$fileName';

        await _client.storage
            .from('users')
            .upload(
              filePath,
              dto.photo!,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        photoUrl = _client.storage.from('users').getPublicUrl(filePath);
      }

      // 3. Salvar na tabela public.users
      // Nota: Assume-se que a tabela public.users existe conforme solicitado
      await _client.from('users').upsert({
        'id': userId,
        'name': dto.name,
        'phone': dto.phone,
        'role': dto.role,
        'photo_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> recoverPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}
