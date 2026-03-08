import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup_provider.dart';

final _visitClientsProvider =
    FutureProvider.autoDispose<List<VisitClientSummary>>(
      (ref) => ref.watch(visitClientLookupProvider).listActiveClients(),
    );

final _visitFarmsProvider = FutureProvider.family
    .autoDispose<List<VisitFarmSummary>, String>((ref, clientId) {
      return ref.watch(visitClientLookupProvider).listFarmsByClient(clientId);
    });

final _visitFieldsProvider = FutureProvider.family
    .autoDispose<List<VisitFieldSummary>, String>((ref, farmId) {
      return ref.watch(visitClientLookupProvider).listFieldsByFarm(farmId);
    });

class VisitSheet extends ConsumerStatefulWidget {
  // Bug 2: areaId e activityType são opcionais — apenas produtor é obrigatório.
  final Function(String clientId, String? areaId, String? activityType)
  onConfirm;

  /// ID do cliente pré-selecionado via query param modo=visita (P5).
  /// Quando informado, o dropdown de Produtor já inicia selecionado.
  final String? preSelectedClienteId;
  // Bug 1: scrollController do DraggableScrollableSheet para expandir via drag.
  final ScrollController? scrollController;

  const VisitSheet({
    super.key,
    required this.onConfirm,
    this.preSelectedClienteId,
    this.scrollController,
  });

  @override
  ConsumerState<VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends ConsumerState<VisitSheet> {
  VisitClientSummary? _selectedClient;
  VisitFarmSummary? _selectedFarm;
  VisitFieldSummary? _selectedTalhao;
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
    final clientsAsync = ref.watch(_visitClientsProvider);
    final farmsAsync = _selectedClient != null
        ? ref.watch(_visitFarmsProvider(_selectedClient!.id))
        : const AsyncData<List<VisitFarmSummary>>([]);
    final fieldsAsync = _selectedFarm != null
        ? ref.watch(_visitFieldsProvider(_selectedFarm!.id))
        : const AsyncData<List<VisitFieldSummary>>([]);

    // P5: Pré-selecionar cliente quando aberto via /map?modo=visita&clienteId=X
    if (widget.preSelectedClienteId != null && _selectedClient == null) {
      final clients = clientsAsync.valueOrNull;
      if (clients != null) {
        final match = clients
            .where((c) => c.id == widget.preSelectedClienteId)
            .firstOrNull;
        if (match != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedClient = match);
          });
        }
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle bar ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Título ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Iniciar Visita',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Conteúdo com scroll — apenas os dropdowns ──
          // Bug 1: controller conecta ao DraggableScrollableSheet externo
          // para que o drag expanda o sheet em vez de só rolar o conteúdo.
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Produtor
                  _buildDropdown<VisitClientSummary>(
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
                  _buildDropdown<VisitFarmSummary>(
                    label: 'Fazenda',
                    value: _selectedFarm,
                    items: farmsAsync.valueOrNull ?? [],
                    itemLabel: (f) => f.name,
                    enabled: _selectedClient != null,
                    onChanged: (f) {
                      setState(() {
                        _selectedFarm = f;
                        _selectedTalhao = null;
                      });
                    },
                    emptyMessage: 'Nenhuma fazenda encontrada',
                    isLoading: farmsAsync.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // 3. Talhão (Área)
                  _buildDropdown<VisitFieldSummary>(
                    label: 'Área / Talhão',
                    value: _selectedTalhao,
                    items: fieldsAsync.valueOrNull ?? [],
                    itemLabel: (t) => t.name,
                    enabled: _selectedFarm != null,
                    onChanged: (t) {
                      setState(() => _selectedTalhao = t);
                    },
                    emptyMessage: 'Nenhum talhão encontrado',
                    isLoading: fieldsAsync.isLoading,
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
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedActivity = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Botão FIXO no rodapé — FORA DO SCROLL ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(context).padding.bottom, // safe area
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                // Bug 2: apenas produtor é obrigatório.
                // Fazenda, Talhão e Atividade são opcionais — podem ser
                // preenchidos ou atualizados após o check-in.
                onPressed: _selectedClient != null
                    ? () {
                        widget.onConfirm(
                          _selectedClient!.id,
                          _selectedTalhao?.id, // null quando não selecionado
                          _selectedActivity, // sempre tem default 'Monitoramento'
                        );
                        // NOTA: Navigator.pop removido daqui.
                        // O parent (private_map_sheets.dart) é o único responsável
                        // por fechar o modal após confirmar, evitando double-pop
                        // que causava tela preta ao fechar o mapa junto.
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTokens.brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'CONFIRMAR CHEGADA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ),
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
