import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import 'foto_picker_widget.dart';

/// Estado editável de um lado de Avaliação (A ou B)
class AvaliacaoLadoState {
  final TextEditingController labelCtrl;
  final TextEditingController obsCtrl;
  String? tipoCultura;
  String? fotoUrl; // URL após upload

  AvaliacaoLadoState({String defaultLabel = 'Produto'})
    : labelCtrl = TextEditingController(text: defaultLabel),
      obsCtrl = TextEditingController();

  void dispose() {
    labelCtrl.dispose();
    obsCtrl.dispose();
  }
}

/// Estado completo de um bloco de avaliação
class AvaliacaoBlocoState {
  final String id;
  final AvaliacaoLadoState ladoA;
  final AvaliacaoLadoState ladoB;
  bool colapsado;
  bool duasFotos;

  AvaliacaoBlocoState({
    required this.id,
    required this.ladoA,
    required this.ladoB,
    this.colapsado = false,
    this.duasFotos = true,
  });

  void dispose() {
    ladoA.dispose();
    ladoB.dispose();
  }
}

/// Widget de Bloco de Avaliação (Produto A vs Produto B)
/// Suporta: colapsar/expandir, layout 1 ou 2 fotos, remover
class AvaliacaoBlocoWidget extends StatefulWidget {
  final AvaliacaoBlocoState state;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const AvaliacaoBlocoWidget({
    super.key,
    required this.state,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<AvaliacaoBlocoWidget> createState() => _AvaliacaoBlocoWidgetState();
}

class _AvaliacaoBlocoWidgetState extends State<AvaliacaoBlocoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  static const Color _bgDark = Color(0xFF1C1C1E);
  static const Color _fieldDark = Color(0xFF2C2C2E);
  static const Color _borderDark = Color(0xFF3A3A3C);
  static const Color _focusGreen = Color(0xFF4CAF50);
  static const Color _headerColor = Color(0xFF3A3F5C);

  static const List<String> _culturas = [
    'Soja',
    'Milho',
    'Trigo',
    'Café',
    'Algodão',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.state.colapsado ? 0.0 : 1.0,
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => widget.state.colapsado = !widget.state.colapsado);
    if (widget.state.colapsado) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final bg = isIos ? SoloForteSheetSkinIos.cardBackground : _bgDark;
    final border = isIos ? SoloForteSheetSkinIos.cardBorder : _borderDark;
    final headerBg =
        isIos ? SoloForteSheetSkinIos.ctaBackground : _headerColor;
    final headerFg =
        isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final headerFgMuted = isIos
        ? SoloForteSheetSkinIos.ctaText.withValues(alpha: 0.7)
        : Colors.white70;
    final badgeBg = isIos
        ? SoloForteSheetSkinIos.iconBackground
        : Colors.white.withValues(alpha: 0.15);
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 16.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 0.5),
        color: bg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius - 2),
                  bottom: widget.state.colapsado
                      ? Radius.circular(radius - 2)
                      : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          color: isIos
                              ? SoloForteSheetSkinIos.iconStroke
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Avaliação ${widget.index + 1} — ${widget.state.ladoA.labelCtrl.text} vs ${widget.state.ladoB.labelCtrl.text}',
                      style: TextStyle(
                        color: headerFg,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Toggle layout
                  GestureDetector(
                    onTap: () {
                      setState(
                        () => widget.state.duasFotos = !widget.state.duasFotos,
                      );
                      widget.onChanged();
                    },
                    child: Tooltip(
                      message: widget.state.duasFotos ? '2 fotos' : '1 foto',
                      child: Icon(
                        widget.state.duasFotos
                            ? Icons.view_agenda_outlined
                            : Icons.crop_portrait_outlined,
                        color: headerFgMuted,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Remover
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onRemove();
                    },
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Colapsar
                  AnimatedRotation(
                    turns: widget.state.colapsado ? 0 : 0.5,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more,
                      color: headerFgMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Conteúdo expansível ───────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: widget.state.duasFotos
                  ? _buildDuasFotos(isIos)
                  : _buildUmaFoto(isIos),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuasFotos(bool isIos) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildLadoCard(
            widget.state.ladoA,
            label: 'Lado A',
            isIos: isIos,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildLadoCard(
            widget.state.ladoB,
            label: 'Lado B',
            isIos: isIos,
          ),
        ),
      ],
    );
  }

  Widget _buildUmaFoto(bool isIos) {
    return Column(
      children: [
        _buildLadoCard(
          widget.state.ladoA,
          label: 'Produto',
          isIos: isIos,
        ),
        const SizedBox(height: 12),
        _buildLadoCard(
          widget.state.ladoB,
          label: 'Controle',
          isIos: isIos,
        ),
      ],
    );
  }

  Widget _buildLadoCard(
    AvaliacaoLadoState lado, {
    required String label,
    required bool isIos,
  }) {
    final bg = isIos ? SoloForteSheetSkinIos.cardBackground : _bgDark;
    final border = isIos ? SoloForteSheetSkinIos.cardBorder : _borderDark;
    final field = isIos ? SoloForteSheetSkinIos.background : _fieldDark;
    final textColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final hintColor =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.white38;
    final mutedColor =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.white54;
    final focusBorder =
        isIos ? SoloForteSheetSkinIos.iconStroke : _focusGreen;
    final dividerColor = isIos
        ? SoloForteSheetSkinIos.rowDivider
        : Colors.white.withValues(alpha: 0.08);
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 12.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label editável
          TextField(
            controller: lado.labelCtrl,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            onChanged: (_) {
              widget.onChanged();
              setState(() {}); // Atualiza header
            },
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(fontSize: 12, color: hintColor),
              filled: true,
              fillColor: field,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: focusBorder, width: 1.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
          Divider(color: dividerColor, height: 12),

          // Foto
          FotoPickerWidget(
            label: label,
            url: lado.fotoUrl,
            folder: 'avaliacoes',
            height: 90,
            onChanged: (url) {
              setState(() => lado.fotoUrl = url);
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),

          // Tipo de Cultura
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: field,
              border: Border.all(color: border, width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: lado.tipoCultura,
                onChanged: (v) {
                  setState(() => lado.tipoCultura = v);
                  widget.onChanged();
                },
                isExpanded: true,
                hint: Text(
                  'Cultura',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
                style: TextStyle(fontSize: 12, color: textColor),
                dropdownColor: field,
                iconEnabledColor: mutedColor,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      '— Cultura —',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ),
                  ..._culturas.map(
                    (c) => DropdownMenuItem(
                      value: c.toLowerCase(),
                      child: Text(
                        c,
                        style: TextStyle(fontSize: 12, color: textColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Observações
          TextField(
            controller: lado.obsCtrl,
            maxLines: 2,
            style: TextStyle(color: textColor, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Observações...',
              hintStyle: TextStyle(fontSize: 11, color: hintColor),
              filled: true,
              fillColor: field,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: focusBorder, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(8),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
