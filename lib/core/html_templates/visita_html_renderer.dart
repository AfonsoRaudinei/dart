import 'relatorio_html_renderer.dart';

class VisitaHtmlRenderer {
  /// Renderiza T-R1 a partir de um relatório técnico serializado.
  ///
  /// [relatorio] deve seguir o formato de RelatorioTecnico.toJson().
  /// O renderer fica em core/ e não importa tipos de modules/.
  static Future<String> render({
    required Map<String, dynamic> relatorio,
    required String agronomistNome,
    required String clienteNome,
    required Map<String, String> publicacoesTitulos,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantRole,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate('relatorio_visita.html');
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: reportBrandName,
      customLogoPath: reportLogoPath,
      consultantName: agronomistNome,
      consultantRole: consultantRole,
    );

    final status = _string(relatorio['status'], fallback: 'pendente_revisao');
    final title = _string(relatorio['title']);
    final farmName = _string(relatorio['farmName']);
    final titleOuFarm = title.isNotEmpty ? title : farmName;
    final ocorrencias = _listOfMaps(relatorio['ocorrencias']);
    final talhoes = _listOfMaps(relatorio['talhoes']);
    final monitoramentos = _listOfMaps(relatorio['monitoramentos']);
    final fotos = _listOfStrings(relatorio['fotos']);
    final publicacoesRefs = _listOfStrings(relatorio['publicacoesRefs']);

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'status': RelatorioHtmlRenderer.escapeHtml(status),
      'status_label': _statusLabel(status),
      'title_ou_farm_name': RelatorioHtmlRenderer.escapeHtml(titleOuFarm),
      'farm_name': RelatorioHtmlRenderer.escapeHtml(farmName),
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'agronomist_nome': RelatorioHtmlRenderer.escapeHtml(agronomistNome),
      'period_start_formatado': _formatIsoDateTime(relatorio['periodStart']),
      'period_end_formatado': _formatIsoDateTime(relatorio['periodEnd']),
      'custom_notes': RelatorioHtmlRenderer.escapeHtml(
        _string(relatorio['customNotes']),
      ),
      'ocorrencias_count': ocorrencias.length.toString(),
      'id_curto': RelatorioHtmlRenderer.shortId(_string(relatorio['id'])),
      'gerado_em_formatado': RelatorioHtmlRenderer.geradoEm(),
    });

    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'custom_notes',
      include: _string(relatorio['customNotes']).isNotEmpty,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'talhoes.length > 0',
      include: talhoes.isNotEmpty,
      truthyHtml: '<div class="talhao-list">${_renderTalhoes(talhoes)}</div>',
      falsyHtml:
          '<div class="empty-section">Nenhum talhão registrado nesta visita.</div>',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'ocorrencias.length > 0',
      include: ocorrencias.isNotEmpty,
      truthyHtml:
          '''
    <div class="section-label">
      <div class="section-label-bar"></div>
      <span class="section-label-text">Ocorrências Registradas</span>
    </div>
    ${_renderOcorrenciasSummary(ocorrencias)}
    <div class="ocorrencia-list">${await _renderOcorrencias(ocorrencias)}</div>
    ''',
      falsyHtml: '''
    <div class="section-label">
      <div class="section-label-bar"></div>
      <span class="section-label-text">Ocorrências Registradas</span>
    </div>
    <div class="ocorrencia-empty">Nenhuma ocorrência foi registrada nesta visita.</div>
    ''',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'monitoramentos.length > 0',
      include: monitoramentos.isNotEmpty,
      truthyHtml:
          '''
    <div class="section-label">
      <div class="section-label-bar"></div>
      <span class="section-label-text">Monitoramentos</span>
    </div>
    <div class="monitoramento-list">${_renderMonitoramentos(monitoramentos)}</div>
    ''',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'fotos.length > 0',
      include: fotos.isNotEmpty,
      truthyHtml:
          '''
    <div class="section-label">
      <div class="section-label-bar"></div>
      <span class="section-label-text">Registro Fotográfico</span>
    </div>
    <div class="fotos-grid">${await _renderFotos(fotos)}</div>
    ''',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'publicacoes_refs.length > 0',
      include: publicacoesRefs.isNotEmpty,
      truthyHtml:
          '''
    <div class="section-label">
      <div class="section-label-bar"></div>
      <span class="section-label-text">Publicações Técnicas</span>
    </div>
    <div class="publicacoes-list">${_renderPublicacoes(publicacoesRefs, publicacoesTitulos)}</div>
    ''',
    );

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
  }

  static String _renderTalhoes(List<Map<String, dynamic>> talhoes) {
    if (talhoes.isEmpty) return '';
    final sb = StringBuffer();
    for (final talhao in talhoes) {
      final nome = RelatorioHtmlRenderer.escapeHtml(
        _string(talhao['nomeTalhao']),
      );
      final cultura = RelatorioHtmlRenderer.escapeHtml(
        _string(talhao['cultura']),
      );
      final safra = RelatorioHtmlRenderer.escapeHtml(_string(talhao['safra']));
      final area = _double(talhao['areaHectares']);

      sb.write('''
      <div class="talhao-card">
        <div>
          <div class="talhao-nome">$nome</div>
          <div class="talhao-meta">
            ${cultura.isNotEmpty ? '<span class="talhao-chip">Cultura: $cultura</span>' : ''}
            ${safra.isNotEmpty ? '<span class="talhao-chip">Safra: $safra</span>' : ''}
          </div>
        </div>
        ${area != null ? '<div class="talhao-area">${RelatorioHtmlRenderer.formatHectares(area)}<span class="talhao-area-unit">ha</span></div>' : ''}
      </div>
      ''');
    }
    return sb.toString();
  }

  static Future<String> _renderOcorrencias(
    List<Map<String, dynamic>> ocorrencias,
  ) async {
    if (ocorrencias.isEmpty) return '';
    final sb = StringBuffer();
    for (final ocorrencia in ocorrencias) {
      final tipo = RelatorioHtmlRenderer.escapeHtml(
        _string(ocorrencia['tipo']),
      );
      final severity = _stringOrNull(ocorrencia['severity']);
      final data = _formatIsoDate(ocorrencia['registradaEm']);
      final hora = _formatIsoTime(ocorrencia['registradaEm']);
      final meta = <String>[
        if (data.isNotEmpty && hora.isNotEmpty) '$data · $hora',
        if (data.isNotEmpty && hora.isEmpty) data,
      ];
      final detailMeta = <String>[
        if (_stringOrNull(ocorrencia['cultivar']) case final cultivar?)
          'Cultivar: ${RelatorioHtmlRenderer.escapeHtml(cultivar)}',
        if (_stringOrNull(ocorrencia['estadioFenologico']) case final estadio?)
          'Estádio: ${RelatorioHtmlRenderer.escapeHtml(estadio)}',
        if (_stringOrNull(ocorrencia['tipoOcorrencia']) case final categoria?)
          'Categoria: ${RelatorioHtmlRenderer.escapeHtml(categoria)}',
      ];
      final fotosHtml = await _renderOcorrenciaFotos(ocorrencia);
      final descricaoHtml = _renderOcorrenciaSection(
        label: 'Descrição',
        content: _stringOrNull(ocorrencia['descricao']),
      );
      final recomendacoesHtml = _renderOcorrenciaSection(
        label: 'Recomendação',
        content: _stringOrNull(ocorrencia['recomendacoes']),
      );
      final localizacaoHtml = _renderOcorrenciaLocation(ocorrencia);

      sb.write('''
      <div class="ocorrencia-card">
        <div class="ocorrencia-info">
          <div class="ocorrencia-header">
            <span class="ocorrencia-tipo">$tipo</span>
            ${_renderSeverityBadge(severity)}
          </div>
          <div class="ocorrencia-meta">
            ${meta.map((item) => '<span class="ocorrencia-meta-item">${RelatorioHtmlRenderer.escapeHtml(item)}</span>').join()}
          </div>
          ${detailMeta.isEmpty ? '' : '<div class="ocorrencia-details">${detailMeta.map((item) => '<span class="ocorrencia-detail-item">$item</span>').join()}</div>'}
          $descricaoHtml
          $recomendacoesHtml
          $localizacaoHtml
          $fotosHtml
        </div>
      </div>
      ''');
    }
    return sb.toString();
  }

  static String _renderOcorrenciasSummary(
    List<Map<String, dynamic>> ocorrencias,
  ) {
    final grave = ocorrencias
        .where(
          (ocorrencia) => _matchesSeverity(ocorrencia['severity'], 'grave'),
        )
        .length;
    final moderada = ocorrencias
        .where(
          (ocorrencia) => _matchesSeverity(ocorrencia['severity'], 'moderada'),
        )
        .length;
    final leve = ocorrencias
        .where((ocorrencia) => _matchesSeverity(ocorrencia['severity'], 'leve'))
        .length;

    return '''
    <div class="ocorrencia-summary">
      <div class="ocorrencia-summary-title">OCORRÊNCIAS REGISTRADAS (${ocorrencias.length})</div>
      <div class="ocorrencia-summary-meta">Grave: $grave · Moderada: $moderada · Leve: $leve</div>
    </div>
    ''';
  }

  static String _renderSeverityBadge(String? severity) {
    final normalized = severity?.trim();
    if (normalized == null || normalized.isEmpty) return '';
    final badgeClass = switch (normalized.toLowerCase()) {
      'leve' => 'ocorrencia-badge ocorrencia-badge-leve',
      'moderada' => 'ocorrencia-badge ocorrencia-badge-moderada',
      'grave' => 'ocorrencia-badge ocorrencia-badge-grave',
      _ => '',
    };
    if (badgeClass.isEmpty) return '';
    return '<span class="$badgeClass">${RelatorioHtmlRenderer.escapeHtml(normalized)}</span>';
  }

  static String _renderOcorrenciaSection({
    required String label,
    required String? content,
  }) {
    final normalized = content?.trim();
    if (normalized == null || normalized.isEmpty) return '';
    return '''
    <div class="ocorrencia-section">
      <div class="ocorrencia-section-label">$label</div>
      <div class="ocorrencia-section-content">${RelatorioHtmlRenderer.escapeHtml(normalized)}</div>
    </div>
    ''';
  }

  static String _renderOcorrenciaLocation(Map<String, dynamic> ocorrencia) {
    final lat = _double(ocorrencia['lat']);
    final lng = _double(ocorrencia['lng']);
    if (lat == null || lng == null) return '';
    return '''
    <div class="ocorrencia-location">📍 ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}</div>
    ''';
  }

  static Future<String> _renderOcorrenciaFotos(
    Map<String, dynamic> ocorrencia,
  ) async {
    final fotoPaths = _resolveFotoPaths(ocorrencia);
    if (fotoPaths.isEmpty) return '';

    final items = <String>[];
    for (final path in fotoPaths) {
      final fotoB64 = await RelatorioHtmlRenderer.photoPathToBase64(path);
      if (fotoB64 == null) continue;
      items.add(
        '<img class="ocorrencia-photo" src="$fotoB64" alt="Foto da ocorrência" loading="lazy">',
      );
    }
    if (items.isEmpty) return '';
    return '<div class="ocorrencia-photos">${items.join()}</div>';
  }

  static List<String> _resolveFotoPaths(Map<String, dynamic> ocorrencia) {
    final fotoPaths = <String>[];
    final rawList = ocorrencia['fotoPaths'];
    if (rawList is List) {
      for (final item in rawList) {
        final path = item?.toString().trim();
        if (path != null && path.isNotEmpty) {
          fotoPaths.add(path);
        }
      }
    }
    if (fotoPaths.isNotEmpty) return fotoPaths;
    final fotoPath = _stringOrNull(ocorrencia['fotoPath']);
    return fotoPath == null ? const [] : [fotoPath];
  }

  static bool _matchesSeverity(Object? severity, String expected) {
    final normalized = severity?.toString().trim().toLowerCase();
    return normalized == expected;
  }

  static String _renderMonitoramentos(
    List<Map<String, dynamic>> monitoramentos,
  ) {
    if (monitoramentos.isEmpty) return '';
    final sb = StringBuffer();
    for (final monitoramento in monitoramentos) {
      final tipo = RelatorioHtmlRenderer.escapeHtml(
        _string(monitoramento['tipo']),
      );
      final data = _formatIsoDateTime(monitoramento['coletadoEm']);
      final dados = _map(monitoramento['dados']);
      final dadosHtml = dados.entries
          .map(
            (entry) =>
                '''
        <div class="dado-item">
          <div class="dado-chave">${RelatorioHtmlRenderer.escapeHtml(entry.key)}</div>
          <div class="dado-valor">${RelatorioHtmlRenderer.escapeHtml(entry.value?.toString())}</div>
        </div>
      ''',
          )
          .join();

      sb.write('''
      <div class="monitoramento-card">
        <div class="monitoramento-header">
          <div class="monitoramento-tipo">$tipo</div>
          <div class="monitoramento-data">$data</div>
        </div>
        <div class="monitoramento-dados">$dadosHtml</div>
      </div>
      ''');
    }
    return sb.toString();
  }

  static Future<String> _renderFotos(List<String> fotos) async {
    if (fotos.isEmpty) return '';
    final sb = StringBuffer();
    for (final path in fotos) {
      final b64 = await RelatorioHtmlRenderer.photoPathToBase64(path);
      if (b64 != null) {
        sb.write('''
        <div class="foto-item">
          <img src="$b64" alt="Foto da visita" loading="lazy">
        </div>
        ''');
      }
    }
    return sb.toString();
  }

  static String _renderPublicacoes(
    List<String> refs,
    Map<String, String> titulos,
  ) {
    if (refs.isEmpty) return '';
    final sb = StringBuffer();
    for (final ref in refs) {
      final titulo = RelatorioHtmlRenderer.escapeHtml(
        titulos[ref] ?? 'Publicação ${RelatorioHtmlRenderer.shortId(ref)}',
      );
      sb.write('''
      <div class="publicacao-badge">
        $titulo
      </div>
      ''');
    }
    return sb.toString();
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'publicado':
        return 'Publicado';
      case 'arquivado':
        return 'Arquivado';
      default:
        return 'Em Revisão';
    }
  }

  static String _formatIsoDateTime(Object? value) {
    final raw = _string(value);
    if (raw.isEmpty) return '';
    try {
      return RelatorioHtmlRenderer.formatDateTime(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  static String _formatIsoDate(Object? value) {
    final raw = _string(value);
    if (raw.isEmpty) return '';
    try {
      return RelatorioHtmlRenderer.formatDate(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  static String _formatIsoTime(Object? value) {
    final raw = _string(value);
    if (raw.isEmpty) return '';
    try {
      return RelatorioHtmlRenderer.formatTime(DateTime.parse(raw));
    } catch (_) {
      return '';
    }
  }

  static String _string(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  static String? _stringOrNull(Object? value) {
    final text = _string(value);
    return text.isEmpty ? null : text;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_string(value).replaceAll(',', '.'));
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<String> _listOfStrings(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}
