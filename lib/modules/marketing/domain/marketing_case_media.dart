import 'entities/marketing_case.dart';

/// Lista estável de refs de mídia de um [MarketingCase] (URL remota ou path local).
///
/// Ordem: principal → depois → antes → lados de avaliação (A, B por bloco).
/// Deduplica e ignora vazios.
class MarketingCaseMedia {
  const MarketingCaseMedia._();

  static List<String> mediaRefs(MarketingCase marketingCase) {
    final ordered = <String>[];

    void add(String? raw) {
      final value = raw?.trim() ?? '';
      if (value.isEmpty) return;
      if (ordered.contains(value)) return;
      ordered.add(value);
    }

    add(marketingCase.fotoPrincipalUrl);
    add(marketingCase.fotoDepoisUrl);
    add(marketingCase.fotoAntesUrl);

    for (final bloco in marketingCase.avaliacoes) {
      add(bloco.ladoA.fotoUrl);
      add(bloco.ladoB.fotoUrl);
    }

    for (final item in marketingCase.avaliacoesLivres) {
      add(item.fotoLadoAPath);
      add(item.fotoLadoBPath);
    }

    return List<String>.unmodifiable(ordered);
  }

  /// Rótulo curto para a página [index] quando aplicável (Antes/Depois).
  static String? labelFor(MarketingCase marketingCase, int index) {
    final refs = mediaRefs(marketingCase);
    if (index < 0 || index >= refs.length) return null;
    final ref = refs[index];
    final antes = marketingCase.fotoAntesUrl?.trim();
    final depois = marketingCase.fotoDepoisUrl?.trim();
    if (depois != null && depois == ref) return 'Depois';
    if (antes != null && antes == ref) return 'Antes';
    return null;
  }
}
