import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Sub-View Header ──────────────────────────────────────────────────────────

class ClimaSubViewHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  const ClimaSubViewHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onBack();
            },
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.climaTint,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.37,
                color: context.climaTextPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Share Button ─────────────────────────────────────────────────────────────

class ClimaShareButton extends StatelessWidget {
  const ClimaShareButton({super.key, required this.payload});

  final ClimaSharePayload payload;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Compartilhar previsão no WhatsApp',
      child: Tooltip(
        message: 'Compartilhar no WhatsApp',
        child: SizedBox(
          width: 44,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.climaCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: context.climaShadow,
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.expand(),
              icon: Icon(
                Icons.share_outlined,
                color: context.climaTint,
                size: 22,
              ),
              tooltip: 'Compartilhar no WhatsApp',
              onPressed: () => showSoloForteSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                maxHeightFraction: 0.82,
                builder: (_) => ClimaWhatsAppSheet(payload: payload),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Icon Button ──────────────────────────────────────────────────────────────

class ClimaIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const ClimaIconBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.climaCard,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: context.climaShadow,
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: context.climaTint),
      ),
    );
  }
}

// ─── Loading Center ───────────────────────────────────────────────────────────

class ClimaLoadingCenter extends StatelessWidget {
  const ClimaLoadingCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Center(
        child: CircularProgressIndicator(
          color: context.climaTint,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class ClimaErrorState extends StatelessWidget {
  final String message;

  const ClimaErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            'Não foi possível carregar os dados climáticos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.climaTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: context.climaTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WhatsApp Sheet ───────────────────────────────────────────────────────────

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
    return _clientes
        .where((c) => climaCityMatchKey(c.city) == filtro)
        .toList();
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

    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final visiveis = _visiveis;
    final cidades = _cidades;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
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
              ],
            ),
          ),
          Divider(color: divider, height: 1),
          _ClimaWhatsAppPreview(payload: payload),
          if (!_loading && cidades.isNotEmpty)
            _ClimaCityFilter(
              cidades: cidades,
              selecionada: _filtroCidade,
              accent: accent,
              labelColor: categoryLabel,
              onSelected: (key) => setState(() => _filtroCidade = key),
              onMarcar: visiveis.any((c) => climaPhoneIsValid(c.phone))
                  ? _marcarComTelefone
                  : null,
            ),
          Divider(color: divider, height: 1),
          Expanded(
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accent,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : _clientes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhum cliente cadastrado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: categoryLabel,
                        ),
                      ),
                    ),
                  )
                : visiveis.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhum cliente em $_filtroLabel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: categoryLabel,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: visiveis.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: divider, height: 1),
                    itemBuilder: (_, i) {
                      final cliente = visiveis[i];
                      final tel = cliente.phone;
                      final hasPhone = climaPhoneIsValid(tel);
                      return CheckboxListTile(
                        tileColor: inputBg,
                        activeColor: accent,
                        checkColor: isIos
                            ? SoloForteSheetSkinIos.ctaText
                            : Theme.of(context).colorScheme.onPrimary,
                        value: hasPhone && _selecionados.contains(tel),
                        onChanged: hasPhone
                            ? (checked) {
                                setState(() {
                                  if (checked == true && tel != null) {
                                    _selecionados.add(tel);
                                  } else if (tel != null) {
                                    _selecionados.remove(tel);
                                  }
                                });
                              }
                            : null,
                        title: Text(
                          cliente.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: hasPhone ? inputText : categoryLabel,
                          ),
                        ),
                        subtitle: Text(
                          hasPhone ? tel! : 'Sem telefone cadastrado',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: categoryLabel,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Divider(color: divider, height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16 + bottomPad + kFabSafeArea,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Tooltip(
                message: total == 0
                    ? 'Selecione ao menos um destinatário'
                    : 'Enviar previsão pelo WhatsApp',
                child: FilledButton.icon(
                  onPressed: total == 0 ? null : _enviarParaSelecionados,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: inputBg,
                    foregroundColor: isIos
                        ? SoloForteSheetSkinIos.ctaText
                        : Theme.of(context).colorScheme.onPrimary,
                    disabledForegroundColor: categoryLabel,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClimaCityFilter extends StatelessWidget {
  const _ClimaCityFilter({
    required this.cidades,
    required this.selecionada,
    required this.accent,
    required this.labelColor,
    required this.onSelected,
    required this.onMarcar,
  });

  final List<String> cidades;
  final String? selecionada;
  final Color accent;
  final Color labelColor;
  final ValueChanged<String?> onSelected;
  final VoidCallback? onMarcar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CityChip(
                  label: 'Todas',
                  selected: selecionada == null,
                  accent: accent,
                  labelColor: labelColor,
                  onTap: () => onSelected(null),
                ),
                for (final cidade in cidades) ...[
                  const SizedBox(width: 8),
                  _CityChip(
                    label: cidade,
                    selected: climaCityMatchKey(cidade) == selecionada,
                    accent: accent,
                    labelColor: labelColor,
                    onTap: () => onSelected(climaCityMatchKey(cidade)),
                  ),
                ],
              ],
            ),
          ),
          if (onMarcar != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onMarcar,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Marcar com telefone'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.labelColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? accent : labelColor),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : labelColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClimaWhatsAppPreview extends StatelessWidget {
  const _ClimaWhatsAppPreview({required this.payload});

  final ClimaSharePayload payload;

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final cardBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final cardBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : SoloForteSheetTokens.divider;
    final labelColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.categoryLabel;
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.inputText;
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 14.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prévia do card',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payload.previewEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payload.previewTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        payload.previewSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: payload.previewChips
                  .map((label) => _PreviewChip(label: label))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isIos
            ? SoloForteSheetSkinIos.badgeBackground
            : SoloForteSheetTokens.categoryBackground,
        borderRadius: BorderRadius.circular(999),
        border: isIos
            ? Border.all(color: SoloForteSheetSkinIos.badgeBorder)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isIos
              ? SoloForteSheetSkinIos.badgeText
              : SoloForteSheetTokens.inputText,
        ),
      ),
    );
  }
}
