import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
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
  static const _sheetBg = Color(0xFF1C1C1E);
  static const _surface = Color(0xFF2C2C2E);
  static const _border = Color(0xFF3A3A3C);
  static const _accentGreen = Color(0xFF4CAF50);
  static const _buttonActive = Color(0xFF2E7D32);

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

    final isConfirmEnabled = _selectedClient != null;

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
        color: _sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle bar ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Título ──
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Iniciar Visita',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
          ),

          // ── Conteúdo com scroll — apenas os dropdowns ──
          // Bug 1: controller conecta ao DraggableScrollableSheet externo
          // para que o drag expanda o sheet em vez de só rolar o conteúdo.
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 12),

                  // 4. Atividade
                  _buildDropdown<String>(
                    label: 'Atividade',
                    value: _selectedActivity,
                    items: _activities,
                    itemLabel: (value) => value,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedActivity = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: kFabSafeArea),
                ],
              ),
            ),
          ),

          // ── Botão FIXO no rodapé — FORA DO SCROLL ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              math.max(20, MediaQuery.of(context).padding.bottom + 20),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                // Bug 2: apenas produtor é obrigatório.
                // Fazenda, Talhão e Atividade são opcionais — podem ser
                // preenchidos ou atualizados após o check-in.
                onPressed: isConfirmEnabled
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
                  elevation: 0,
                  backgroundColor: _buttonActive,
                  disabledBackgroundColor: _surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'CONFIRMAR CHEGADA',
                  style: TextStyle(
                    color: isConfirmEnabled ? Colors.white : Colors.white24,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 1.2,
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
    final baseField = SizedBox(
      height: 56,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        dropdownColor: _surface,
        borderRadius: BorderRadius.circular(12),
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: _surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accentGreen, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items: items.isEmpty
            ? null
            : items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                );
              }).toList(),
        onChanged: enabled ? onChanged : null,
        hint: isLoading
            ? const Text(
                'Carregando...',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              )
            : (!enabled
                  ? const Text(
                      'Selecione o anterior primeiro',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    )
                  : (items.isEmpty
                        ? Text(
                            emptyMessage,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                            ),
                          )
                        : null)),
        disabledHint: Text(
          items.isEmpty && enabled ? emptyMessage : 'Selecione...',
          style: const TextStyle(color: Colors.white38, fontSize: 16),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 6),
        if (!enabled) Opacity(opacity: 0.45, child: baseField) else baseField,
      ],
    );
  }
}
