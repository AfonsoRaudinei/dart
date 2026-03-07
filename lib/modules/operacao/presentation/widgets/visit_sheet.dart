import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
// Farm/Talhao vêm de consultoria — operacao→consultoria é PERMITIDO pelas enforcement-rules
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart'
    show clientDetailProvider;

/// Provider de clientes ativos via IClientLookup — sem acoplamento a consultoria/
final _clientesAtivosProvider = FutureProvider.autoDispose<List<ClientSummary>>(
  (ref) => ref.watch(clientLookupProvider).listAtivos(),
);

class VisitSheet extends ConsumerStatefulWidget {
  final Function(String clientId, String areaId, String activityType) onConfirm;

  const VisitSheet({super.key, required this.onConfirm});

  @override
  ConsumerState<VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends ConsumerState<VisitSheet> {
  ClientSummary? _selectedClientSummary;
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
    // Lista de clientes via IClientLookup (core/contracts/ — sem acoplar consultoria)
    final clientesAsync = ref.watch(_clientesAtivosProvider);
    // Farms do cliente selecionado via clientDetailProvider (operacao→consultoria é PERMITIDO)
    final farmsAsync = _selectedClientSummary != null
        ? ref.watch(clientDetailProvider(_selectedClientSummary!.id))
        : const AsyncData<Client?>(null);

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
          const Text(
            'Iniciar Visita',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 1. Produtor
          _buildDropdown<ClientSummary>(
            label: 'Produtor',
            value: _selectedClientSummary,
            items: clientesAsync.valueOrNull ?? [],
            itemLabel: (c) => c.name,
            onChanged: (c) {
              setState(() {
                _selectedClientSummary = c;
                _selectedFarm = null;
                _selectedTalhao = null;
              });
            },
            isLoading: clientesAsync.isLoading,
          ),
          const SizedBox(height: 16),

          // 2. Fazenda
          _buildDropdown<Farm>(
            label: 'Fazenda',
            value: _selectedFarm,
            items: farmsAsync.valueOrNull?.farms ?? [],
            itemLabel: (f) => f.name,
            enabled: _selectedClientSummary != null,
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
            initialValue: _selectedActivity,
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
            onPressed: (_selectedClientSummary != null && _selectedTalhao != null)
                ? () {
                    widget.onConfirm(
                      _selectedClientSummary!.id,
                      _selectedTalhao!.id,
                      _selectedActivity,
                    );
                    Navigator.pop(context); // Close sheet
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTokens.brandGreen,
              foregroundColor: Colors.white, // Texto branco em verde forte
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: const Text(
              'CONFIRMAR CHEGADA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      initialValue: value,
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
