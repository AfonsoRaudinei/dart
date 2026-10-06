import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_card_preview_dialog.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_share_png.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_whatsapp_sheet_ui.dart';

// ─── WhatsApp Sheet ───────────────────────────────────────────────────────────

/// Chrome fixo estimado (header + footer + divisores) para limitar só o scroll.
const double kClimaShareSheetChromeEstimate = 248;

class ClimaWhatsAppSheet extends ConsumerStatefulWidget {
  final ClimaSharePayload payload;

  const ClimaWhatsAppSheet({super.key, required this.payload});

  @override
  ConsumerState<ClimaWhatsAppSheet> createState() => _ClimaWhatsAppSheetState();
}

class _ClimaWhatsAppSheetState extends ConsumerState<ClimaWhatsAppSheet> {
  List<ClientSummary> _clientes = [];
  final Set<String> _selecionados = {};
  bool _loading = true;
  bool _sharingCard = false;

  /// Chave da cidade filtrada. `null` = Todas.
  String? _filtroCidade;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  String get _cidadePrevisaoKey => climaCityMatchKey(widget.payload.cidade);

  String get _filtroLabel {
    if (_filtroCidade == null || _filtroCidade == _cidadePrevisaoKey) {
      return _cidadePrevisaoLabel;
    }
    for (final cliente in _clientes) {
      if (climaCityMatchKey(cliente.city) == _filtroCidade) {
        return cliente.city!.trim();
      }
    }
    return _cidadePrevisaoLabel;
  }

  String get _cidadePrevisaoLabel {
    final raw = widget.payload.cidade.split(',').first.trim();
    return raw.isEmpty ? widget.payload.cidade : raw;
  }

  List<String> get _cidades {
    final seen = <String>{};
    final labels = <String>[];
    final previsao = _cidadePrevisaoKey;
    if (previsao.isNotEmpty) {
      seen.add(previsao);
      labels.add(_cidadePrevisaoLabel);
    }
    for (final cliente in _clientes) {
      final key = climaCityMatchKey(cliente.city);
      if (key.isEmpty || !seen.add(key)) continue;
      labels.add(cliente.city!.trim());
    }
    return labels;
  }

  List<ClientSummary> get _visiveis {
    final filtro = _filtroCidade;
    if (filtro == null) return _clientes;
    return _clientes.where((c) => climaCityMatchKey(c.city) == filtro).toList();
  }

  Future<void> _carregarClientes() async {
    final clientes = await ref.read(clientLookupProvider).listAtivos();
    if (!mounted) return;
    final previsao = _cidadePrevisaoKey;
    setState(() {
      _clientes = clientes;
      _filtroCidade = previsao.isEmpty ? null : previsao;
      _loading = false;
    });
  }

  void _marcarComTelefone() {
    setState(() {
      for (final cliente in _visiveis) {
        final tel = cliente.phone;
        if (climaPhoneIsValid(tel)) _selecionados.add(tel!);
      }
    });
  }

