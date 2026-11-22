part of 'marketing_case_sheet.dart';

class _AvaliacaoLivreReadOnlyCard extends StatefulWidget {
  final AvaliacaoItem avaliacao;
  final Color cardBg;
  final Color cardBorder;
  final Color titleColor;
  final Color hintColor;
  final bool isIos;

  const _AvaliacaoLivreReadOnlyCard({
    required this.avaliacao,
    required this.cardBg,
    required this.cardBorder,
    required this.titleColor,
    required this.hintColor,
    required this.isIos,
  });

  @override
  State<_AvaliacaoLivreReadOnlyCard> createState() =>
      _AvaliacaoLivreReadOnlyCardState();
}

class _AvaliacaoLivreReadOnlyCardState
    extends State<_AvaliacaoLivreReadOnlyCard> {
  String? _selectedParametroId;

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final avaliacao = widget.avaliacao;
    final accent = widget.isIos ? v.iconStroke : context.themeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${avaliacao.titulo.isEmpty ? 'Avaliação' : avaliacao.titulo} — ${avaliacao.nomeLadoA} vs ${avaliacao.nomeLadoB}',
            style: TextStyle(
              color: widget.titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Média de ganho: ${_formatSigned(avaliacao.mediaGanhoPercent)}%',
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (avaliacao.cultura != null && avaliacao.cultura!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Cultura: ${avaliacao.cultura}',
              style: TextStyle(color: widget.hintColor, fontSize: 12),
            ),
          ],
          if (_fotosPreenchidasDoBloco(avaliacao).isNotEmpty) ...[
            const SizedBox(height: 10),
            _FotosCarrossel(
              fotos: _fotosPreenchidasDoBloco(avaliacao),
              titleColor: widget.titleColor,
            ),
          ],
          const SizedBox(height: 10),
          ...avaliacao.parametros.map(
            (parametro) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      parametro.titulo,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.titleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${_formatValue(parametro.testemunha)} -> ${_formatValue(parametro.teste)}',
                    style: TextStyle(color: widget.titleColor, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    parametro.testemunha == 0
                        ? '--'
                        : '${_formatSigned(parametro.deltaPercent)}%',
                    style: TextStyle(
                      color: parametro.isNegativo
                          ? PremiumTokens.alertError
                          : accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (avaliacao.parametros.isNotEmpty) ...[
            const SizedBox(height: 10),
            ComparativoChart(
              parametros: avaliacao.parametros,
              selecionadoId: _selectedParametroId,
              onSelect: (id) => setState(() => _selectedParametroId = id),
              testemunhaLabel: avaliacao.nomeLadoA,
              testeLabel: avaliacao.nomeLadoB,
            ),
          ],
          if (avaliacao.observacoes != null &&
              avaliacao.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              avaliacao.observacoes!,
              style: TextStyle(
                color: widget.titleColor,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatValue(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  static String _formatSigned(double value) {
    final formatted = value.toStringAsFixed(1).replaceAll('.', ',');
    return value >= 0 ? '+$formatted' : formatted;
  }
}

class _ComparacaoBlocosReadOnly extends StatelessWidget {
  final List<AvaliacaoItem> avaliacoes;
  final Color titleColor;

  const _ComparacaoBlocosReadOnly({
    required this.avaliacoes,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in avaliacoes) ...[
          if (item.titulo.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item.titulo.trim(),
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          _FotosCarrossel(fotos: _fotosDoBloco(item), titleColor: titleColor),
          if (item.observacoes != null &&
              item.observacoes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.observacoes!.trim(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: titleColor, height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  List<_FotoComRotulo> _fotosDoBloco(AvaliacaoItem item) =>
      _fotosPreenchidasDoBloco(item);
}

/// Fotos preenchidas do bloco (A, B, C) com o rótulo de cada lado.
List<_FotoComRotulo> _fotosPreenchidasDoBloco(AvaliacaoItem item) {
  final fotos = <_FotoComRotulo>[];
  void add(String? url, String? rotulo) {
    final path = url?.trim() ?? '';
    if (path.isEmpty) return;
    fotos.add(_FotoComRotulo(path, rotulo?.trim() ?? ''));
  }

  add(item.fotoLadoAPath, item.nomeLadoA);
  add(item.fotoLadoBPath, item.nomeLadoB);
  add(item.fotoLadoCPath, item.nomeLadoC);
  return fotos;
}

/// Fotos de uma comparação: 1 foto ocupa a largura toda; 2 ou 3 viram um
/// carrossel horizontal com pontinhos. Cada instância guarda a própria página.
class _FotosCarrossel extends StatefulWidget {
  final List<_FotoComRotulo> fotos;
  final Color titleColor;

  const _FotosCarrossel({required this.fotos, required this.titleColor});

  @override
  State<_FotosCarrossel> createState() => _FotosCarrosselState();
}

class _FotosCarrosselState extends State<_FotosCarrossel> {
  static const _alturaFoto = 220.0;
  static const _alturaRotulo = 22.0;
  static const _fracaoViewport = 0.88;

  late PageController _controller = _novoController();
  int _pagina = 0;

  bool get _carrossel => widget.fotos.length > 1;

  PageController _novoController() =>
      PageController(viewportFraction: _carrossel ? _fracaoViewport : 1);

  @override
  void didUpdateWidget(_FotosCarrossel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.fotos.length > 1) != _carrossel) {
      _controller.dispose();
      _controller = _novoController();
    }
    if (_pagina >= widget.fotos.length) _pagina = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fotos = widget.fotos;
    if (fotos.isEmpty) return const SizedBox.shrink();
    final v = SoloForteSheetVisuals.of(context);
    if (!_carrossel) return _quadro(fotos.first, v, 0);

    final altura =
        _alturaFoto +
        (fotos.any((f) => f.rotulo.isNotEmpty) ? _alturaRotulo : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: altura,
          child: PageView.builder(
            controller: _controller,
            itemCount: fotos.length,
            onPageChanged: (i) => setState(() => _pagina = i),
            itemBuilder: (_, i) => _quadro(fotos[i], v, 4),
          ),
        ),
        const SizedBox(height: 8),
        _pontinhos(v),
      ],
    );
  }

  Widget _quadro(_FotoComRotulo foto, SoloForteSheetVisuals v, double gap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: foto.url,
              height: _alturaFoto,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                height: _alturaFoto,
                color: v.cardBackground,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: v.subtitleColor,
                ),
              ),
            ),
          ),
          if (foto.rotulo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              foto.rotulo,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.titleColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pontinhos(SoloForteSheetVisuals v) {
    final total = widget.fotos.length;
    return Semantics(
      container: true,
      label: 'Foto ${_pagina + 1} de $total',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                key: ValueKey('foto-pontinho-$i'),
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _pagina ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _pagina
                      ? v.iconStroke
                      : v.subtitleColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FotoComRotulo {
  final String url;
  final String rotulo;

  const _FotoComRotulo(this.url, this.rotulo);
}

class _MetricaItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricaItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
