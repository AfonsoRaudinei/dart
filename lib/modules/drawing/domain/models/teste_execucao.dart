import 'drawing_models.dart';

/// Registro de implementação do campo de teste vinculado a [drawing_id].
class TesteExecucao {
  const TesteExecucao({
    required this.id,
    required this.drawingId,
    required this.userId,
    required this.syncStatus,
    this.talhao,
    this.implementacao,
    this.fotoUrl,
    required this.criadoEm,
    required this.atualizadoEm,
    this.deletedAt,
  });

  final String id;
  final String drawingId;
  final String userId;
  final SyncStatus syncStatus;
  final String? talhao;
  final String? implementacao;
  final String? fotoUrl;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final DateTime? deletedAt;

  TesteExecucao copyWith({
    String? id,
    String? drawingId,
    String? userId,
    SyncStatus? syncStatus,
    String? talhao,
    String? implementacao,
    String? fotoUrl,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return TesteExecucao(
      id: id ?? this.id,
      drawingId: drawingId ?? this.drawingId,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
      talhao: talhao ?? this.talhao,
      implementacao: implementacao ?? this.implementacao,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}