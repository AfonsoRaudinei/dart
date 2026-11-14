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

/// Cases antigos gravaram só comparações extras em avaliacoesJson.
/// A Comparação 1 seguia em fotoAntesUrl/fotoDepoisUrl.
bool _fotosLegadasNoPrimeiroBloco(MarketingCase marketingCase) {
  final blocos = marketingCase.avaliacoesLivres;
  if (blocos.isEmpty) return false;
  final primeiro = blocos.first;
  final paths = {
    primeiro.fotoLadoAPath,
    primeiro.fotoLadoBPath,
    primeiro.fotoLadoCPath,
  };
  bool cobre(String? url) => url == null || url.isEmpty || paths.contains(url);
  return cobre(marketingCase.fotoAntesUrl) &&
      cobre(marketingCase.fotoDepoisUrl);
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
    final v = SoloForteSheetVisuals.of(context);
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
          _FotosGrade(
            fotos: _fotosDoBloco(item),
            visuals: v,
            titleColor: titleColor,
          ),
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

  List<_FotoComRotulo> _fotosDoBloco(AvaliacaoItem item) {
    final fotos = <_FotoComRotulo>[];
    void add(String? url, String? rotulo) {
      final path = url?.trim() ?? '';
      if (path.isEmpty) return;
      fotos.add(_FotoComRotulo(path, rotulo?.trim() ?? ''));
    }

    add(item.fotoLadoAPath, item.nomeLadoA);
    add(item.fotoLadoBPath, item.nomeLadoB);
    add(item.fotoLadoCPath, item.nomeLadoC);
    if (fotos.length <= 3) return fotos;
    return fotos.sublist(0, 3);
  }
}

class _FotosGrade extends StatelessWidget {
  final List<_FotoComRotulo> fotos;
  final SoloForteSheetVisuals visuals;
  final Color titleColor;

  const _FotosGrade({
    required this.fotos,
    required this.visuals,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) return const SizedBox.shrink();
    if (fotos.length == 1) return _coluna(fotos.first);
    final linha = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _coluna(fotos[0])),
        const SizedBox(width: 8),
        Expanded(child: _coluna(fotos[1])),
      ],
    );
    if (fotos.length == 2) return linha;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [linha, const SizedBox(height: 8), _coluna(fotos[2])],
    );
  }

  Widget _coluna(_FotoComRotulo foto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _mini(foto.url),
        if (foto.rotulo.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            foto.rotulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _mini(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        height: 130,
        width: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          height: 130,
          color: visuals.cardBackground,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: visuals.subtitleColor,
          ),
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
