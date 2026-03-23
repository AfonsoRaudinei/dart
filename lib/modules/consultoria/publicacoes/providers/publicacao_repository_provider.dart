import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/session/session_controller.dart';
import '../repositories/i_publicacao_repository.dart';
import '../repositories/publicacao_repository_impl.dart';

part 'publicacao_repository_provider.g.dart';

/// Provider concreto SQLite de [IPublicacaoRepository] — ADR-009
///
/// Registra [PublicacaoRepositoryImpl] como implementação oficial do contrato.
/// Mantido em memória durante todo o ciclo de vida do app ([keepAlive: true]).
///
/// Toda camada de domínio ou apresentação deve assistir a este provider
/// (ou ao alias [publicacaoRepositoryProvider]).
///
/// Exemplo de consumo em use case:
/// ```dart
/// final repository = ref.watch(publicacaoRepositoryProvider);
/// ```
@Riverpod(keepAlive: true)
IPublicacaoRepository publicacaoRepository(PublicacaoRepositoryRef ref) {
  return PublicacaoRepositoryImpl();
}

// ignore: unused_element
final _publicacaoLogoutInvalidationRegistration = () {
  SessionController.registerLogoutInvalidation(
    key: 'publicacaoRepositoryProvider',
    invalidate: (ref) => ref.invalidate(publicacaoRepositoryProvider),
  );
  return true;
}();
