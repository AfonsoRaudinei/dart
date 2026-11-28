import 'dart:convert';
import 'dart:typed_data';

import 'relatorio_html_renderer.dart';

/// Fotos do case Resultado no relatório HTML (ADR-065).
///
/// A 1ª foto é o hero do template; as demais viram figuras extras na mesma
/// seção "Registro fotográfico". Toda foto usa `<img data-sf-photo `.
class ResultadoFotosHtml {
  const ResultadoFotosHtml._();

  /// URLs do case: `fotos_resultado_json` (String JSON ou List); se ausente
  /// ou vazia, cai em `foto_principal_url`.
  static List<String> urls(Map<String, dynamic> data) {
    final lista = _parse(data['fotos_resultado_json']);
    if (lista.isNotEmpty) return lista;
    return _parse([data['foto_principal_url']]);
  }

  /// Resolve cada URL para o `src` exportável; descarta as que não resolvem.
  static Future<List<String>> resolve(
    Map<String, dynamic> data,
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
  ) async {
    final resolvidas = await Future.wait([
      for (final url in urls(data))
        RelatorioHtmlRenderer.resolvePhotoSrcForExport(
          url,
          fetchRemoteBytes: fetchRemoteBytes,
        ),
    ]);
    return [
      for (final src in resolvidas)
        if (src.isNotEmpty) src,
    ];
  }

  static String legenda(int numero, String dataCase) =>
      dataCase.isEmpty ? 'Foto $numero' : 'Foto $numero · $dataCase';

  /// Figuras das fotos 2..N (vazio quando há só o hero).
  static String extras(List<String> srcs, String dataCase) {
    if (srcs.length < 2) return '';
    final figuras = StringBuffer();
    for (var i = 1; i < srcs.length; i++) {
      final numero = i + 1;
      final id = 'sf-mk-foto-$numero';
      final legenda = RelatorioHtmlRenderer.escapeHtml(
        ResultadoFotosHtml.legenda(numero, dataCase),
      );
      final src = RelatorioHtmlRenderer.escapeHtml(srcs[i]);
      figuras.write(
        '<figure class="sf-figure lado">'
        '<input type="checkbox" id="$id" class="sf-lb-toggle" hidden>'
        '<label for="$id"><img data-sf-photo src="$src" alt="Foto $numero do resultado" loading="lazy"></label>'
        '<figcaption>$legenda</figcaption>'
        '</figure>',
      );
    }
    final umaFoto = srcs.length == 2 ? ' uma-foto' : '';
    return '<div class="sf-figure-grid mk-compare$umaFoto">$figuras</div>';
  }

  static List<String> _parse(Object? raw) {
    Iterable<Object?> itens = const [];
    try {
      if (raw is List) {
        itens = raw;
      } else if (raw is String && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) itens = decoded;
      }
    } catch (_) {
      return const [];
    }
    return [
      for (final item in itens)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}
