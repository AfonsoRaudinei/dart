import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/repositories/i_clients_repository.dart';
import '../controllers/drawing_controller.dart';
import '../providers/drawing_client_provider.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

/// Bottom sheet para editar as informações básicas de um talhão:
/// nome, cliente, fazenda, área (read-only), cultura e safra.
///
/// Chama [DrawingController.updateMetadata] ao confirmar.
class DrawingInfoEditSheet extends ConsumerStatefulWidget {
  final DrawingFeature feature;
  final DrawingController controller;
  final bool embedded;
  final VoidCallback? onCancel;
  final VoidCallback? onSaved;

  const DrawingInfoEditSheet({
    super.key,
    required this.feature,
    required this.controller,
    this.embedded = false,
    this.onCancel,
    this.onSaved,
  });

  @override
  ConsumerState<DrawingInfoEditSheet> createState() =>
      _DrawingInfoEditSheetState();
}

class _DrawingInfoEditSheetState extends ConsumerState<DrawingInfoEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _culturaCtrl;
  late final TextEditingController _safraCtrl;

  Client? _selectedClient;
  Farm? _selectedFarm;

  @override
  void initState() {
    super.initState();
    final props = widget.feature.properties;
    _nomeCtrl = TextEditingController(text: props.nome);
    _culturaCtrl = TextEditingController(text: props.cultura ?? '');
    _safraCtrl = TextEditingController(text: props.safra ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) => _initSelections());
  }

  void _initSelections() {
    final clientState = ref.read(drawingClientProvider);
    final props = widget.feature.properties;

    if (clientState.clients.isEmpty) {
      ref.read(drawingClientProvider.notifier).loadClients();
    }

    if (props.clienteId != null) {
      try {
        final client = clientState.clients.firstWhere(
          (c) => c.id == props.clienteId,
        );
        setState(() => _selectedClient = client);
        _loadFarmsAndSelect(props.clienteId!, props.fazendaId);
      } catch (_) {
        // cliente ainda não carregado — será restaurado quando a lista chegar
      }
    }
  }

  Future<void> _loadFarmsAndSelect(String clientId, String? farmId) async {
    await ref.read(drawingClientProvider.notifier).loadFarms(clientId);
    if (!mounted) return;
    if (farmId == null) return;
    final farms = ref.read(drawingClientProvider).farms;
    try {
      final farm = farms.firstWhere((f) => f.id == farmId);
      setState(() => _selectedFarm = farm);
    } catch (_) {
      // Fazenda removida ou ainda não carregada: mantém seleção vazia.
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _culturaCtrl.dispose();
    _safraCtrl.dispose();
    super.dispose();
  }

  void _onClientChanged(Client? client) {
    setState(() {
      _selectedClient = client;
      _selectedFarm = null;
    });
    if (client != null) {
      ref.read(drawingClientProvider.notifier).loadFarms(client.id);
    }
  }

  void _close() {
    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
    }
    Navigator.of(context).pop();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.controller.updateMetadata(
      widget.feature.id,
      nome: _nomeCtrl.text.trim(),
      cultura: _culturaCtrl.text.trim().isEmpty
          ? null
          : _culturaCtrl.text.trim(),
      safra: _safraCtrl.text.trim().isEmpty ? null : _safraCtrl.text.trim(),
      clienteId: _selectedClient?.id,
      fazendaId: _selectedFarm?.id,
    );
    if (widget.onSaved != null) {
      widget.onSaved!();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(drawingClientProvider);

    // Tenta reidrar a seleção de cliente após carregamento tardio
    if (_selectedClient == null &&
        widget.feature.properties.clienteId != null &&
        clientState.clients.isNotEmpty) {
      try {
        _selectedClient = clientState.clients.firstWhere(
          (c) => c.id == widget.feature.properties.clienteId,
        );
        if (widget.feature.properties.fazendaId != null &&
            clientState.farms.isNotEmpty) {
          try {
            _selectedFarm = clientState.farms.firstWhere(
              (f) => f.id == widget.feature.properties.fazendaId,
            );
          } catch (_) {
            // Fazenda removida: mantém seleção vazia.
          }
        }
      } catch (_) {
        // Cliente removido: mantém seleção vazia.
      }
    }

    const bg = SoloForteSheetTokens.sheetBackground;
    const inputBg = SoloForteSheetTokens.inputBackground;
    const hintColor = SoloForteSheetTokens.inputHint;
    const divColor = SoloForteSheetTokens.divider;
    const textStyle = TextStyle(color: Colors.white, fontSize: 14);
    const labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return Container(
      decoration: const BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.embedded)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: divColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            const Text(
              'Editar Informações',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Nome
            const Text('Nome do talhão *', style: labelStyle),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nomeCtrl,
              style: textStyle,
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                hintText: 'Ex: Talhão 01',
                hintStyle: const TextStyle(color: hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),

            // Área (read-only)
            const Text('Área (ha)', style: labelStyle),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.feature.properties.areaHa.toStringAsFixed(2),
                style: textStyle.copyWith(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 16),

            // Cliente
            const Text('Cliente', style: labelStyle),
            const SizedBox(height: 6),
            clientState.isLoadingClients
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<Client>(
                    initialValue: _selectedClient,
                    dropdownColor: inputBg,
                    style: textStyle,
                    hint: const Text(
                      'Selecionar cliente',
                      style: TextStyle(color: hintColor),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<Client>(
                        value: null,
                        child: Text(
                          '— Nenhum —',
                          style: TextStyle(color: hintColor),
                        ),
                      ),
                      ...clientState.clients.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                      ),
                    ],
                    onChanged: _onClientChanged,
                  ),
            const SizedBox(height: 16),

            // Fazenda
            const Text('Fazenda', style: labelStyle),
            const SizedBox(height: 6),
            clientState.isLoadingFarms
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<Farm>(
                    initialValue: _selectedFarm,
                    dropdownColor: inputBg,
                    style: textStyle,
                    hint: const Text(
                      'Selecionar fazenda',
                      style: TextStyle(color: hintColor),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<Farm>(
                        value: null,
                        child: Text(
                          '— Nenhuma —',
                          style: TextStyle(color: hintColor),
                        ),
                      ),
                      ...clientState.farms.map(
                        (f) => DropdownMenuItem(value: f, child: Text(f.name)),
                      ),
                    ],
                    onChanged: _selectedClient == null
                        ? null
                        : (f) => setState(() => _selectedFarm = f),
                  ),
            const SizedBox(height: 16),

            // Cultura
            const Text('Cultura', style: labelStyle),
            const SizedBox(height: 6),
            TextFormField(
              controller: _culturaCtrl,
              style: textStyle,
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                hintText: 'Ex: soja, milho, café',
                hintStyle: const TextStyle(color: hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Safra
            const Text('Safra', style: labelStyle),
            const SizedBox(height: 6),
            TextFormField(
              controller: _safraCtrl,
              style: textStyle,
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                hintText: 'Ex: 2025/2026',
                hintStyle: const TextStyle(color: hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Divider(color: divColor),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _close,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: divColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Salvar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
