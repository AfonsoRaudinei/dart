import '../../domain/entities/parametro_comparativo.dart';

/// Bloco de comparação Antes/Depois no formulário (estado local do sheet).
class NovoCaseComparacao {
  final String id;
  String? fotoAntesUrl;
  String? fotoDepoisUrl;
  final List<ParametroComparativo> parametros;
  String? parametroSelecionadoId;

  NovoCaseComparacao({
    required this.id,
    this.fotoAntesUrl,
    this.fotoDepoisUrl,
    List<ParametroComparativo>? parametros,
    this.parametroSelecionadoId,
  }) : parametros = parametros ?? [];

  NovoCaseComparacao copyWith({
    String? id,
    String? fotoAntesUrl,
    String? fotoDepoisUrl,
    List<ParametroComparativo>? parametros,
    String? parametroSelecionadoId,
    bool clearFotoAntes = false,
    bool clearFotoDepois = false,
    bool clearParametroSelecionado = false,
  }) {
    return NovoCaseComparacao(
      id: id ?? this.id,
      fotoAntesUrl: clearFotoAntes ? null : fotoAntesUrl ?? this.fotoAntesUrl,
      fotoDepoisUrl: clearFotoDepois ? null : fotoDepoisUrl ?? this.fotoDepoisUrl,
      parametros: parametros ?? this.parametros,
      parametroSelecionadoId: clearParametroSelecionado
          ? null
          : parametroSelecionadoId ?? this.parametroSelecionadoId,
    );
  }
}
