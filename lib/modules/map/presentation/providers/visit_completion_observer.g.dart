// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_completion_observer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$visitCompletionObserverHash() =>
    r'5a38cc696a34cbd7a72cab3dca5dc2d9c27a39d5';

/// Orquestrador: VisitSession finalizada → RelatórioTécnico gerado — ADR-009
///
/// Observa o [agendaProvider] e, quando uma [VisitSession] transiciona de
/// ativa (endAtReal == null) para concluída (endAtReal != null), constrói
/// um [VisitSessionSnapshot] e dispara o [generateRelatarioProvider] de
/// forma assíncrona (fire-and-forget — sem bloquear a UI).
///
/// **Bounded context:**
///   - `agenda/` → fonte dos dados de sessão e evento
///   - `consultoria/` → destino (geração do relatório via use case)
///   - `map/` → orquestrador (este arquivo); não importa `operacao/`
///
/// **Mapeamento de campos (declarado explicitamente conforme ADR-009):**
///
/// | Fonte (Event / VisitSession)  | VisitSessionSnapshot.campo | Observação                        |
/// |-------------------------------|----------------------------|-----------------------------------|
/// | session.id                    | sessionId                  | direto                            |
/// | event.clienteId               | clientId                   | direto                            |
/// | event.fazendaId               | farmName                   | fallback se null¹                 |
/// | session.createdBy             | agronomistId               | direto                            |
/// | session.startAtReal           | startedAt                  | direto                            |
/// | session.endAtReal!            | finishedAt                 | não-null garantido                |
/// | OccurrenceRepository          | ocorrencias                | query por session.id²             |
/// | event.talhaoId                | talhoes                    | ID disponível, nome via TODO³     |
/// | (ausente)                     | fotos                      | [] — campo futuro⁴               |
/// | (ausente)                     | monitoramentos             | [] — campo futuro⁴               |
///
/// ¹ `Event.fazendaId` existe mas `farmName` (string legível) requer lookup
///   no repositório de fazendas. Usado como fallback enquanto o lookup não
///   está implementado. TODO marcado no código.
///
/// ² `OccurrenceRepository.getOccurrencesBySession(session.id)` já existe
///   em `consultoria/occurrences/data/occurrence_repository.dart`.
///   Cada `Occurrence` é mapeada para `OcorrenciaSnapshot`.
///
/// ³ `event.talhaoId` fornece o ID do talhão visitado. O nome completo
///   requer lookup via repositório de clientes/talhões. TODO marcado.
///
/// ⁴ Fotos e monitoramentos serão populados quando o módulo `operacao/`
///   expuser esses dados por sessão (iteração futura).
///
/// **Ativação:** este observer deve ser lido/assistido no boot do app para
/// que o listener seja registrado. Ver `main.dart`:
/// ```dart
/// ref.read(visitCompletionObserverProvider); // ADR-010
/// ```
///
/// Copied from [VisitCompletionObserver].
@ProviderFor(VisitCompletionObserver)
final visitCompletionObserverProvider =
    NotifierProvider<VisitCompletionObserver, void>.internal(
      VisitCompletionObserver.new,
      name: r'visitCompletionObserverProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$visitCompletionObserverHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$VisitCompletionObserver = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
