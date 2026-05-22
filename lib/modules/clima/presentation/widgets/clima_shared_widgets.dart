import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Sub-View Header ──────────────────────────────────────────────────────────

class ClimaSubViewHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const ClimaSubViewHeader({
    super.key,
    required this.title,
    required this.onBack,
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
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: kClimaTint,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.37,
              color: kClimaTextPrimary,
            ),
          ),
        ],
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
          color: kClimaCard,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: kClimaShadow, offset: Offset(0, 2), blurRadius: 8),
          ],
        ),
        child: Icon(icon, size: 18, color: kClimaTint),
      ),
    );
  }
}

// ─── Loading Center ───────────────────────────────────────────────────────────

class ClimaLoadingCenter extends StatelessWidget {
  const ClimaLoadingCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 100),
      child: Center(
        child: CircularProgressIndicator(color: kClimaTint, strokeWidth: 2.5),
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
          const Text(
            'Não foi possível carregar os dados climáticos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kClimaTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: kClimaTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WhatsApp Sheet ───────────────────────────────────────────────────────────

class ClimaWhatsAppSheet extends StatefulWidget {
  final ClimaAtual clima;

  const ClimaWhatsAppSheet({super.key, required this.clima});

  @override
  State<ClimaWhatsAppSheet> createState() => _ClimaWhatsAppSheetState();
}

class _ClimaWhatsAppSheetState extends State<ClimaWhatsAppSheet> {
  List<Map<String, String>> _clientes = [];
  final Set<String> _selecionados = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    final db = await DatabaseHelper.instance.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final rows = await db.rawQuery(
      'SELECT nome, telefone FROM clients '
      'WHERE user_id = ? AND telefone IS NOT NULL AND telefone != "" '
      'AND deleted_at IS NULL '
      'ORDER BY nome ASC',
      [userId],
    );
    if (!mounted) return;
    setState(() {
      _clientes = rows
          .map(
            (r) => {
              'nome': r['nome'] as String,
              'telefone': r['telefone'] as String,
            },
          )
          .toList();
      _loading = false;
    });
  }

  String _buildMensagem(ClimaAtual clima) {
    return '🌤 Previsão do tempo — ${clima.cidade}\n\n'
        '🌡 ${clima.temperatura.toStringAsFixed(0)}°C — ${clima.condicao}\n'
        '💧 Umidade: ${clima.umidade}%\n'
        '🌧 Chuva: ${clima.precipitacao.toStringAsFixed(1)} mm\n'
        '💨 Vento: ${clima.ventoVelocidade.toStringAsFixed(0)} km/h ${clima.ventoDirecao}\n'
        '☀️ Índice UV: ${clima.indiceUV}\n\n'
        'Enviado pelo SoloForte App';
  }

  Future<void> _enviarWhatsApp(String telefone) async {
    final tel = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final mensagem = _buildMensagem(widget.clima);
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──────────────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF48484A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Header ──────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compartilhar previsão por WhatsApp',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: SoloForteSheetTokens.titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.clima.cidade,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: SoloForteSheetTokens.categoryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: SoloForteSheetTokens.divider, height: 1),
            _ClimaWhatsAppPreview(clima: widget.clima),
            const Divider(color: SoloForteSheetTokens.divider, height: 1),
            // ── Lista de clientes ────────────────────────────────────────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: kClimaTint,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : _clientes.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Nenhum cliente com telefone cadastrado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: SoloForteSheetTokens.categoryLabel,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _clientes.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: SoloForteSheetTokens.divider,
                        height: 1,
                      ),
                      itemBuilder: (_, i) {
                        final cliente = _clientes[i];
                        final tel = cliente['telefone']!;
                        return CheckboxListTile(
                          tileColor: const Color(0xFF2C2C2E),
                          activeColor: const Color(0xFF4ADE80),
                          checkColor: Colors.black,
                          value: _selecionados.contains(tel),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selecionados.add(tel);
                              } else {
                                _selecionados.remove(tel);
                              }
                            });
                          },
                          title: Text(
                            cliente['nome']!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: SoloForteSheetTokens.inputText,
                            ),
                          ),
                          subtitle: Text(
                            tel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: SoloForteSheetTokens.categoryLabel,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(color: SoloForteSheetTokens.divider, height: 1),
            // ── Botão de envio ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: Tooltip(
                  message: total == 0
                      ? 'Selecione ao menos um destinatário'
                      : 'Enviar previsão pelo WhatsApp',
                  child: FilledButton.icon(
                    onPressed: total == 0 ? null : _enviarParaSelecionados,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      disabledBackgroundColor: const Color(0xFF2C2C2E),
                      foregroundColor: Colors.black,
                      disabledForegroundColor: const Color(0xFF48484A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}

class _ClimaWhatsAppPreview extends StatelessWidget {
  const _ClimaWhatsAppPreview({required this.clima});

  final ClimaAtual clima;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SoloForteSheetTokens.inputBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SoloForteSheetTokens.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prévia do card',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: SoloForteSheetTokens.categoryLabel,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  climaWeatherEmoji(clima.condicaoCodigo),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${clima.temperatura.toStringAsFixed(0)}°C · ${clima.cidade}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: SoloForteSheetTokens.inputText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        clima.condicao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: SoloForteSheetTokens.categoryLabel,
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
              children: [
                _PreviewChip(label: 'Umidade ${clima.umidade}%'),
                _PreviewChip(
                  label:
                      'Vento ${clima.ventoVelocidade.toStringAsFixed(0)} km/h',
                ),
                _PreviewChip(
                  label: 'Chuva ${clima.precipitacao.toStringAsFixed(1)} mm',
                ),
                _PreviewChip(label: 'UV ${clima.indiceUV}'),
              ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.categoryBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: SoloForteSheetTokens.inputText,
        ),
      ),
    );
  }
}
