import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/session/session_controller.dart';
import '../repositories/i_relatorio_repository.dart';
import '../repositories/relatorio_repository_impl.dart';

part 'relatorio_repository_provider.g.dart';

/// Provider concreto SQLite de [IRelatorioRepository] — ADR-009
///
/// Registra [RelatorioRepositoryImpl] como implementação oficial do contrato.
/// Mantido em memória durante todo o ciclo de vida do app ([keepAlive: true]).
///
/// Toda camada de domínio ou apresentação deve assistir a este provider
/// (ou ao alias [relatorioRepositoryProvider]).
///
/// Exemplo de consumo em use case:
/// ```dart
/// final repository = ref.watch(relatorioRepositoryProvider);
/// ```
@Riverpod(keepAlive: true)
IRelatorioRepository relatorioRepository(RelatorioRepositoryRef ref) {
  return RelatorioRepositoryImpl();
}

// ignore: unused_element
final _relatorioLogoutInvalidationRegistration = () {
  SessionController.registerLogoutInvalidation(
    key: 'relatorioRepositoryProvider',
    invalidate: (ref) => ref.invalidate(relatorioRepositoryProvider),
  );
  return true;
}();