  Future<void> _enviarWhatsApp(String telefone) async {
    final tel = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final mensagem = widget.payload.buildWhatsAppMessage();
    final url = 'https://wa.me/55$tel?text=${Uri.encodeComponent(mensagem)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _enviarParaSelecionados() async {
    for (final telefone in _selecionados) {
      await _enviarWhatsApp(telefone);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _compartilharCardImagem() async {
    if (_sharingCard) return;
    setState(() => _sharingCard = true);
    try {
      final ok = await shareClimaCardAsPng(context, widget.payload);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível gerar o card para compartilhar'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível gerar o card para compartilhar'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingCard = false);
    }
  }

  void _abrirPreviewCard() {
    showClimaCardPreviewDialog(context, widget.payload);
  }

  @override
  Widget build(BuildContext context) {
    final total = _selecionados.length;
    final payload = widget.payload;
    final isIos = soloForteSheetIsIos(context);
    final accent = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : Theme.of(context).colorScheme.primary;
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.titleColor;
    final categoryLabel = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.categoryLabel;
    final divider = isIos
        ? SoloForteSheetSkinIos.rowDivider
        : SoloForteSheetTokens.divider;
    final inputBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final inputText = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.inputText;
    final ctaRadius = isIos ? SoloForteSheetSkinIos.ctaRadius : 12.0;
    final cardRadius = isIos ? SoloForteSheetSkinIos.cardRadius : 14.0;

    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final visiveis = _visiveis;
    final cidades = _cidades;
    final fonteLine = climaShareRodape(payload.fonte);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boundedHeight = constraints.maxHeight.isFinite;

          final scrollBody = SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClimaWhatsAppHeroResumo(
                  payload: payload,
                  accent: accent,
                  titleColor: titleColor,
                  labelColor: categoryLabel,
                  cardBg: inputBg,
                  cardRadius: cardRadius,
                  isIos: isIos,
                  onTap: _abrirPreviewCard,
                ),
                if (!_loading && cidades.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClimaWhatsAppCityFilter(
                    cidades: cidades,
                    selecionada: _filtroCidade,
                    accent: accent,
                    labelColor: categoryLabel,
                    inputBg: inputBg,
                    onSelected: (key) => setState(() => _filtroCidade = key),
                    onMarcar: visiveis.any((c) => climaPhoneIsValid(c.phone))
                        ? _marcarComTelefone
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accent,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (_clientes.isEmpty)
                  ClimaWhatsAppEmptyProducers(
                    message: 'Nenhum cliente cadastrado.',
                    labelColor: categoryLabel,
                  )
                else if (visiveis.isEmpty)
                  ClimaWhatsAppEmptyProducers(
                    message: 'Nenhum cliente em $_filtroLabel.',
                    labelColor: categoryLabel,
                    onClearFilter: () => setState(() => _filtroCidade = null),
                    accent: accent,
                  )
                else
                  ClimaWhatsAppProducerGroup(
                    clientes: visiveis,
                    selecionados: _selecionados,
                    accent: accent,
                    titleColor: inputText,
                    labelColor: categoryLabel,
                    divider: divider,
                    cardBg: inputBg,
                    cardRadius: cardRadius,
                    onToggle: (tel, selected) {
                      setState(() {
                        if (selected) {
                          _selecionados.add(tel);
                        } else {
                          _selecionados.remove(tel);
                        }
                      });
                    },
                  ),
              ],
            ),
          );

          final scrollMax = boundedHeight
              ? (constraints.maxHeight - kClimaShareSheetChromeEstimate).clamp(
                  96.0,
                  constraints.maxHeight,
                )
              : double.infinity;

          final body = boundedHeight
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: scrollMax),
                  child: scrollBody,
                )
              : scrollBody;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compartilhar previsão por WhatsApp',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: SoloForteSheetTokens.titleFontSize,
                        fontWeight: SoloForteSheetTokens.titleWeight,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payload.cidade,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: categoryLabel),
                    ),
                    if (fonteLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        fonteLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: categoryLabel,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              body,
              Divider(color: divider, height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  12 + bottomPad + kFabSafeArea,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: total == 0 ? null : _enviarParaSelecionados,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        disabledBackgroundColor: isIos
                            ? SoloForteSheetSkinIos.cardBackground
                            : SoloForteSheetTokens.inputBackground,
                        foregroundColor: isIos
                            ? SoloForteSheetSkinIos.ctaText
                            : Theme.of(context).colorScheme.onPrimary,
                        disabledForegroundColor: categoryLabel,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ctaRadius),
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        total == 0
                            ? 'Selecione destinatários'
                            : 'Enviar pelo WhatsApp ($total)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _sharingCard ? null : _compartilharCardImagem,
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: _sharingCard
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accent,
                              ),
                            )
                          : const Icon(Icons.ios_share, size: 18),
                      label: Text(
                        _sharingCard ? 'Gerando card…' : 'Compartilhar card',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
