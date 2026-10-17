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
    final periodStart = _formatIsoDateTime(relatorio['periodStart']);
    final periodEnd = _formatIsoDateTime(relatorio['periodEnd']);
    final role = consultantRole?.trim() ?? '';
    final periodo = _periodoLinha(relatorio);
    final contextoLinha = [
      if (title.isNotEmpty && farmName.isNotEmpty)
        RelatorioHtmlRenderer.escapeHtml(farmName),
      if (clienteNome.trim().isNotEmpty)
        RelatorioHtmlRenderer.escapeHtml(clienteNome.trim()),
      if (periodo.isNotEmpty) periodo,
    ].join(' · ');

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'status': RelatorioHtmlRenderer.escapeHtml(status),
      'status_label': _statusLabel(status),
      'status_dot': _statusDot(status),
      'title_ou_farm_name': RelatorioHtmlRenderer.escapeHtml(titleOuFarm),
      'contexto_linha': contextoLinha,
      'farm_name': RelatorioHtmlRenderer.escapeHtml(farmName),
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'agronomist_nome': RelatorioHtmlRenderer.escapeHtml(agronomistNome),
      'consultant_role': RelatorioHtmlRenderer.escapeHtml(role),
      'emitido_em': RelatorioHtmlRenderer.formatDate(DateTime.now()),
      'period_start_formatado': periodStart,
      'period_end_formatado': periodEnd,
      'custom_notes': RelatorioHtmlRenderer.escapeHtml(
        _string(relatorio['customNotes']),
      ),
      'ocorrencias_count': ocorrencias.length.toString(),
      'id_curto': RelatorioHtmlRenderer.shortId(_string(relatorio['id'])),
      'gerado_em_formatado': RelatorioHtmlRenderer.geradoEm(),
    });

    tpl = _resolveRepeatedIf(tpl, 'contexto_linha', contextoLinha.isNotEmpty);
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'ficha_tecnica',
      include:
          clienteNome.trim().isNotEmpty ||
          farmName.isNotEmpty ||
          periodStart.isNotEmpty ||
          periodEnd.isNotEmpty,
    );
    tpl = _resolveRepeatedIf(
      tpl,
      'agronomist_nome',
      agronomistNome.trim().isNotEmpty,
    );
    tpl = _resolveRepeatedIf(tpl, 'consultant_role', role.isNotEmpty);
    tpl = _resolveRepeatedIf(
      tpl,
      'cliente_nome',
      clienteNome.trim().isNotEmpty,
    );
    tpl = _resolveRepeatedIf(tpl, 'farm_name', farmName.isNotEmpty);
    tpl = _resolveRepeatedIf(tpl, 'period_start', periodStart.isNotEmpty);
    tpl = _resolveRepeatedIf(tpl, 'period_end', periodEnd.isNotEmpty);
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'custom_notes',
      include: _string(relatorio['customNotes']).isNotEmpty,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'talhoes.length > 0',
      include: talhoes.isNotEmpty,
      truthyHtml: '<div class="sf-sheet">${_renderTalhoes(talhoes)}</div>',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'ocorrencias.length > 0',
      include: ocorrencias.isNotEmpty,
      truthyHtml:
          '''
    ${_renderOcorrenciasSummary(ocorrencias)}
    <div class="sf-sheet">${await _renderOcorrencias(ocorrencias)}</div>
    ''',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'monitoramentos.length > 0',
      include: monitoramentos.isNotEmpty,
      truthyHtml: _section(
        'Monitoramentos',
        _renderMonitoramentos(monitoramentos),
      ),
    );
    final fotosHtml = await _renderFotos(fotos);
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'fotos.length > 0',
      include: fotosHtml.isNotEmpty,
      truthyHtml: _section(
        'Registro fotográfico',
        '<div class="sf-figure-grid">$fotosHtml</div>',
      ),
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'publicacoes_refs.length > 0',
      include: publicacoesRefs.isNotEmpty,
      truthyHtml: _section(
        'Publicações técnicas',
        '<div class="sf-sheet">${_renderPublicacoes(publicacoesRefs, publicacoesTitulos)}</div>',
      ),
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

  static String _section(String title, String body) {
    return '''
    <section class="sf-section">
      <h2 class="sf-section-title"><span class="sf-section-num"></span>$title</h2>
      $body
    </section>
    ''';
  }

  /// `03/06/2026 · 09:00–10:00` no mesmo dia; senão `início – fim`.
  static String _periodoLinha(Map<String, dynamic> relatorio) {
    final start = _parseIso(relatorio['periodStart']);
    final end = _parseIso(relatorio['periodEnd']);
    if (start == null) return '';
    final startDate = RelatorioHtmlRenderer.formatDate(start);
    final startTime = RelatorioHtmlRenderer.formatTime(start);
    if (end == null) return '$startDate · $startTime';
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '$startDate · $startTime–${RelatorioHtmlRenderer.formatTime(end)}';
    }
    return '${RelatorioHtmlRenderer.formatDateTime(start)} – '
        '${RelatorioHtmlRenderer.formatDateTime(end)}';
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
      final sub = [
        if (cultura.isNotEmpty) 'Cultura: $cultura',
        if (safra.isNotEmpty) 'Safra: $safra',
      ].join(' · ');

      sb.write('''
      <div class="sf-row talhao-row">
        <span class="sf-row-label"><span class="sf-item-title">$nome</span>${sub.isNotEmpty ? '<span class="sf-row-sub">$sub</span>' : ''}</span>
        ${area != null ? '<span class="sf-row-value">${RelatorioHtmlRenderer.formatHectares(area)} ha</span>' : ''}
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
        if (_stringOrNull(ocorrencia['tipoOcorrencia']) case final categoria?)
          RelatorioHtmlRenderer.escapeHtml(categoria),
        if (_stringOrNull(ocorrencia['cultivar']) case final cultivar?)
          'Cultivar ${RelatorioHtmlRenderer.escapeHtml(cultivar)}',
        if (_stringOrNull(ocorrencia['estadioFenologico']) case final estadio?)
          'Estádio ${RelatorioHtmlRenderer.escapeHtml(estadio)}',
        if (_hasLocation(ocorrencia)) 'Ponto registrado no mapa',
      ];
      final fotos = await _resolveOcorrenciaFotos(ocorrencia);
      final descricao = _stringOrNull(ocorrencia['descricao'])?.trim() ?? '';
      final recomendacao =
          _stringOrNull(ocorrencia['recomendacoes'])?.trim() ?? '';
      final thumbHtml = fotos.isEmpty
          ? ''
          : '<img data-sf-photo class="sf-thumb" src="${fotos.first}" alt="Foto da ocorrência" loading="lazy">';
      final stripHtml = fotos.length > 1
          ? '<div class="sf-thumb-strip">${fotos.skip(1).map((src) => '<img data-sf-photo class="sf-thumb" src="$src" alt="Foto da ocorrência" loading="lazy">').join()}</div>'
          : '';

      sb.write('''
      <div class="sf-item ocorrencia-row">
        $thumbHtml
        <div class="sf-item-body">
          <div class="sf-item-head">
            <span class="sf-item-title">$tipo</span>
            ${_renderSeverityStatus(severity)}
          </div>
          ${meta.isEmpty ? '' : '<span class="sf-caption">${meta.join(' · ')}</span>'}
          ${descricao.isEmpty ? '' : '<p class="sf-prose">${RelatorioHtmlRenderer.escapeHtml(descricao)}</p>'}
          ${recomendacao.isEmpty ? '' : '<div class="sf-callout"><p class="sf-note-label">Recomendação</p><p class="sf-prose">${RelatorioHtmlRenderer.escapeHtml(recomendacao)}</p></div>'}
          $stripHtml
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
    final total = ocorrencias.length;
    final totalLabel = total == 1 ? '1 ocorrência' : '$total ocorrências';

    return '''
    <p class="sf-section-caption ocorrencia-summary">$totalLabel · Grave: $grave · Moderada: $moderada · Leve: $leve</p>
    ''';
  }

  static String _renderSeverityStatus(String? severity) {
    final normalized = severity?.trim();
    if (normalized == null || normalized.isEmpty) return '';
    final dotClass = switch (normalized.toLowerCase()) {
      'leve' => 'baixa',
      'moderada' => 'media',
      'grave' => 'alta',
      _ => '',
    };
    if (dotClass.isEmpty) return '';
    final label =
        normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
    return '<span class="sf-status"><span class="sf-dot $dotClass"></span>${RelatorioHtmlRenderer.escapeHtml(label)}</span>';
  }

  static bool _hasLocation(Map<String, dynamic> ocorrencia) {
    return _double(ocorrencia['lat']) != null &&
        _double(ocorrencia['lng']) != null;
  }

  static Future<List<String>> _resolveOcorrenciaFotos(
    Map<String, dynamic> ocorrencia,
  ) async {
    final items = <String>[];
    for (final path in _resolveFotoPaths(ocorrencia)) {
      final fotoB64 = await RelatorioHtmlRenderer.photoPathToBase64(path);
      if (fotoB64 == null) continue;
      items.add(fotoB64);
    }
    return items;
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
                '<div class="sf-row">'
                '<span class="sf-row-label">${RelatorioHtmlRenderer.escapeHtml(RelatorioHtmlRenderer.humanizeKey(entry.key))}</span>'
                '<span class="sf-row-value">${RelatorioHtmlRenderer.escapeHtml(entry.value?.toString())}</span>'
                '</div>',
          )
          .join();

      sb.write('''
      <p class="sf-group-label">$tipo${data.isNotEmpty ? ' · $data' : ''}</p>
      ${dadosHtml.isEmpty ? '' : '<div class="sf-sheet">$dadosHtml</div>'}
      ''');
    }
    return sb.toString();
  }

  static Future<String> _renderFotos(List<String> fotos) async {
    if (fotos.isEmpty) return '';
    final sb = StringBuffer();
    var numero = 0;
    for (final path in fotos) {
      final b64 = await RelatorioHtmlRenderer.photoPathToBase64(path);
      if (b64 != null) {
        numero++;
        sb.write('''
        <figure class="sf-figure">
          <input type="checkbox" id="sf-visita-foto-$numero" class="sf-lb-toggle" hidden>
          <label for="sf-visita-foto-$numero">
            <img data-sf-photo src="$b64" alt="Foto $numero da visita" loading="lazy">
          </label>
          <figcaption>Foto $numero</figcaption>
        </figure>
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
      <div class="sf-row publicacao-row"><span class="sf-row-label">$titulo</span></div>
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
        return 'Em revisão';
    }
  }

  static String _statusDot(String status) {
    switch (status) {
      case 'publicado':
        return 'ok';
      case 'arquivado':
        return 'draft';
      default:
        return 'media';
    }
  }

  static DateTime? _parseIso(Object? value) {
    final raw = _string(value);
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
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
