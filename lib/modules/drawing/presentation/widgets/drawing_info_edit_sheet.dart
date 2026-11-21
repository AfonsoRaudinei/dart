import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/repositories/i_clients_repository.dart';
import '../controllers/drawing_controller.dart';
import '../providers/drawing_client_provider.dart';
import '../../../../core/domain/cultura_tipo.dart';
import '../../../../core/ui/cultura_material_fields.dart';
import 'package:soloforte_app/core/ui/keyboard_dismiss.dart';
import 'drawing_hierarchy_search_field.dart';

/// Padding inferior do form. Host do mapa já encolhe o detent pelo teclado.
@visibleForTesting
double drawingInfoEditSheetBottomPadding({
  required bool embedded,
  required double keyboardInset,
  double extra = 24,
}) {
  return (embedded ? 0.0 : keyboardInset) + extra;
}

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

  /// Exclui o talhão (após confirmação). Sem ele, o botão não aparece.
  final VoidCallback? onDelete;

  const DrawingInfoEditSheet({
    super.key,
    required this.feature,
    required this.controller,
    this.embedded = false,
    this.onCancel,
    this.onSaved,
    this.onDelete,
  });

  @override
  ConsumerState<DrawingInfoEditSheet> createState() =>
      _DrawingInfoEditSheetState();
}

class _DrawingInfoEditSheetState extends ConsumerState<DrawingInfoEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _culturaLivreCtrl;
  late final TextEditingController _materialCtrl;
  late final TextEditingController _safraCtrl;
  CulturaTipo? _selectedCultura;

  Client? _selectedClient;
  Farm? _selectedFarm;

  String _clientQuery = '';
  String _farmQuery = '';
  final _clientSearchController = TextEditingController();
  final _farmSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final props = widget.feature.properties;
    _nomeCtrl = TextEditingController(text: props.nome);
    _selectedCultura = CulturaTipo.matchStored(props.cultura);
    _culturaLivreCtrl = TextEditingController(
      text: _selectedCultura == CulturaTipo.outro ? (props.cultura ?? '') : '',
    );
    _materialCtrl = TextEditingController(text: props.material ?? '');
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
    _culturaLivreCtrl.dispose();
    _materialCtrl.dispose();
    _safraCtrl.dispose();
    _clientSearchController.dispose();
    _farmSearchController.dispose();
    super.dispose();
  }

  void _onClientChanged(Client? client) {
    setState(() {
      _selectedClient = client;
      _selectedFarm = null;
      _farmQuery = '';
    });
    _farmSearchController.clear();
    if (client != null) {
      ref.read(drawingClientProvider.notifier).loadFarms(client.id);
    }
  }

  void _close() {
    SoloforteKeyboardDismiss.dismiss();
    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir talhão?'),
        content: Text(
          'O talhão "${widget.feature.properties.nome}" será removido do mapa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) widget.onDelete?.call();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.controller.updateMetadata(
      widget.feature.id,
      nome: _nomeCtrl.text.trim(),
      cultura: persistCulturaValue(
        selectedTipo: _selectedCultura,
        culturaLivre: _culturaLivreCtrl.text,
      ),
      material: _materialCtrl.text.trim(),
      safra: _safraCtrl.text.trim(),
      clienteId: _selectedClient?.id,
      fazendaId: _selectedFarm?.id,
    );
    SoloforteKeyboardDismiss.dismiss();
    if (widget.onSaved != null) {
      widget.onSaved!();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
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

    final isIos = v.isIos;
    final bg = isIos && !widget.embedded
        ? v.sheetBackground
        : (widget.embedded ? Colors.transparent : v.sheetBackground);
    final inputBg = v.cardBackground;
    final hintColor = v.inputHint;
    final divColor = v.rowDivider;
    final textStyle = TextStyle(color: v.onSheetPrimary, fontSize: 14);
    final labelStyle = TextStyle(
      color: v.onSheetSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final mutedText = textStyle.copyWith(color: v.onSheetSecondary);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: drawingInfoEditSheetBottomPadding(
          embedded: widget.embedded,
          keyboardInset: MediaQuery.viewInsetsOf(context).bottom,
        ),
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

            // Nome
            Text('Nome do talhão *', style: labelStyle),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nomeCtrl,
              style: textStyle,
              scrollPadding: const EdgeInsets.only(bottom: 80),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                hintText: 'Ex: Talhão 01',
                hintStyle: TextStyle(color: hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: isIos
                      ? BorderSide(color: v.cardBorder)
                      : BorderSide.none,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),

            // Área (read-only)
            Text('Área (ha)', style: labelStyle),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(8),
                border: isIos ? Border.all(color: v.cardBorder) : null,
              ),
              child: Text(
                widget.feature.properties.areaHa.toStringAsFixed(2),
                style: mutedText,
              ),
            ),
            const SizedBox(height: 16),

            // Cliente
            Text('Cliente', style: labelStyle),
            const SizedBox(height: 6),
            DrawingClientSearchField(
              visuals: v,
              clients: clientState.clients,
              searchController: _clientSearchController,
              query: _clientQuery,
              selectedClient: _selectedClient,
              isLoading: clientState.isLoadingClients,
              clearable: true,
              onClearSelection: () => _onClientChanged(null),
              onQueryChanged: (value) => setState(() => _clientQuery = value),
              onSelectClient: _onClientChanged,
            ),
            const SizedBox(height: 16),

            // Fazenda
            Text('Fazenda', style: labelStyle),
            const SizedBox(height: 6),
            DrawingFarmSearchField(
              visuals: v,
              farms: clientState.farms,
              searchController: _farmSearchController,
              query: _farmQuery,
              selectedFarm: _selectedFarm,
              clientSelected: _selectedClient != null,
              isLoading: clientState.isLoadingFarms,
              enabled: _selectedClient != null,
              clearable: true,
              onClearSelection: () => setState(() => _selectedFarm = null),
              onQueryChanged: (value) => setState(() => _farmQuery = value),
              onSelectFarm: (farm) => setState(() => _selectedFarm = farm),
            ),
            const SizedBox(height: 16),

            CulturaMaterialFields(
              selectedTipo: _selectedCultura,
              culturaLivreController: _culturaLivreCtrl,
              materialController: _materialCtrl,
              onTipoSelected: (tipo) => setState(() => _selectedCultura = tipo),
              labelColor: labelStyle.color,
              chipUnselectedBackground: inputBg,
              chipUnselectedForeground: textStyle.color,
              fieldFillColor: inputBg,
              fieldTextColor: textStyle.color,
              fieldHintColor: hintColor,
            ),
            const SizedBox(height: 16),

            // Safra
            Text('Safra', style: labelStyle),
            const SizedBox(height: 6),
            TextFormField(
              controller: _safraCtrl,
              style: textStyle,
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                hintText: 'Ex: 2025/2026',
                hintStyle: TextStyle(color: hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            Divider(color: divColor),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _close,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isIos ? v.ghostText : v.onSheetSecondary,
                      side: BorderSide(color: isIos ? v.ghostBorder : divColor),
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
                      backgroundColor: isIos
                          ? v.ctaBackground
                          : const Color(0xFF34C759),
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
            if (widget.onDelete != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  key: const Key('drawing_info_delete'),
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Excluir talhão'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3B30),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
