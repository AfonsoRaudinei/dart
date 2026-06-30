import 'dart:convert';

import 'relatorio_html_renderer.dart';

class OcorrenciaHtmlRenderer {
  /// [data] = Occurrence convertido para Map pelo chamador.
  ///
  /// Estrutura esperada: campos do schema occurrences e campos calculados
  /// opcionais: categoria_emoji, categoria_label, urgencia_class, foto_base64.
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

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'categoria_emoji': data['categoria_emoji'] as String? ?? cat.emoji,
      'categoria_label': data['categoria_label'] as String? ?? cat.label,
      'category': category,
      'type': RelatorioHtmlRenderer.escapeHtml(data['type'] as String? ?? ''),
      'urgencia_class':
          data['urgencia_class'] as String? ??
          _urgenciaClass(data['type'] as String?),
      'status': RelatorioHtmlRenderer.escapeHtml(
        data['status'] as String? ?? 'draft',
      ),
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
      'created_at_formatado': RelatorioHtmlRenderer.formatDateTime(
        _parseDateTime(data['created_at'] as String?),
      ),
      'updated_at_formatado': RelatorioHtmlRenderer.formatDateTime(
        _parseDateTime(data['updated_at'] as String?),
      ),
      'id_curto': RelatorioHtmlRenderer.shortId(data['id'] as String? ?? ''),
      'sync_status': data['sync_status'] as String? ?? '',
    });

    final galeria = await _renderGaleria(
      data['fotos_categorias_json'] as String?,
    );
    final notas = _renderNotas(data['notas_categorias_json'] as String?);
    final metricas = _renderMetricas(data['metricas_json'] as String?);
    final nutrientes = _renderNutrientes(data['nutrientes_json'] as String?);

    tpl = _resolveRepeatedIf(
      tpl,
      'status',
      (data['status'] as String?)?.isNotEmpty == true,
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

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
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

    final alta = ocorrencias.where((data) => data['type'] == 'Alta').length;
    final media = ocorrencias.where((data) => data['type'] == 'Média').length;
    final baixa = ocorrencias.where((data) => data['type'] == 'Baixa').length;

    final pctAlta = total > 0 ? (alta / total * 100).round() : 0;
    final pctMedia = total > 0 ? (media / total * 100).round() : 0;
    final pctBaixa = total > 0 ? (baixa / total * 100).round() : 0;

    final cats = ocorrencias
        .map((data) => data['category'] as String? ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'fazenda_nome': RelatorioHtmlRenderer.escapeHtml(fazendaNome),
      'talhao_nome': RelatorioHtmlRenderer.escapeHtml(talhaoNome),
      'cultivar': RelatorioHtmlRenderer.escapeHtml(cultivar),
      'agronomist_nome': RelatorioHtmlRenderer.escapeHtml(agronomistNome),
      'data_visita_formatada': RelatorioHtmlRenderer.formatDate(dataVisita),
      'total_ocorrencias': total.toString(),
      'total_categorias': cats.toString(),
      'total_fotos': totalFotos.toString(),
      'amostras_solo': amostras.toString(),
      'count_alta': alta.toString(),
      'count_media': media.toString(),
      'count_baixa': baixa.toString(),
      'pct_alta': pctAlta.toString(),
      'pct_media': pctMedia.toString(),
      'pct_baixa': pctBaixa.toString(),
      'gerado_em_formatado': RelatorioHtmlRenderer.geradoEm(),
      'visit_session_id_curto': visitSessionId != null
          ? RelatorioHtmlRenderer.shortId(visitSessionId)
          : '',
    });

    final grupos = await _renderGrupos(ocorrencias);
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'grupos.length > 0',
      include: grupos.isNotEmpty,
      truthyHtml: grupos,
      falsyHtml:
          '<div class="empty-state"><div class="empty-state-emoji">🌾</div><div class="empty-state-text">Nenhuma ocorrência registrada nesta visita.</div></div>',
    );

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
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

  static Future<String> _renderGrupos(
    List<Map<String, dynamic>> ocorrencias,
  ) async {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final data in ocorrencias) {
      final key = data['category'] as String? ?? 'outro';
      grouped.putIfAbsent(key, () => []).add(data);
    }

    final sb = StringBuffer();
    for (final entry in grouped.entries) {
      final cat = _categoriaInfo(entry.key);
      sb.write('<div class="grupo-categoria">');
      sb.write('''
        <div class="grupo-header">
          <span class="grupo-emoji">${cat.emoji}</span>
          <span class="grupo-titulo">${cat.label}</span>
          <span class="grupo-count">${entry.value.length}</span>
        </div>
      ''');

      for (final data in entry.value) {
        final fotoB64 = data['foto_base64'] as String?;
        final urgClass =
            data['urgencia_class'] as String? ??
            _urgenciaClass(data['type'] as String?);
        final hasLoc = data['lat'] != null && data['long'] != null;
        final createdAt = _parseDateTime(data['created_at'] as String?);

        sb.write('''
        <div class="ocorrencia-card">
          <div class="ocorrencia-foto">
            ${fotoB64 != null && fotoB64.isNotEmpty ? '<img src="$fotoB64" alt="Foto" loading="lazy">' : _svgPlaceholder()}
          </div>
          <div class="ocorrencia-info">
            <div class="ocorrencia-top">
              <span class="ocorrencia-urg-tag $urgClass">${RelatorioHtmlRenderer.escapeHtml(data['type'] as String?)}</span>
              <span class="ocorrencia-id">#${RelatorioHtmlRenderer.shortId(data['id'] as String? ?? '')}</span>
            </div>
            <div class="ocorrencia-descricao">${RelatorioHtmlRenderer.escapeHtml(data['description'] as String?)}</div>
            <div class="ocorrencia-meta">
              <span class="ocorrencia-meta-item">
                <svg viewBox="0 0 24 24"><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2zm.5 11H8v-2h2.5V7H13v6z"/></svg>
                ${RelatorioHtmlRenderer.formatTime(createdAt)}
              </span>
              ${hasLoc ? '<span class="ocorrencia-meta-item"><svg viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>Georreferenciada</span>' : ''}
              ${_isAmostraSolo(data) ? '<span class="ocorrencia-meta-item">🪨 Amostra coletada</span>' : ''}
            </div>
          </div>
        </div>
        ''');
      }

      sb.write('</div>');
    }
    return sb.toString();
  }

  static Future<String> _renderGaleria(String? fotosJson) async {
    if (fotosJson == null || fotosJson == '{}') return '';
    final map = _decodeMap(fotosJson);
    if (map.isEmpty) return '';

    final sb = StringBuffer();
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
      sb.write('''
        <div class="galeria-grupo">
          <div class="galeria-grupo-header">
            <span class="galeria-grupo-emoji">${cat.emoji}</span>
            <span class="galeria-grupo-nome">${RelatorioHtmlRenderer.escapeHtml(cat.label)}</span>
            <span class="galeria-grupo-count">${imagens.length} fotos</span>
          </div>
          <div class="galeria-grid">
      ''');
      for (final image in imagens) {
        sb.write('''
            <div class="galeria-foto">
              <img src="$image" alt="Foto" loading="lazy">
            </div>
        ''');
      }
      sb.write('''
          </div>
        </div>
      ''');
    }
    return sb.toString();
  }

  static String _renderNotas(String? notasJson) {
    if (notasJson == null || notasJson == '{}') return '';
    final map = _decodeMap(notasJson);
    if (map.isEmpty) return '';

    final sb = StringBuffer();
    sb.write('<div class="notas-list">');
    for (final entry in map.entries) {
      final texto = entry.value?.toString().trim() ?? '';
      if (texto.isEmpty) continue;
      final cat = _categoriaInfo(entry.key);
      sb.write('''
        <div class="nota-item">
          <div class="nota-header">
            <span class="nota-emoji">${cat.emoji}</span>
            <span class="nota-categoria">${RelatorioHtmlRenderer.escapeHtml(cat.label)}</span>
          </div>
          <div class="nota-texto">${RelatorioHtmlRenderer.escapeHtml(texto)}</div>
        </div>
      ''');
    }
    sb.write('</div>');
    return sb.toString();
  }

  static String _renderMetricas(String? metricasJson) {
    if (metricasJson == null || metricasJson == '{}') return '';
    final map = _decodeMap(metricasJson);
    if (map.isEmpty) return '';

    final sb = StringBuffer();
    sb.write('<div class="metricas-block">');
    for (final entry in map.entries) {
      final metrics = entry.value is Map ? entry.value as Map : const {};
      final visibleMetrics = metrics.entries
          .where(
            (metric) => metric.value != null && metric.value.toString() != '0',
          )
          .toList();
      if (visibleMetrics.isEmpty) continue;

      final cat = _categoriaInfo(entry.key);
      sb.write('''
        <div class="metricas-grupo">
          <div class="metricas-grupo-titulo">
            <span>${cat.emoji}</span>
            <span>${RelatorioHtmlRenderer.escapeHtml(cat.label)}</span>
          </div>
          <div class="metricas-items">
      ''');
      for (final metric in visibleMetrics) {
        sb.write('''
            <div class="metrica-item">
              <span class="metrica-nome">${RelatorioHtmlRenderer.escapeHtml(_metricLabel(metric.key.toString()))}</span>
              <span class="metrica-valor">${RelatorioHtmlRenderer.escapeHtml(metric.value.toString())}</span>
            </div>
        ''');
      }
      sb.write('''
          </div>
        </div>
      ''');
    }
    sb.write('</div>');
    return sb.toString();
  }

  static String _renderNutrientes(String? nutrientesJson) {
    if (nutrientesJson == null || nutrientesJson == '[]') return '';
    final nutrientes = _decodeList(nutrientesJson)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (nutrientes.isEmpty) return '';

    final sb = StringBuffer();
    sb.write('<div class="nutrientes-list">');
    for (final nutriente in nutrientes) {
      sb.write(
        '<span class="nutriente-badge">${RelatorioHtmlRenderer.escapeHtml(nutriente)}</span>',
      );
    }
    sb.write('</div>');
    return sb.toString();
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

  static String _metricLabel(String key) {
    return key.replaceAll('_', ' ');
  }

  static String _svgPlaceholder() => '''
    <div class="ocorrencia-foto-placeholder">
      <svg viewBox="0 0 24 24" fill="#9CA3AF">
        <path d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"/>
      </svg>
    </div>
  ''';

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

  static bool _isAmostraSolo(Map<String, dynamic> data) {
    final value = data['amostra_solo'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    return false;
  }

  static _CatInfo _categoriaInfo(String? cat) {
    switch (cat) {
      case 'doenca':
        return const _CatInfo('🦠', 'Doença');
      case 'insetos':
        return const _CatInfo('🐛', 'Insetos');
      case 'ervas_daninhas':
      case 'daninhas':
        return const _CatInfo('🌿', 'Ervas Daninhas');
      case 'nutrientes':
      case 'nutricional':
        return const _CatInfo('🧪', 'Nutrientes');
      case 'agua':
        return const _CatInfo('💧', 'Água');
      case 'amostra_solo':
        return const _CatInfo('🪨', 'Solo');
      default:
        return const _CatInfo('📍', 'Ocorrência');
    }
  }
}

class _CatInfo {
  final String emoji;
  final String label;

  const _CatInfo(this.emoji, this.label);
}
