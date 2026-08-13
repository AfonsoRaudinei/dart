import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/contracts/i_farm_lookup_provider.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import 'novo_case_form_helpers.dart';

enum ProdutorEntryMode { nome, cliente }

/// Campo Produtor / Fazenda com toggle Nome (texto livre) ou Cliente (lookup).
class ProdutorEntrySection extends ConsumerStatefulWidget {
  final TextEditingController produtorController;
  final String? clientId;
  final ValueChanged<String?> onClientIdChanged;
  final bool required;

  const ProdutorEntrySection({
    super.key,
    required this.produtorController,
    required this.clientId,
    required this.onClientIdChanged,
    this.required = true,
  });

  @override
  ConsumerState<ProdutorEntrySection> createState() =>
      _ProdutorEntrySectionState();
}

class _ProdutorEntrySectionState extends ConsumerState<ProdutorEntrySection> {
  late ProdutorEntryMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.clientId != null
        ? ProdutorEntryMode.cliente
        : ProdutorEntryMode.nome;
  }

  void _setMode(ProdutorEntryMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      if (mode == ProdutorEntryMode.nome) {
        widget.onClientIdChanged(null);
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _openClientPicker() async {
    FocusScope.of(context).unfocus();
    final lookup = ref.read(clientLookupProvider);
    List<ClientSummary> clients;
    try {
      clients = await lookup.listAtivos();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar os clientes.')),
      );
      return;
    }

    if (!mounted) return;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum cliente ativo na carteira.'),
        ),
      );
      return;
    }

    final selected = await showSoloForteSheet<ClientSummary>(
      context: context,
      showDragHandle: true,
      maxHeightFraction: 0.7,
      builder: (sheetContext) => _ClientPickerSheet(clients: clients),
    );
    if (selected == null || !mounted) return;

    final label = await _buildProdutorLabel(selected);
    if (!mounted) return;

    setState(() => _mode = ProdutorEntryMode.cliente);
    widget.onClientIdChanged(selected.id);
    widget.produtorController.text = label;
    HapticFeedback.lightImpact();
  }

  Future<String> _buildProdutorLabel(ClientSummary client) async {
    try {
      final farms = await ref
          .read(iFarmLookupProvider)
          .getFarmsByClient(client.id);
      if (farms.isNotEmpty) {
        return '${client.name} / ${farms.first.name}';
      }
    } catch (_) {
      // Mantém só o nome do cliente.
    }
    return client.name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProdutorModeSelector(
          selectedMode: _mode,
          onChanged: _setMode,
        ),
        const SizedBox(height: 10),
        if (_mode == ProdutorEntryMode.nome)
          novoCaseTextInput(
            widget.produtorController,
            'Produtor / Fazenda *',
            required: widget.required,
            onChanged: (_) => widget.onClientIdChanged(null),
          )
        else
          FormField<String>(
            initialValue: widget.clientId,
            validator: (_) {
              if (!widget.required) return null;
              if (widget.clientId == null ||
                  widget.produtorController.text.trim().isEmpty) {
                return 'Selecione um cliente';
              }
              return null;
            },
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ClientePickerRow(
                  label: widget.produtorController.text.trim(),
                  onTap: () async {
                    await _openClientPicker();
                    field.didChange(widget.clientId);
                  },
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      field.errorText ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProdutorModeSelector extends StatelessWidget {
  final ProdutorEntryMode selectedMode;
  final ValueChanged<ProdutorEntryMode> onChanged;

  const _ProdutorModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _modeChip(
            context,
            label: 'Nome',
            selected: selectedMode == ProdutorEntryMode.nome,
            onTap: () => onChanged(ProdutorEntryMode.nome),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _modeChip(
            context,
            label: 'Cliente',
            selected: selectedMode == ProdutorEntryMode.cliente,
            onTap: () => onChanged(ProdutorEntryMode.cliente),
          ),
        ),
      ],
    );
  }

  Widget _modeChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? PremiumTokens.brandGreen.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? PremiumTokens.brandGreen
                : PremiumTokens.hairlineLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : const Color(0xFF8E8E93),
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ClientePickerRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ClientePickerRow({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = label.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 18,
              color: hasSelection
                  ? PremiumTokens.brandGreen
                  : SoloForteSheetTokens.inputHint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasSelection ? label : 'Selecionar cliente *',
                style: TextStyle(
                  color: hasSelection
                      ? SoloForteSheetTokens.inputText
                      : SoloForteSheetTokens.inputHint,
                  fontSize: 14,
                  fontWeight:
                      hasSelection ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: SoloForteSheetTokens.inputHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientPickerSheet extends StatelessWidget {
  final List<ClientSummary> clients;

  const _ClientPickerSheet({required this.clients});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SoloForteSheetTokens.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Selecionar cliente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: clients.length,
              separatorBuilder: (_, __) => const Divider(
                height: 0.5,
                thickness: 0.5,
                color: PremiumTokens.hairlineLight,
              ),
              itemBuilder: (context, index) {
                final client = clients[index];
                return ListTile(
                  title: Text(
                    client.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: client.phone?.trim().isNotEmpty == true
                      ? Text(
                          client.phone!,
                          style: const TextStyle(
                            color: SoloForteSheetTokens.inputHint,
                            fontSize: 13,
                          ),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(client),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
