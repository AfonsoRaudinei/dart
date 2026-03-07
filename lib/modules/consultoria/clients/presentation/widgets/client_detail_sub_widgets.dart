// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

// ── Sub-widgets públicos de ClientDetailScreen ────────────────────────────
// Extraídos para manter client_detail_screen.dart abaixo de 900 linhas.
// (Sprint 7 — Bounded Context Hygiene)

// ── Botão de ação rápida ──────────────────────────────────────────────────

class ClientActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ClientActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<ClientActionButton> createState() => _ClientActionButtonState();
}

class _ClientActionButtonState extends State<ClientActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.08),
                      offset: Offset(0, 10),
                      blurRadius: 32,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: PremiumTokens.brandGreen,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.07,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Item de fazenda na listagem ───────────────────────────────────────────

class ClientFarmItem extends StatelessWidget {
  final String name;
  final String area;
  final VoidCallback? onTap;

  const ClientFarmItem({
    super.key,
    required this.name,
    required this.area,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              offset: Offset(0, 10),
              blurRadius: 32,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
            Row(
              children: [
                Text(
                  area,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFC7C7CC),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formatter: caixa alta automática ────────────────────────────────────

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

// ── Opção no modal de nova fazenda/talhão (iOS Premium) ──────────────────

class ClientModalOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ClientModalOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PremiumTokens.brandGreen.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: PremiumTokens.brandGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFC7C7CC),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper: modal de nova fazenda ────────────────────────────────────────
// Função livre para evitar dependência do state — chamada com context+client.

void showNovaFazendaModal(BuildContext context, dynamic client) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag pill
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFC5C5C7),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Text(
            'Adicionar Talhão',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Como deseja criar o novo talhão?',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          // Opção 1: Desenhar
          ClientModalOption(
            icon: Icons.edit_location_alt_outlined,
            title: 'Desenhar no Mapa',
            subtitle: 'Toque no mapa para definir os vértices',
            onTap: () {
              Navigator.of(context).pop();
              HapticFeedback.selectionClick();
              context.go(
                '/map?modo=desenho'
                '&clienteId=${client.id}'
                '&clienteNome=${Uri.encodeComponent(client.name as String)}',
              );
            },
          ),
          const SizedBox(height: 12),
          // Opção 2: Importar KML/KMZ
          ClientModalOption(
            icon: Icons.upload_file_outlined,
            title: 'Importar KML ou KMZ',
            subtitle: 'Selecione um arquivo do dispositivo',
            onTap: () {
              Navigator.of(context).pop();
              HapticFeedback.selectionClick();
              context.go(
                '/map?modo=importar'
                '&clienteId=${client.id}'
                '&clienteNome=${Uri.encodeComponent(client.name as String)}',
              );
            },
          ),
        ],
      ),
    ),
  );
}
