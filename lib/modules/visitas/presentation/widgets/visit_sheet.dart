import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

class VisitSheet extends ConsumerStatefulWidget {
  final Function(String clientId, String areaId, String activityType) onConfirm;

  const VisitSheet({super.key, required this.onConfirm});

  @override
  ConsumerState<VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends ConsumerState<VisitSheet> {
  Client? _selectedClient;
  Farm? _selectedFarm;
  Talhao? _selectedTalhao;
  String _selectedActivity = 'Monitoramento';

  final List<String> _activities = [
    'Monitoramento',
    'Aplicação',
    'Semeadura',
    'Colheita',
    'Outro',
  ];

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Iniciar Visita',
            style: SoloTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 1. Produtor
          _buildDropdown<Client>(
            label: 'Produtor',
            value: _selectedClient,
            items: clientsAsync.valueOrNull ?? [],
            itemLabel: (c) => c.name,
            onChanged: (c) {
              setState(() {
                _selectedClient = c;
                _selectedFarm = null;
                _selectedTalhao = null;
              });
            },
            isLoading: clientsAsync.isLoading,
          ),
          const SizedBox(height: 16),

          // 2. Fazenda
          _buildDropdown<Farm>(
            label: 'Fazenda',
            value: _selectedFarm,
            items: _selectedClient?.farms ?? [],
            itemLabel: (f) => f.name,
            enabled: _selectedClient != null,
            onChanged: (f) {
              setState(() {
                _selectedFarm = f;
                _selectedTalhao = null;
              });
            },
            emptyMessage: 'Nenhuma fazenda encontrada',
          ),
          const SizedBox(height: 16),

          // 3. Talhão (Área)
          _buildDropdown<Talhao>(
            label: 'Área / Talhão',
            value: _selectedTalhao,
            items: _selectedFarm?.fields ?? [],
            itemLabel: (t) => t.name,
            enabled: _selectedFarm != null,
            onChanged: (t) {
              setState(() => _selectedTalhao = t);
            },
            emptyMessage: 'Nenhum talhão encontrado',
          ),
          const SizedBox(height: 16),

          // 4. Atividade
          DropdownButtonFormField<String>(
            value: _selectedActivity,
            decoration: InputDecoration(
              labelText: 'Atividade',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _activities.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedActivity = newValue!;
              });
            },
          ),
          const SizedBox(height: 32),

          // Confirm Button
          ElevatedButton(
            onPressed: (_selectedClient != null && _selectedTalhao != null)
                ? () {
                    widget.onConfirm(
                      _selectedClient!.id,
                      _selectedTalhao!.id,
                      _selectedActivity,
                    );
                    Navigator.pop(context); // Close sheet
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: SoloForteColors.greenIOS,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: const Text(
              'CONFIRMAR CHEGADA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required Function(T?) onChanged,
    bool enabled = true,
    bool isLoading = false,
    String emptyMessage = 'Vazio',
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: items.isEmpty
          ? null
          : items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
              );
            }).toList(),
      onChanged: enabled ? onChanged : null,
      hint: isLoading
          ? const Text('Carregando...')
          : (!enabled
                ? const Text('Selecione o anterior primeiro')
                : (items.isEmpty ? Text(emptyMessage) : null)),
      disabledHint: Text(
        items.isEmpty && enabled ? emptyMessage : 'Selecione...',
      ),
    );
  }
}
