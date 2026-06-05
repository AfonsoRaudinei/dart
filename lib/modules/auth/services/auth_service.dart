import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/network_policy.dart';
import '../models/register_dto.dart';

part 'auth_service.g.dart';

@riverpod
class AuthService extends _$AuthService {
  @override
  void build() {}

  SupabaseClient get _client => Supabase.instance.client;

  Future<AuthResponse> login(String email, String password) async {
    try {
      final result = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return result;
    } on AuthException catch (e) {
      throw Exception(_traduzirErro(e.message));
    } catch (e) {
      throw Exception(
        'Não foi possível completar a operação. Verifique sua conexão.',
      );
    }
  }

  Future<AuthResponse> register(RegisterDto dto) async {
    try {
      final result = await _client.auth.signUp(
        email: dto.email,
        password: dto.password,
        data: {'full_name': dto.name},
      );

      // Se sessão ativa (email-confirm desativado), completar perfil agora
      final userId = result.user?.id;
      if (result.session != null && userId != null) {
        try {
          await _completeProfile(userId: userId, dto: dto);
        } catch (e) {
          debugPrint('⚠️ [AuthService] _completeProfile falhou: $e');
          // Não bloquear cadastro por falha no perfil
        }
      }

      return result;
    } on AuthException catch (e) {
      throw Exception(_traduzirErro(e.message));
    } catch (e) {
      throw Exception(
        'Não foi possível completar a operação. Verifique sua conexão.',
      );
    }
  }

  Future<void> recoverPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'soloforte://reset-password',
      );
    } on AuthException catch (e) {
      throw Exception(_traduzirErro(e.message));
    } catch (e) {
      throw Exception(
        'Não foi possível completar a operação. Verifique sua conexão.',
      );
    }
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final result = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return result;
    } on AuthException catch (e) {
      throw Exception(_traduzirErro(e.message));
    } catch (e) {
      throw Exception(
        'Não foi possível completar a operação. Verifique sua conexão.',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(_traduzirErro(e.message));
    } catch (e) {
      throw Exception(
        'Não foi possível completar a operação. Verifique sua conexão.',
      );
    }
  }

  /// Garante que o perfil do usuário logado está completo.
  ///
  /// Idempotente: nunca sobrescreve dados válidos já existentes.
  /// Seguro para múltiplas execuções (login + bootstrap Map).
  ///
  /// Perfil mínimo funcional: `id` + `role` (obrigatórios).
  /// `name` é visual — não bloqueia funcionalidade se ausente.
  Future<void> ensureProfileComplete() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Buscar perfil atual
      final profile = await NetworkPolicy.withTimeout(
        () => _client
            .from('perfis')
            .select('name, role')
            .eq('id', user.id)
            .maybeSingle(),
      );

      if (profile == null) {
        // Perfil não existe (edge case — trigger falhou?) — criar via upsert
        debugPrint('⚠️ [AuthService] Perfil não encontrado. Criando...');
        await NetworkPolicy.withTimeout(
          () => _client.from('perfis').upsert({
            'id': user.id,
            'name': user.userMetadata?['full_name'] ?? '',
            'role': user.userMetadata?['role'] ?? 'produtor',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }),
        );
        return;
      }

      // Só atualizar campos vazios — nunca sobrescrever dados válidos
      final currentName = profile['name'] as String?;
      final currentRole = profile['role'] as String?;

      final updates = <String, dynamic>{};

      if (currentName == null || currentName.isEmpty) {
        updates['name'] = user.userMetadata?['full_name'] ?? '';
      }
      if (currentRole == null || currentRole.isEmpty) {
        updates['role'] = user.userMetadata?['role'] ?? 'produtor';
      }

      if (updates.isEmpty) return; // Perfil já completo — noop

      await NetworkPolicy.withTimeout(
        () => _client.from('perfis').update(updates).eq('id', user.id),
      );
      debugPrint('✅ [AuthService] Perfil completado: ${updates.keys}');
    } on PostgrestException catch (e) {
      // Não bloquear login por falha no perfil
      debugPrint('⚠️ [AuthService] Erro ao completar perfil: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ [AuthService] Erro inesperado no perfil: $e');
    }
  }

  /// Preenche perfil com dados completos (nome, telefone, role, avatar).
  /// Chamado quando sessão está disponível (email confirmation desativada
  /// ou após login confirmado).
  Future<void> _completeProfile({
    required String userId,
    required RegisterDto dto,
  }) async {
    String? photoUrl;

    // Upload da imagem se existir
    if (dto.photo != null) {
      final fileExt = dto.photo!.path.split('.').last;
      final fileName =
          '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      try {
        await NetworkPolicy.withTimeout(
          () => _client.storage
              .from('avatars')
              .upload(
                filePath,
                dto.photo!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              ),
        );

        photoUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      } catch (e) {
        debugPrint('⚠️ [AuthService] Erro no upload de avatar: $e');
        photoUrl = null;
      }
    }

    // UPDATE (não INSERT) — perfil já criado pelo trigger
    try {
      await NetworkPolicy.withTimeout(
        () => _client
            .from('perfis')
            .update({
              'name': dto.name,
              'phone': dto.phone,
              'photo_url': photoUrl,
            })
            .eq('id', userId),
      );
    } on PostgrestException catch (e) {
      debugPrint('⚠️ [AuthService] Erro ao atualizar perfil: ${e.message}');
      // Não bloquear cadastro por falha no update de perfil
    }
  }

  // --- auxiliar ---

  String _traduzirErro(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'Email ou senha incorretos.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'Este email já está cadastrado.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email não confirmado. Verifique sua caixa de entrada.';
    }
    if (lower.contains('password should be at least')) {
      return 'A senha deve ter pelo menos 8 caracteres.';
    }
    if (lower.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection')) {
      return 'Sem conexão com a internet. Verifique sua rede.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }
}
