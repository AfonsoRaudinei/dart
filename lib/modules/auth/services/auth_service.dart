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

  /// Cadastro de novo usuário.
  ///
  /// Fluxo:
  /// 1. signUp() cria registro em auth.users
  /// 2. Trigger `on_auth_user_created` cria perfil vazio automaticamente
  /// 3. Se sessão existir (email confirmation desativada), atualiza perfil
  /// 4. Se sessão não existir (email confirmation ativa), retorna sucesso
  ///    e perfil será atualizado no primeiro login
  Future<void> register(RegisterDto dto) async {
    try {
      // 1. Criar usuário no Auth do Supabase
      //    O trigger on_auth_user_created cria perfil vazio automaticamente.
      //    Não há INSERT manual em perfis — SECURITY DEFINER no trigger.
      final AuthResponse res = await NetworkPolicy.withTimeout(
        () => _client.auth.signUp(
          email: dto.email,
          password: dto.password,
          data: {'full_name': dto.name, 'role': dto.role},
        ),
      );

      final user = res.user;
      if (user == null) throw Exception('Falha ao criar usuário');

      // 2. Verificar se sessão foi criada
      //    Com email confirmation ativa: session == null (esperado)
      //    Com email confirmation desativada: session != null
      final session = res.session;

      if (session == null) {
        // Email confirmation ativa — perfil vazio já criado pelo trigger.
        // Dados completos (nome, telefone, role) serão preenchidos
        // no primeiro login via ensureProfileComplete().
        debugPrint(
          '📧 [AuthService] Cadastro OK. Confirmação de email pendente.',
        );
        return;
      }

      // 3. Sessão existe — atualizar perfil com dados completos agora
      await _completeProfile(
        userId: user.id,
        dto: dto,
      );
    } on AuthException catch (e) {
      debugPrint('⚠️ [AuthService] AuthException: ${e.message}');
      if (e.message.contains('User already registered')) {
        throw Exception('Email já cadastrado.');
      }
      throw Exception(
        'Erro de autenticação. Verifique seus dados e tente novamente.',
      );
    } catch (e) {
      rethrow;
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
      debugPrint(
        '⚠️ [AuthService] Erro ao completar perfil: ${e.message}',
      );
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
        () => _client.from('perfis').update({
          'name': dto.name,
          'phone': dto.phone,
          'role': dto.role,
          'photo_url': photoUrl,
        }).eq('id', userId),
      );
    } on PostgrestException catch (e) {
      debugPrint('⚠️ [AuthService] Erro ao atualizar perfil: ${e.message}');
      // Não bloquear cadastro por falha no update de perfil
    }
  }

  Future<void> recoverPassword(String email) async {
    try {
      await NetworkPolicy.withTimeout(
        () => _client.auth.resetPasswordForEmail(email),
      );
    } catch (e) {
      rethrow;
    }
  }
}
