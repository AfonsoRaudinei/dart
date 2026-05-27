import 'relatorio_html_renderer.dart';

class OcorrenciaHtmlRenderer {
  /// [data] = Occurrence convertido para Map pelo chamador.
  ///
  /// Estrutura esperada: campos do schema occurrences e campos calculados
  /// opcionais: categoria_emoji, categoria_label, urgencia_class, foto_base64.
  static Future<String> renderDetalhe(Map<String, dynamic> data) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'ocorrencia_detalhada.html',
    );

    final category = data['category'] as String? ?? '';
    final cat = _categoriaInfo(category);

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
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

    final galeria = _renderGaleria(data['fotos_categorias_json'] as String?);
    tpl = tpl.replaceAll('<!-- {{FOTOS_CATEGORIAS_LOOP}} -->', galeria);

    final notas = _renderNotas(data['notas_categorias_json'] as String?);
    tpl = tpl.replaceAll('<!-- {{NOTAS_CATEGORIAS_LOOP}} -->', notas);

    final metricas = _renderMetricas(data['metricas_json'] as String?);
    tpl = tpl.replaceAll('<!-- {{METRICAS_LOOP}} -->', metricas);

    final nutrientes = _renderNutrientes(data['nutrientes_json'] as String?);
    tpl = tpl.replaceAll('<!-- {{NUTRIENTES_LOOP}} -->', nutrientes);

    return tpl;
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
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'ocorrencias_lista.html',
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
    tpl = tpl.replaceAll('<!-- {{GRUPOS_LOOP}} -->', grupos);

    return tpl;
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

  static String _renderGaleria(String? fotosJson) {
    if (fotosJson == null || fotosJson == '{}') return '';
    return '';
  }

  static String _renderNotas(String? notasJson) {
    if (notasJson == null || notasJson == '{}') return '';
    return '';
  }

  static String _renderMetricas(String? metricasJson) {
    if (metricasJson == null || metricasJson == '{}') return '';
    return '';
  }

  static String _renderNutrientes(String? nutrientesJson) {
    if (nutrientesJson == null || nutrientesJson == '[]') return '';
    return '';
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
