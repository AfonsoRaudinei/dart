import 'package:soloforte_app/core/domain/talhao_condicao.dart';

/// Contrato neutro para comandos sobre talhoes originados do mapa.
///
/// Consumidores externos nao devem importar drawing/ diretamente. A
/// implementacao concreta vive no bounded context dono dos dados.
abstract interface class IDrawingFieldWriter {
  Future<void> deleteFieldAndRecalculateClientArea({
    required String fieldId,
    required String clientId,
  });

  /// Associa um talhao do mapa (`drawings`) a uma fazenda do cliente.
  ///
  /// Atualiza `fazenda_id` / `cliente_id` sem alterar a geometria.
  /// Ver ADR-049.
  Future<void> linkFieldToFarm({
    required String fieldId,
    required String clientId,
    required String farmId,
  });

  /// Renomeia um talhão do mapa (`drawings`) sem alterar a geometria.
  Future<void> updateFieldName({required String fieldId, required String name});

  /// Atualiza cultura, material, safra e plantio de um talhão do mapa sem alterar a geometria.
  ///
  /// Null mantém o valor atual. String vazia limpa. [cicloDias] aceita dígitos
  /// (vira int); vazio limpa; inválido lança [StateError]. Feature inexistente
  /// ou inativa lança [StateError]. Ver ADR-038.
  Future<void> updateFieldMetadata({
    required String fieldId,
    String? cultura,
    String? material,
    String? safra,
    String? dataPlantio,
    String? dataEmergencia,
    String? cicloDias,
  });

  /// Grava a condição do talhão (Bom, Atenção, Alerta, Ruim) sem alterar a geometria.
  ///
  /// Persiste o ARGB canônico em `cor`. Feature inexistente ou inativa lança
  /// [StateError].
  Future<void> updateFieldAvaliacao({
    required String fieldId,
    required TalhaoCondicao condicao,
  });

  /// Combina dois talhões do mapa em um único polígono.
  ///
  /// Mescla a geometria do secundário no primário, preserva o ID do primário
  /// (sem `createNewVersion`), soft-deleta o secundário e recalcula a área
  /// total do cliente. Geometria inválida lança [StateError]. Ver ADR-038.
  Future<void> unionDrawingFields({
    required String primaryFieldId,
    required String secondaryFieldId,
    required String clientId,
  });
}
