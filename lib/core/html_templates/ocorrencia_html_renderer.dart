import 'dart:convert';

import 'relatorio_html_renderer.dart';

class OcorrenciaHtmlRenderer {
  /// [data] = Occurrence convertido para Map pelo chamador.
  ///
  /// Estrutura esperada: campos do schema occurrences e campos calculados
  /// opcionais: categoria_label, urgencia_class, foto_base64, cliente_nome,
  /// fazenda_nome, talhao_nome.
  static Future<String> renderDetalhe(
    Map<String, dynamic> data, {
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantName,
    String? consultantRole,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'ocorrencia_detalhada.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: reportBrandName,
      customLogoPath: reportLogoPath,
      consultantName: consultantName,
      consultantRole: consultantRole,
    );

    final category = data['category'] as String? ?? '';
    final cat = _categoriaInfo(category);
    final categoriaLabel = RelatorioHtmlRenderer.escapeHtml(
      data['categoria_label'] as String? ?? cat.label,
    );
    final type = (data['type'] as String?)?.trim() ?? '';
    final urgenciaClass =
        data['urgencia_class'] as String? ?? _urgenciaClass(type);
    final createdAt = _parseDateTime(data['created_at'] as String?);
    final dataRegistro = RelatorioHtmlRenderer.formatDate(createdAt);
    final consultantNome = consultantName?.trim() ?? '';
    final heroSrc = data['foto_base64'] as String? ?? '';
    final contextoLinha =
        [data['cliente_nome'], data['fazenda_nome'], data['talhao_nome']]
            .map((value) => (value as String?)?.trim() ?? '')
            .where((value) => value.isNotEmpty)
            .map(RelatorioHtmlRenderer.escapeHtml)
            .followedBy([if (dataRegistro.isNotEmpty) dataRegistro])
            .join(' · ');

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'categoria_label': categoriaLabel,
      'contexto_linha': contextoLinha,
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(
        data['cliente_nome'] as String?,
      ),
      'fazenda_nome': RelatorioHtmlRenderer.escapeHtml(
        data['fazenda_nome'] as String?,
      ),
      'talhao_nome': RelatorioHtmlRenderer.escapeHtml(
        data['talhao_nome'] as String?,
      ),
      'category': category,
      'type': RelatorioHtmlRenderer.escapeHtml(type),
      'urgencia_class': urgenciaClass,
      'urgencia_label':
          'Urgência ${_urgenciaValor(urgenciaClass).toLowerCase()}',
      'consultant_nome': RelatorioHtmlRenderer.escapeHtml(consultantNome),
      'consultant_role': RelatorioHtmlRenderer.escapeHtml(
        consultantRole?.trim(),
      ),
      'emitido_em': RelatorioHtmlRenderer.formatDate(DateTime.now()),
      'foto_hero_legenda': [
        'Foto 1',
        categoriaLabel,
        if (dataRegistro.isNotEmpty) dataRegistro,
      ].join(' · '),
      'cultivar': RelatorioHtmlRenderer.escapeHtml(data['cultivar'] as String?),
      'estadio_fenologico': RelatorioHtmlRenderer.escapeHtml(
        data['estadio_fenologico'] as String?,
      ),
      'data_plantio_formatado': _formatDataPlantio(
        data['data_plantio'] as String?,
      ),
      'photo_base64': data['foto_base64'] as String? ?? '',
      'description': RelatorioHtmlRenderer.escapeHtml(
        data['description'] as String?,
      ),
      'recomendacoes': RelatorioHtmlRenderer.escapeHtml(
        data['recomendacoes'] as String?,
      ),
      'lat': data['lat']?.toString() ?? '',
      'long': data['long']?.toString() ?? '',
      'localizacao_mapa': _localizacaoMapa(data),
      'created_at_formatado': RelatorioHtmlRenderer.formatDateTime(createdAt),
      'id_curto': RelatorioHtmlRenderer.shortId(data['id'] as String? ?? ''),
      'sync_status': data['sync_status'] as String? ?? '',
    });

    final galeria = await _renderGaleria(
      data['fotos_categorias_json'] as String?,
      firstNumber: heroSrc.isNotEmpty ? 2 : 1,
    );
    final notas = _renderNotas(data['notas_categorias_json'] as String?);
    final metricas = _renderMetricas(data['metricas_json'] as String?);
    final nutrientes = _renderNutrientes(data['nutrientes_json'] as String?);

    tpl = _resolveRepeatedIf(tpl, 'contexto_linha', contextoLinha.isNotEmpty);
    tpl = _resolveRepeatedIf(tpl, 'type', type.isNotEmpty);
    tpl = _resolveRepeatedIf(tpl, 'consultant_nome', consultantNome.isNotEmpty);
    tpl = _resolveRepeatedIf(
      tpl,
      'consultant_role',
      consultantRole?.trim().isNotEmpty == true,
    );
    tpl = _resolveRepeatedIf(tpl, 'created_at', createdAt != null);
    tpl = _resolveRepeatedIf(
      tpl,
      'registro_fotografico',
      heroSrc.isNotEmpty || galeria.isNotEmpty,
    );
    tpl = _resolveRepeatedIf(
      tpl,
      'cultivar',
      (data['cultivar'] as String?)?.isNotEmpty == true,
    );
    tpl = _resolveRepeatedIf(
      tpl,
      'estadio_fenologico',
      (data['estadio_fenologico'] as String?)?.isNotEmpty == true,
    );
    tpl = _resolveRepeatedIf(
      tpl,
      'data_plantio',
      (data['data_plantio'] as String?)?.isNotEmpty == true,
    );
    tpl = _resolveRepeatedIf(tpl, 'amostra_solo', _isAmostraSolo(data));
    tpl = _resolveRepeatedIf(
      tpl,
      'description',
      (data['description'] as String?)?.isNotEmpty == true,
    );
    tpl = _resolveRepeatedIf(
      tpl,
      'photo_base64',
      (data['foto_base64'] as String?)?.isNotEmpty == true,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'fotos_categorias',
      include: galeria.isNotEmpty,
      truthyHtml: galeria,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'notas_categorias',
      include: notas.isNotEmpty,
      truthyHtml: notas,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'metricas',
      include: metricas.isNotEmpty,
      truthyHtml: metricas,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'nutrientes && nutrientes.length > 0',
      include: nutrientes.isNotEmpty,
      truthyHtml: nutrientes,
    );
    tpl = _resolveRepeatedIf(
      tpl,
      'recomendacoes',
      (data['recomendacoes'] as String?)?.isNotEmpty == true,
    );
    tpl = _resolveRepeatedIf(
      tpl,
      'lat && long',
      data['lat'] != null && data['long'] != null,
    );

    return RelatorioHtmlRenderer.finalizeDocument(tpl);
  }

  static Future<String> renderLista({
    required List<Map<String, dynamic>> ocorrencias,
    required String clienteNome,
    String? fazendaNome,
    String? talhaoNome,
    String? cultivar,
    String? agronomistNome,
    DateTime? dataVisita,
    String? visitSessionId,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantRole,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'ocorrencias_lista.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: reportBrandName,
      customLogoPath: reportLogoPath,
      consultantName: agronomistNome,
      consultantRole: consultantRole,
    );

    final total = ocorrencias.length;
    final totalFotos = ocorrencias
        .where((data) => (data['foto_base64'] as String?)?.isNotEmpty == true)
        .length;
    final amostras = ocorrencias.where(_isAmostraSolo).length;

    int countUrgencia(String urgenciaClass) => ocorrencias
        .where((data) => _urgenciaClassOrNull(data['type']) == urgenciaClass)
        .length;
    final alta = countUrgencia('alta');
    final media = countUrgencia('media');
    final baixa = countUrgencia('baixa');

    final pctAlta = total > 0 ? (alta / total * 100).round() : 0;
    final pctMedia = total > 0 ? (media / total * 100).round() : 0;
    final pctBaixa = total > 0 ? (baixa / total * 100).round() : 0;

    final cats = ocorrencias
        .map((data) => data['category'] as String? ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;

    final dataVisitaFmt = RelatorioHtmlRenderer.formatDate(dataVisita);
    final role = consultantRole?.trim() ?? '';
    final contextoLinha = [fazendaNome, talhaoNome, cultivar]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .map(RelatorioHtmlRenderer.escapeHtml)
        .followedBy([if (dataVisitaFmt.isNotEmpty) dataVisitaFmt])
        .join(' · ');

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'contexto_linha': contextoLinha,
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'fazenda_nome': RelatorioHtmlRenderer.escapeHtml(fazendaNome),
      'talhao_nome': RelatorioHtmlRenderer.escapeHtml(talhaoNome),
      'cultivar': RelatorioHtmlRenderer.escapeHtml(cultivar),
      'agronomist_nome': RelatorioHtmlRenderer.escapeHtml(agronomistNome),
      'consultant_role': RelatorioHtmlRenderer.escapeHtml(role),
      'emitido_em': RelatorioHtmlRenderer.formatDate(DateTime.now()),
      'data_visita_formatada': dataVisitaFmt,
      'total_ocorrencias': total.toString(),
      'total_ocorrencias_label': total == 1 ? 'ocorrência' : 'ocorrências',
      'total_categorias': cats.toString(),
      'total_categorias_label': cats == 1 ? 'categoria' : 'categorias',
      'total_fotos': totalFotos.toString(),
      'total_fotos_label': totalFotos == 1 ? 'foto' : 'fotos',
      'amostras_solo': amostras.toString(),
      'amostras_solo_label': amostras == 1
          ? 'amostra de solo'
          : 'amostras de solo',
      'count_alta': alta.toString(),
      'count_media': media.toString(),
      'count_baixa': baixa.toString(),
      'pct_alta': pctAlta.toString(),
      'pct_media': pctMedia.toString(),
      'pct_baixa': pctBaixa.toString(),
    });

    tpl = _resolveRepeatedIf(tpl, 'contexto_linha', contextoLinha.isNotEmpty);
    for (final entry in {
      'cultivar': cultivar,
      'agronomist_nome': agronomistNome,
      'data_visita_formatada': dataVisitaFmt,
      'consultant_role': role,
    }.entries) {
      tpl = _resolveRepeatedIf(
        tpl,
        entry.key,
        entry.value?.trim().isNotEmpty == true,
      );
    }
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'total_ocorrencias > 0',
      include: total > 0,
    );

    final grupos = _renderGrupos(ocorrencias);
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'grupos.length > 0',
      include: grupos.isNotEmpty,
      truthyHtml: grupos,
    );

    return RelatorioHtmlRenderer.finalizeDocument(tpl);
  }

  static String _resolveRepeatedIf(String tpl, String condition, bool include) {
    var result = tpl;
    for (var i = 0; i < 8; i++) {
      final next = RelatorioHtmlRenderer.resolveIfBlock(
        result,
        condition,
        include: include,
      );
      if (next == result) break;
      result = next;
    }
    return result;
  }

  static String _renderGrupos(List<Map<String, dynamic>> ocorrencias) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final data in ocorrencias) {
      final key = data['category'] as String? ?? 'outro';
      grouped.putIfAbsent(key, () => []).add(data);
    }

    final sb = StringBuffer();
    var numero = 0;
    var fotoNumero = 0;
    for (final entry in grouped.entries) {
      final cat = _categoriaInfo(entry.key);
      sb.write(
        '<p class="sf-group-label">${RelatorioHtmlRenderer.escapeHtml(cat.label)} · ${entry.value.length}</p>',
      );
      sb.write('<div class="sf-sheet">');

      for (final data in entry.value) {
        numero++;
        final fotoSrc = RelatorioHtmlRenderer.sanitizePhotoSrc(
          data['foto_base64'] as String?,
        );
        final createdAt = _parseDateTime(data['created_at'] as String?);
        final hora = RelatorioHtmlRenderer.formatTime(createdAt);
        final descricao = (data['description'] as String?)?.trim() ?? '';

        var thumbHtml = '';
        String? fotoLegenda;
        if (fotoSrc.isNotEmpty) {
          fotoNumero++;
          fotoLegenda = 'Foto $fotoNumero';
          thumbHtml =
              '''
          <input type="checkbox" id="sf-lista-foto-$fotoNumero" class="sf-lb-toggle" hidden>
          <label for="sf-lista-foto-$fotoNumero" class="sf-thumb-zoom">
            <img data-sf-photo class="sf-thumb" src="$fotoSrc" alt="$fotoLegenda" loading="lazy">
          </label>''';
        }

        final meta = <String>[
          if (hora.isNotEmpty) hora,
          if (fotoLegenda != null) fotoLegenda,
          if (data['lat'] != null && data['long'] != null)
            'Ponto registrado no mapa',
          if (_isAmostraSolo(data)) 'Amostra de solo coletada',
        ];

        sb.write('''
        <div class="sf-item ocorrencia-row">$thumbHtml
          <div class="sf-item-body">
            <div class="sf-item-head">
              <span class="sf-item-title">Ocorrência $numero</span>
              ${_renderUrgenciaStatus(data['type'])}
            </div>
            ${meta.isEmpty ? '' : '<span class="sf-caption">${meta.join(' · ')}</span>'}
            ${descricao.isEmpty ? '' : '<p class="sf-prose">${RelatorioHtmlRenderer.escapeHtml(descricao)}</p>'}
          </div>
        </div>
        ''');
      }

      sb.write('</div>');
    }
    return sb.toString();
  }

  static String _renderUrgenciaStatus(Object? type) {
    final raw = type?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    final urgenciaClass = _urgenciaClassOrNull(raw);
    final label = urgenciaClass == null
        ? RelatorioHtmlRenderer.escapeHtml(raw)
        : _urgenciaValor(urgenciaClass);
    return '<span class="sf-status"><span class="sf-dot ${urgenciaClass ?? ''}"></span>$label</span>';
  }

  static String? _urgenciaClassOrNull(Object? type) {
    switch (type?.toString().trim().toLowerCase()) {
      case 'alta':
        return 'alta';
      case 'média':
      case 'media':
        return 'media';
      case 'baixa':
        return 'baixa';
      default:
        return null;
    }
  }

  static Future<String> _renderGaleria(
    String? fotosJson, {
    required int firstNumber,
  }) async {
    if (fotosJson == null || fotosJson == '{}') return '';
    final map = _decodeMap(fotosJson);
    if (map.isEmpty) return '';

    final sb = StringBuffer();
    var fotoIndex = 0;
    for (final entry in map.entries) {
      final fotos = _asStringList(entry.value);
      if (fotos.isEmpty) continue;

      final imagens = <String>[];
      for (final path in fotos) {
        final base64 = await RelatorioHtmlRenderer.photoPathToBase64(path);
        if (base64 != null && base64.isNotEmpty) imagens.add(base64);
      }
      if (imagens.isEmpty) continue;

      final cat = _categoriaInfo(entry.key);
      final countLabel = imagens.length == 1
          ? '1 foto'
          : '${imagens.length} fotos';
      sb.write(
        '<p class="sf-group-label">${RelatorioHtmlRenderer.escapeHtml(cat.label)} · $countLabel</p>',
      );
      sb.write('<div class="sf-figure-grid">');
      for (final image in imagens) {
        fotoIndex++;
        final numero = firstNumber + fotoIndex - 1;
        sb.write('''
          <figure class="sf-figure">
            <input type="checkbox" id="sf-foto-$fotoIndex" class="sf-lb-toggle" hidden>
            <label for="sf-foto-$fotoIndex" class="galeria-foto">
              <img data-sf-photo src="$image" alt="Foto $numero" loading="lazy">
            </label>
            <figcaption>Foto $numero</figcaption>
          </figure>
        ''');
      }
      sb.write('</div>');
    }
    return sb.toString();
  }

  static String _section(String title, String body) {
    return '''
    <section class="sf-section">
      <h2 class="sf-section-title"><span class="sf-section-num"></span>$title</h2>
      $body
    </section>
    ''';
  }

  static String _renderNotas(String? notasJson) {
    if (notasJson == null || notasJson == '{}') return '';
    final map = _decodeMap(notasJson);
    if (map.isEmpty) return '';

    final sb = StringBuffer();
    for (final entry in map.entries) {
      final texto = entry.value?.toString().trim() ?? '';
      if (texto.isEmpty) continue;
      final cat = _categoriaInfo(entry.key);
      sb.write('''
        <div class="sf-note">
          <p class="sf-note-label">${RelatorioHtmlRenderer.escapeHtml(cat.label)}</p>
          <p class="sf-prose">${RelatorioHtmlRenderer.escapeHtml(texto)}</p>
        </div>
      ''');
    }
    if (sb.isEmpty) return '';
    return _section('Notas técnicas', sb.toString());
  }

  static String _renderMetricas(String? metricasJson) {
    if (metricasJson == null || metricasJson == '{}') return '';
    final map = _decodeMap(metricasJson);
    if (map.isEmpty) return '';

    final sb = StringBuffer();
    for (final entry in map.entries) {
      final metrics = entry.value is Map ? entry.value as Map : const {};
      final visibleMetrics = metrics.entries
          .where(
            (metric) => metric.value != null && metric.value.toString() != '0',
          )
          .toList();
      if (visibleMetrics.isEmpty) continue;

      final cat = _categoriaInfo(entry.key);
      sb.write(
        '<p class="sf-group-label">${RelatorioHtmlRenderer.escapeHtml(cat.label)}</p>',
      );
      sb.write('<div class="sf-sheet">');
      for (final metric in visibleMetrics) {
        sb.write(
          '<div class="sf-row">'
          '<span class="sf-row-label">${RelatorioHtmlRenderer.escapeHtml(RelatorioHtmlRenderer.humanizeKey(metric.key.toString()))}</span>'
          '<span class="sf-row-value">${RelatorioHtmlRenderer.escapeHtml(metric.value.toString())}</span>'
          '</div>',
        );
      }
      sb.write('</div>');
    }
    if (sb.isEmpty) return '';
    return _section('Métricas avaliadas', sb.toString());
  }

  static String _renderNutrientes(String? nutrientesJson) {
    if (nutrientesJson == null || nutrientesJson == '[]') return '';
    final nutrientes = _decodeList(nutrientesJson)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .map(RelatorioHtmlRenderer.escapeHtml)
        .toList();
    if (nutrientes.isEmpty) return '';

    return _section(
      'Nutrientes identificados',
      '<p class="sf-prose">${nutrientes.join(', ')}</p>',
    );
  }

  static Map<String, dynamic> _decodeMap(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }

  static List<dynamic> _decodeList(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) return decoded;
    } catch (_) {
      return const [];
    }
    return const [];
  }

  static List<String> _asStringList(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String _urgenciaClass(String? type) {
    switch (type?.toLowerCase()) {
      case 'alta':
        return 'alta';
      case 'média':
      case 'media':
        return 'media';
      default:
        return 'baixa';
    }
  }

  static String _urgenciaValor(String urgenciaClass) {
    switch (urgenciaClass) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Média';
      default:
        return 'Baixa';
    }
  }

  static String _formatDataPlantio(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return RelatorioHtmlRenderer.formatDate(dt);
    } catch (_) {
      return iso;
    }
  }

  static DateTime? _parseDateTime(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  static String _localizacaoMapa(Map<String, dynamic> data) {
    final lat = RelatorioHtmlRenderer.readCoordinate(data['lat']);
    final lng = RelatorioHtmlRenderer.readCoordinate(data['long']);
    if (lat == null || lng == null) {
      return '';
    }
    return RelatorioHtmlRenderer.mapLocationAnchor(lat, lng);
  }

  static bool _isAmostraSolo(Map<String, dynamic> data) {
    final value = data['amostra_solo'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    return false;
  }

  static _CatInfo _categoriaInfo(String? cat) {
    switch (cat) {
      case 'doenca':
        return const _CatInfo('Doença');
      case 'insetos':
        return const _CatInfo('Insetos');
      case 'ervas_daninhas':
      case 'daninhas':
        return const _CatInfo('Ervas Daninhas');
      case 'nutrientes':
      case 'nutricional':
        return const _CatInfo('Nutrientes');
      case 'agua':
        return const _CatInfo('Água');
      case 'amostra_solo':
        return const _CatInfo('Solo');
      default:
        return const _CatInfo('Ocorrência');
    }
  }
}

class _CatInfo {
  final String label;

  const _CatInfo(this.label);
}
