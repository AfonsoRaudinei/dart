import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/publicacao_tecnica.dart';
import '../models/publicacao_tema.dart';
import '../providers/publicacao_repository_provider.dart';
import '../repositories/i_publicacao_repository.dart';

part 'create_publicacao_use_case.g.dart';

/// Dados de entrada para criação de uma [PublicacaoTecnica].
///
/// Agrupa os campos obrigatórios e opcionais necessários ao use case,
/// evitando listas longas de parâmetros no provider.
class CreatePublicacaoInput {
  /// ID do agrônomo autor.
  final String authorId;

  /// Tema técnico da publicação.
  final PublicacaoTema tema;

  /// Título da publicação.
  final String titulo;

  /// Conteúdo técnico completo.
  final String conteudo;

  /// Visibilidade na plataforma.
  final PublicacaoVisibility visibility;

  /// Paths locais de fotos vinculadas (opcional).
  final List<String> fotoPaths;

  /// Referência a talhão (opcional — UUID).
  final String? talhaoRef;

  /// Referência a fazenda (opcional — UUID).
  final String? fazendaRef;

  /// Safra de referência (opcional).
  final String? safra;

  const CreatePublicacaoInput({
    required this.authorId,
    required this.tema,
    required this.titulo,
    required this.conteudo,
    required this.visibility,
    this.fotoPaths = const [],
    this.talhaoRef,
    this.fazendaRef,
    this.safra,
  });
}

/// Use case: Criar Publicação Técnica — ADR-009
///
/// Recebe um [CreatePublicacaoInput] e persiste uma nova [PublicacaoTecnica]
/// localmente com syncStatus [PublicacaoSyncStatus.local_only].
///
/// Responsabilidades:
///   - Validar campos obrigatórios (título, conteúdo não vazios)
///   - Atribuir ID único (UUID v4)
///   - Definir syncStatus inicial: [PublicacaoSyncStatus.local_only]
///   - Persistir via [IPublicacaoRepository.save]
///   - Retornar a publicação criada
///
/// Regras ADR-009:
///   ❌ NÃO chama API — offline-first
///   ✅ Publicação fica disponível localmente imediatamente
///   ✅ Sincronização ocorre em etapa separada via pending_sync
@riverpod
Future<PublicacaoTecnica> createPublicacao(
  Ref ref,
  CreatePublicacaoInput input,
) async {
  if (input.titulo.trim().isEmpty) {
    throw ArgumentError('O título da publicação não pode estar vazio.');
  }

  if (input.conteudo.trim().isEmpty) {
    throw ArgumentError('O conteúdo da publicação não pode estar vazio.');
  }

  final repository = ref.watch(publicacaoRepositoryProvider);
  const uuid = Uuid();
  final now = DateTime.now().toUtc();

  final publicacao = PublicacaoTecnica(
    id: uuid.v4(),
    authorId: input.authorId,
    tema: input.tema,
    titulo: input.titulo.trim(),
    conteudo: input.conteudo.trim(),
    visibility: input.visibility,
    syncStatus: PublicacaoSyncStatus.local_only,
    createdAt: now,
    updatedAt: now,
    fotoPaths: input.fotoPaths,
    talhaoRef: input.talhaoRef,
    fazendaRef: input.fazendaRef,
    safra: input.safra,
  );

  await repository.save(publicacao);

  return publicacao;
}
