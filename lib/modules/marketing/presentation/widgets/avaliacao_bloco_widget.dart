import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const List<String> _culturas = [
    'Soja',
    'Milho',
    'Trigo',
    'Café',
    'Algodão',
    'Outro',
  ];
  static const Color _headerColor = Color(0xFF3A3F5C);

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        color: Theme.of(context).cardColor,
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
                color: _headerColor,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: widget.state.colapsado
                      ? const Radius.circular(14)
                      : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
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
                      style: const TextStyle(
                        color: Colors.white,
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
                        color: Colors.white70,
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
                    child: const Icon(
                      Icons.expand_more,
                      color: Colors.white70,
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
                  ? _buildDuasFotos()
                  : _buildUmaFoto(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuasFotos() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildLadoCard(widget.state.ladoA, label: 'Lado A')),
        const SizedBox(width: 12),
        Expanded(child: _buildLadoCard(widget.state.ladoB, label: 'Lado B')),
      ],
    );
  }

  Widget _buildUmaFoto() {
    return Column(
      children: [
        _buildLadoCard(widget.state.ladoA, label: 'Produto', fullWidth: true),
        const SizedBox(height: 12),
        _buildLadoCard(widget.state.ladoB, label: 'Controle', fullWidth: true),
      ],
    );
  }

  Widget _buildLadoCard(
    AvaliacaoLadoState lado, {
    required String label,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label editável
          TextField(
            controller: lado.labelCtrl,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            onChanged: (_) {
              widget.onChanged();
              setState(() {}); // Atualiza header
            },
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 12),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 4),
            ),
          ),
          const Divider(height: 12),

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
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: lado.tipoCultura,
                onChanged: (v) {
                  setState(() => lado.tipoCultura = v);
                  widget.onChanged();
                },
                isExpanded: true,
                hint: const Text('Cultura', style: TextStyle(fontSize: 12)),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                dropdownColor: Colors.white,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('— Cultura —', style: TextStyle(fontSize: 12)),
                  ),
                  ..._culturas.map(
                    (c) => DropdownMenuItem(
                      value: c.toLowerCase(),
                      child: Text(c, style: const TextStyle(fontSize: 12)),
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
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Observações...',
              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _headerColor.withValues(alpha: 0.5),
                ),
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
