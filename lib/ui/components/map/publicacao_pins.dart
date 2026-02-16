import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/domain/publicacao.dart';

// ════════════════════════════════════════════════════════════════════
// PINS DE PUBLICAÇÃO NO MAPA (ADR-007)
// Pin georreferenciado → clique abre preview contextual.
// Pin NÃO navega. Pin NÃO abre editor. Pin NÃO altera estado global.
// ════════════════════════════════════════════════════════════════════

/// Gerador de pins para Publicações no mapa.
/// Segue o mesmo padrão de OccurrencePinGenerator.
class PublicacaoPinGenerator {
  /// Gera lista de Markers a partir de publicações visíveis.
  static List<Marker> generatePins({
    required List<Publicacao> publicacoes,
    required double currentZoom,
    required Function(Publicacao) onPinTap,
  }) {
    return publicacoes
        .where((p) => p.isVisible && p.status == 'published')
        .map((pub) => pub.ensureCover())
        .map((pub) {
          return Marker(
            point: pub.location,
            width: 80,
            height: 96,
            child: GestureDetector(
              key: ValueKey('publicacao-pin-${pub.id}'),
              onTap: () => onPinTap(pub),
              child: _PublicacaoPin(
                publicacao: pub,
                showDetails: currentZoom >= 13,
              ),
            ),
          );
        })
        .toList();
  }
}

/// Widget visual do pin individual.
class _PublicacaoPin extends StatelessWidget {
  final Publicacao publicacao;
  final bool showDetails;

  const _PublicacaoPin({required this.publicacao, required this.showDetails});

  Color _getTypeColor() {
    switch (publicacao.type) {
      case PublicacaoType.institucional:
        return const Color(0xFF2196F3); // Azul
      case PublicacaoType.tecnico:
        return const Color(0xFF4CAF50); // Verde
      case PublicacaoType.resultado:
        return const Color(0xFFFF9800); // Laranja
      case PublicacaoType.comparativo:
        return const Color(0xFF9C27B0); // Roxo
      case PublicacaoType.caseSucesso:
        return const Color(0xFFFFC107); // Amarelo
    }
  }

  IconData _getTypeIcon() {
    switch (publicacao.type) {
      case PublicacaoType.institucional:
        return SFIcons.campaign;
      case PublicacaoType.tecnico:
        return SFIcons.agriculture;
      case PublicacaoType.resultado:
        return SFIcons.trendingUp;
      case PublicacaoType.comparativo:
        return SFIcons.compareArrows;
      case PublicacaoType.caseSucesso:
        return SFIcons.starOutline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor();
    final hasCover = publicacao.coverMedia.path.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Balão do pin
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Foto de capa ou ícone placeholder
                if (hasCover)
                  Image.network(
                    publicacao.coverMedia.path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(color),
                  )
                else
                  _buildPlaceholder(color),

                // Overlay gradiente
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),

                // Título no rodapé (se zoom alto)
                if (showDetails && publicacao.title != null)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        publicacao.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Badge de tipo (topo)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getTypeIcon(), size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Pontinha do pin (triângulo)
        CustomPaint(
          size: const Size(16, 10),
          painter: _PinArrowPainter(color: color),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          _getTypeIcon(),
          size: 28,
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Pinta o triângulo (pontinha) abaixo do pin.
class _PinArrowPainter extends CustomPainter {
  final Color color;
  _PinArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinArrowPainter old) => old.color != color;
}
