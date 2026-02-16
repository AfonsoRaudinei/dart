import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../consultoria/clients/presentation/providers/clients_providers.dart';
import '../../../../consultoria/clients/domain/client.dart';
import '../../../../consultoria/clients/domain/agronomic_models.dart';
import '../../../domain/models/drawing_models.dart';

/// Widget responsável pelo formulário de metadados de uma feature de desenho.
/// 
/// Campos:
/// - Nome da área
/// - Descrição
/// - Cliente
/// - Fazenda
/// - Tipo (Talhão, Pasto, Reserva, etc)
/// 
/// ⚠️ Este widget NÃO salva diretamente - emite callbacks para o parent.
class DrawingMetadataPanel extends ConsumerStatefulWidget {
  final TextEditingController nomeController;
  final TextEditingController descricaoController;
  final Client? selectedClient;
  final Farm? selectedFarm;
  final DrawingType? selectedType;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final ValueChanged<Client?> onClientChanged;
  final ValueChanged<Farm?> onFarmChanged;
  final ValueChanged<DrawingType?> onTypeChanged;

  const DrawingMetadataPanel({
    super.key,
    required this.nomeController,
    required this.descricaoController,
    this.selectedClient,
    this.selectedFarm,
    this.selectedType,
    required this.onConfirm,
    required this.onCancel,
    required this.onClientChanged,
    required this.onFarmChanged,
    required this.onTypeChanged,
  });

  @override
  ConsumerState<DrawingMetadataPanel> createState() =>
      _DrawingMetadataPanelState();
}

class _DrawingMetadataPanelState extends ConsumerState<DrawingMetadataPanel> {
  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Informações da Área',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Nome
          TextField(
            controller: widget.nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome da Área *',
              hintText: 'Ex: Talhão 01',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label),
            ),
          ),
          const SizedBox(height: 16),

          // Descrição
          TextField(
            controller: widget.descricaoController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Informações adicionais (opcional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Cliente
          clientsAsync.when(
            data: (clients) {
              return DropdownButtonFormField<Client>(
                initialValue: widget.selectedClient,
                decoration: const InputDecoration(
                  labelText: 'Cliente *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: clients
                    .map((client) => DropdownMenuItem(
                          value: client,
                          child: Text(client.name),
                        ))
                    .toList(),
                onChanged: widget.onClientChanged,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => Text('Erro ao carregar clientes: $error'),
          ),
          const SizedBox(height: 16),

          // Fazenda (depende do cliente)
          if (widget.selectedClient != null)
            DropdownButtonFormField<Farm>(
              initialValue: widget.selectedFarm,
              decoration: const InputDecoration(
                labelText: 'Fazenda *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.landscape),
              ),
              items: widget.selectedClient!.farms
                  .map((farm) => DropdownMenuItem(
                        value: farm,
                        child: Text(farm.name),
                      ))
                  .toList(),
              onChanged: widget.onFarmChanged,
            ),
          if (widget.selectedClient != null) const SizedBox(height: 16),

          // Tipo de área
          DropdownButtonFormField<DrawingType>(
            initialValue: widget.selectedType,
            decoration: const InputDecoration(
              labelText: 'Tipo *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: DrawingType.values
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeLabel(type)),
                    ))
                .toList(),
            onChanged: widget.onTypeChanged,
          ),
          const SizedBox(height: 24),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canConfirm() ? widget.onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canConfirm() {
    return widget.nomeController.text.isNotEmpty &&
        widget.selectedClient != null &&
        widget.selectedFarm != null &&
        widget.selectedType != null;
  }

  String _getTypeLabel(DrawingType type) {
    switch (type) {
      case DrawingType.talhao:
        return 'Talhão';
      case DrawingType.zona_manejo:
        return 'Zona de Manejo';
      case DrawingType.exclusao:
        return 'Exclusão';
      case DrawingType.buffer:
        return 'Buffer';
      case DrawingType.teste:
        return 'Teste';
      case DrawingType.outro:
        return 'Outro';
    }
  }
}
