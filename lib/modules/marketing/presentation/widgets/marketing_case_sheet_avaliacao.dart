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
    final avaliacao = widget.avaliacao;
    final accent = widget.isIos
        ? SoloForteSheetSkinIos.iconStroke
        : PremiumTokens.brandGreen;

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
              style: TextStyle(
                color: widget.hintColor,
                fontSize: 12,
              ),
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
                    style: TextStyle(
                      color: widget.titleColor,
                      fontSize: 12,
                    ),
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
