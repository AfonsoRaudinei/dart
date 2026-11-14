import '../../domain/entities/parametro_comparativo.dart';

int _novoCaseFotoSlotSeq = 0;

/// Slot de foto dentro de um bloco de comparação (1 a 3 por bloco).
class NovoCaseFotoSlot {
  final String id;
  final String rotulo;
  final String? url;

  NovoCaseFotoSlot({String? id, required this.rotulo, this.url})
    : id = id ?? 'foto-${_novoCaseFotoSlotSeq++}';

  NovoCaseFotoSlot copyWith({
    String? rotulo,
    String? url,
    bool clearUrl = false,
  }) {
    return NovoCaseFotoSlot(
      id: id,
      rotulo: rotulo ?? this.rotulo,
      url: clearUrl ? null : url ?? this.url,
    );
  }
}

/// Bloco de comparação no formulário (estado local do sheet).
class NovoCaseComparacao {
  final String id;
  final List<NovoCaseFotoSlot> fotos;
  final String texto;
  final List<ParametroComparativo> parametros;
  final String? parametroSelecionadoId;

  NovoCaseComparacao({
    required this.id,
    List<NovoCaseFotoSlot>? fotos,
    String? fotoAntesUrl,
    String? fotoDepoisUrl,
    this.texto = '',
    List<ParametroComparativo>? parametros,
    this.parametroSelecionadoId,
  }) : fotos = List<NovoCaseFotoSlot>.unmodifiable(
         _fotosIniciais(fotos, fotoAntesUrl, fotoDepoisUrl),
       ),
       parametros = parametros ?? const [];

  /// Primeiro slot, para compatibilidade com quem lia o par fixo.
  String? get fotoAntesUrl => fotos.isNotEmpty ? fotos.first.url : null;

  /// Segundo slot, se o bloco tiver pelo menos duas fotos.
  String? get fotoDepoisUrl => fotos.length > 1 ? fotos[1].url : null;

  bool get temAlgumaFoto {
    for (final slot in fotos) {
      final url = slot.url?.trim();
      if (url != null && url.isNotEmpty) return true;
    }
    return false;
  }

  NovoCaseComparacao copyWith({
    String? id,
    List<NovoCaseFotoSlot>? fotos,
    String? texto,
    List<ParametroComparativo>? parametros,
    String? parametroSelecionadoId,
    bool clearParametroSelecionado = false,
    String? fotoAntesUrl,
    String? fotoDepoisUrl,
    bool clearFotoAntes = false,
    bool clearFotoDepois = false,
  }) {
    var nextFotos = fotos ?? this.fotos;
    final atualizaUrlLegada =
        fotos == null &&
        (clearFotoAntes ||
            fotoAntesUrl != null ||
            clearFotoDepois ||
            fotoDepoisUrl != null);
    if (atualizaUrlLegada) {
      nextFotos = [
        for (var i = 0; i < this.fotos.length; i++)
          if (i == 0 && (clearFotoAntes || fotoAntesUrl != null))
            this.fotos[i].copyWith(url: fotoAntesUrl, clearUrl: clearFotoAntes)
          else if (i == 1 && (clearFotoDepois || fotoDepoisUrl != null))
            this.fotos[i].copyWith(
              url: fotoDepoisUrl,
              clearUrl: clearFotoDepois,
            )
          else
            this.fotos[i],
      ];
    }
    return NovoCaseComparacao(
      id: id ?? this.id,
      fotos: nextFotos,
      texto: texto ?? this.texto,
      parametros: parametros ?? this.parametros,
      parametroSelecionadoId: clearParametroSelecionado
          ? null
          : parametroSelecionadoId ?? this.parametroSelecionadoId,
    );
  }

  static List<NovoCaseFotoSlot> _fotosIniciais(
    List<NovoCaseFotoSlot>? fotos,
    String? fotoAntesUrl,
    String? fotoDepoisUrl,
  ) {
    if (fotos == null || fotos.isEmpty) {
      return [
        NovoCaseFotoSlot(rotulo: 'Antes', url: fotoAntesUrl),
        NovoCaseFotoSlot(rotulo: 'Depois', url: fotoDepoisUrl),
      ];
    }
    if (fotos.length <= 3) return List<NovoCaseFotoSlot>.from(fotos);
    return List<NovoCaseFotoSlot>.from(fotos.take(3));
  }
}
