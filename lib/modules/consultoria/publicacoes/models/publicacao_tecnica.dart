// ignore_for_file: constant_identifier_names

import 'publicacao_tema.dart';

/// Status de sincronização offline-first para [PublicacaoTecnica].
///
/// - [local_only]: salvo apenas no dispositivo — nunca enviado ao servidor.
/// - [pending_sync]: aguardando envio para o servidor.
/// - [synced]: sincronizado com sucesso.
/// - [sync_error]: erro na última tentativa de sincronização.
/// - [deleted_local]: marcado para exclusão lógica (soft delete local).
enum PublicacaoSyncStatus {
  local_only,
  pending_sync,
  synced,
  sync_error,
  deleted_local;

  String toJson() => name;

  static PublicacaoSyncStatus fromJson(String json) => values.byName(json);
}

/// Modelo de domínio: Publicação Técnica — ADR-009
///
/// Conteúdo técnico aberto produzido pelo agrônomo sobre temas agronômicos.
/// Pertence ao bounded context [consultoria/publicacoes].
///
/// Fluxo de sincronização:
///   Criado → [PublicacaoSyncStatus.local_only]
///   Publicado → [PublicacaoSyncStatus.pending_sync] → [synced]
///
/// Persistência: offline-first — SQLite é a fonte da verdade.
class PublicacaoTecnica {
  // ── Campos obrigatórios ──────────────────────────────────────────────

  /// Identificador único (UUID v4).
  final String id;

  /// ID do agrônomo autor.
  final String authorId;

  /// Tema técnico da publicação.
  final PublicacaoTema tema;

  /// Título da publicação.
  final String titulo;

  /// Conteúdo técnico completo.
  final String conteudo;

  /// Visibilidade da publicação na plataforma.
  final PublicacaoVisibility visibility;

  /// Status de sincronização offline-first.
  final PublicacaoSyncStatus syncStatus;

  /// Timestamp de criação (UTC).
  final DateTime createdAt;

  /// Timestamp da última atualização (UTC).
  final DateTime updatedAt;

  // ── Campos opcionais ─────────────────────────────────────────────────

  /// Soft delete: preenchido ao excluir logicamente. NUNCA deletar fisicamente.
  final DateTime? deletedAt;

  /// Paths locais de fotos vinculadas à publicação.
  final List<String> fotoPaths;

  /// Referência opcional a um talhão (UUID).
  final String? talhaoRef;

  /// Referência opcional a uma fazenda (UUID).
  final String? fazendaRef;

  /// Safra de referência (ex.: "2024/25").
  final String? safra;

  const PublicacaoTecnica({
    required this.id,
    required this.authorId,
    required this.tema,
    required this.titulo,
    required this.conteudo,
    required this.visibility,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.fotoPaths = const [],
    this.talhaoRef,
    this.fazendaRef,
    this.safra,
  });

  // ── copyWith ─────────────────────────────────────────────────────────

  PublicacaoTecnica copyWith({
    String? id,
    String? authorId,
    PublicacaoTema? tema,
    String? titulo,
    String? conteudo,
    PublicacaoVisibility? visibility,
    PublicacaoSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<String>? fotoPaths,
    String? talhaoRef,
    String? fazendaRef,
    String? safra,
  }) {
    return PublicacaoTecnica(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      tema: tema ?? this.tema,
      titulo: titulo ?? this.titulo,
      conteudo: conteudo ?? this.conteudo,
      visibility: visibility ?? this.visibility,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      fotoPaths: fotoPaths ?? this.fotoPaths,
      talhaoRef: talhaoRef ?? this.talhaoRef,
      fazendaRef: fazendaRef ?? this.fazendaRef,
      safra: safra ?? this.safra,
    );
  }

  // ── Serialização ─────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'tema': tema.toJson(),
    'titulo': titulo,
    'conteudo': conteudo,
    'visibility': visibility.toJson(),
    'syncStatus': syncStatus.toJson(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'fotoPaths': fotoPaths,
    'talhaoRef': talhaoRef,
    'fazendaRef': fazendaRef,
    'safra': safra,
  };

  factory PublicacaoTecnica.fromJson(Map<String, dynamic> json) {
    return PublicacaoTecnica(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      tema: PublicacaoTema.fromJson(json['tema'] as String),
      titulo: json['titulo'] as String,
      conteudo: json['conteudo'] as String,
      visibility: PublicacaoVisibility.fromJson(json['visibility'] as String),
      syncStatus: PublicacaoSyncStatus.fromJson(json['syncStatus'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String).toUtc()
          : null,
      fotoPaths: (json['fotoPaths'] as List<dynamic>?)?.cast<String>() ?? [],
      talhaoRef: json['talhaoRef'] as String?,
      fazendaRef: json['fazendaRef'] as String?,
      safra: json['safra'] as String?,
    );
  }
}
