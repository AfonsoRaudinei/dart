import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/publicacao_tecnica.dart';
import '../models/publicacao_tema.dart';
import 'publicacao_repository_provider.dart';

part 'publicacao_providers.g.dart';

/// Provider de lista de publicações públicas — ADR-008
///
/// Retorna a lista de [PublicacaoTecnica] públicas, opcionalmente
/// filtradas por [tema].
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final publicacoes = ref.watch(publicacoesListProvider(tema: tema));
/// ```
@riverpod
Future<List<PublicacaoTecnica>> publicacoesList(
  PublicacoesListRef ref, {
  PublicacaoTema? tema,
}) async {
  final repository = ref.watch(publicacaoRepositoryProvider);

  if (tema != null) {
    return repository.getByTema(tema);
  }

  return repository.getPublicas();
}

/// Provider de detalhe de publicação — ADR-008
///
/// Retorna uma [PublicacaoTecnica] pelo [id], ou [null] se não encontrada.
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final publicacao = ref.watch(publicacaoDetailProvider(id: id));
/// ```
@riverpod
Future<PublicacaoTecnica?> publicacaoDetail(
  PublicacaoDetailRef ref, {
  required String id,
}) async {
  final repository = ref.watch(publicacaoRepositoryProvider);
  return repository.getById(id);
}

/// Estado efêmero do formulário de criação de publicação — ADR-008
///
/// Campos do formulário que NÃO devem persistir entre sessões.
/// AutoDispose para limpar o estado quando o formulário for fechado.
class PublicacaoFormState {
  final PublicacaoTema? tema;
  final String titulo;
  final String conteudo;
  final List<String> fotoPaths;
  final String? talhaoRef;
  final String? safra;
  final bool isSubmitting;
  final String? errorMessage;

  const PublicacaoFormState({
    this.tema,
    this.titulo = '',
    this.conteudo = '',
    this.fotoPaths = const [],
    this.talhaoRef,
    this.safra,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Valida se o formulário está pronto para submissão.
  bool get isValid =>
      titulo.trim().isNotEmpty && conteudo.trim().isNotEmpty && tema != null;

  PublicacaoFormState copyWith({
    PublicacaoTema? tema,
    String? titulo,
    String? conteudo,
    List<String>? fotoPaths,
    String? talhaoRef,
    String? safra,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return PublicacaoFormState(
      tema: tema ?? this.tema,
      titulo: titulo ?? this.titulo,
      conteudo: conteudo ?? this.conteudo,
      fotoPaths: fotoPaths ?? this.fotoPaths,
      talhaoRef: talhaoRef ?? this.talhaoRef,
      safra: safra ?? this.safra,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier de estado do formulário de publicação — ADR-008
///
/// Gerencia o estado efêmero do formulário de criação.
/// AutoDispose para limpar automaticamente ao sair da tela.
///
/// Consumo típico:
/// ```dart
/// final formState = ref.watch(publicacaoFormNotifierProvider);
/// ref.read(publicacaoFormNotifierProvider.notifier).setTema(tema);
/// ```
@riverpod
class PublicacaoFormNotifier extends _$PublicacaoFormNotifier {
  @override
  PublicacaoFormState build() {
    return const PublicacaoFormState();
  }

  void setTema(PublicacaoTema tema) {
    state = state.copyWith(tema: tema);
  }

  void setTitulo(String titulo) {
    state = state.copyWith(titulo: titulo);
  }

  void setConteudo(String conteudo) {
    state = state.copyWith(conteudo: conteudo);
  }

  void addFoto(String path) {
    state = state.copyWith(fotoPaths: [...state.fotoPaths, path]);
  }

  void removeFoto(String path) {
    state = state.copyWith(
      fotoPaths: state.fotoPaths.where((p) => p != path).toList(),
    );
  }

  void setTalhaoRef(String? ref) {
    state = state.copyWith(talhaoRef: ref);
  }

  void setSafra(String? safra) {
    state = state.copyWith(safra: safra);
  }

  void setSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  void setError(String? errorMessage) {
    state = state.copyWith(errorMessage: errorMessage);
  }

  void reset() {
    state = const PublicacaoFormState();
  }
}
