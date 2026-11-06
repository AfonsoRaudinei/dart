import 'package:flutter/widgets.dart';
import 'package:soloforte_app/core/domain/occurrence_recomendacao_ordem.dart';

import '../../domain/occurrence.dart';

/// Campos "O que fazer", "Dose" e "Quando" da sheet de ocorrência (ADR-056).
class OccurrenceOrdemAplicacaoControllers {
  final acao = TextEditingController();
  final dose = TextEditingController();
  final quando = TextEditingController();

  List<TextEditingController> get _all => [acao, dose, quando];

  bool get hasText => _all.any((ctrl) => ctrl.text.trim().isNotEmpty);

  /// Espelho para a coluna legada `recomendacoes`.
  String? get legacyText => OccurrenceRecomendacaoOrdem.mirrorLegacy(
    acao: acao.text,
    dose: dose.text,
    quando: quando.text,
  );

  /// Sem os três campos salvos, o texto legado entra em [acao] — editar uma
  /// ocorrência antiga não pode apagar a recomendação dela.
  void load(Occurrence occurrence) {
    final ordem = OccurrenceRecomendacaoOrdem.resolve(
      acao: occurrence.recomendacaoAcao,
      dose: occurrence.recomendacaoDose,
      quando: occurrence.recomendacaoQuando,
      legacy: occurrence.recomendacoes,
    );
    acao.text = ordem.acao ?? '';
    dose.text = ordem.dose ?? '';
    quando.text = ordem.quando ?? '';
  }

  void addListener(VoidCallback listener) {
    for (final ctrl in _all) {
      ctrl.addListener(listener);
    }
  }

  void removeListener(VoidCallback listener) {
    for (final ctrl in _all) {
      ctrl.removeListener(listener);
    }
  }

  void dispose() {
    for (final ctrl in _all) {
      ctrl.dispose();
    }
  }
}
