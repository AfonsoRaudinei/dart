import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup_provider.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';

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

/// Host de check-in usa [preserveMaterialDefaults] (DraggableScrollableSheet).
/// Por isso detecta Azul via [SoloForteThemeExtension.themeId], não só o Scope.
bool _visitSheetIsIosBlue(BuildContext context) =>
    Theme.of(context).extension<SoloForteThemeExtension>()?.themeId == 'blue';

class VisitSheet extends ConsumerStatefulWidget {
  // Bug 2: areaId e activityType são opcionais — apenas produtor é obrigatório.
  final Function(
    String clientId,
    String? farmId,
    String? areaId,
    String? activityType,
  )
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
  static const _sheetBgDark = Color(0xFF1C1C1E);
  static const _surfaceDark = Color(0xFF2C2C2E);
  static const _borderDark = Color(0xFF3A3A3C);
  static const _accentGreen = Color(0xFF4CAF50);
  static const _buttonActiveDark = Color(0xFF2E7D32);

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
    final isIos = _visitSheetIsIosBlue(context);
    final sheetBg =
        isIos ? SoloForteSheetSkinIos.background : _sheetBgDark;
    final handleColor =
        isIos ? SoloForteSheetSkinIos.handleColor : Colors.white24;
    final titleColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final ctaBg =
        isIos ? SoloForteSheetSkinIos.ctaBackground : _buttonActiveDark;
    final ctaDisabled =
        isIos ? SoloForteSheetSkinIos.cardBackground : _surfaceDark;
    final ctaRadius =
        isIos ? SoloForteSheetSkinIos.ctaRadius : 14.0;

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
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isIos ? SoloForteSheetSkinIos.sheetRadius : 20),
        ),
        border: isIos
            ? const Border(
                top: BorderSide(color: SoloForteSheetSkinIos.sheetBorder),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: isIos ? SoloForteSheetSkinIos.handleSize.width : 40,
              height: isIos ? SoloForteSheetSkinIos.handleSize.height : 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Iniciar Visita',
              style: TextStyle(
                fontSize: isIos ? 16 : 20,
                fontWeight: isIos ? FontWeight.w700 : FontWeight.w600,
                color: titleColor,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    isIos: isIos,
                  ),
                  const SizedBox(height: 12),
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
                    isIos: isIos,
                  ),
                  const SizedBox(height: 12),
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
                    isIos: isIos,
                  ),
                  const SizedBox(height: 12),
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
                    isIos: isIos,
                  ),
                  const SizedBox(height: kFabSafeArea),
                ],
              ),
            ),
          ),
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
                onPressed: isConfirmEnabled
                    ? () {
                        widget.onConfirm(
                          _selectedClient!.id,
                          _selectedFarm?.id,
                          _selectedTalhao?.id,
                          _selectedActivity,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: ctaBg,
                  disabledBackgroundColor: ctaDisabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ctaRadius),
                  ),
                ),
                child: Text(
                  'CONFIRMAR CHEGADA',
                  style: TextStyle(
                    color: isConfirmEnabled
                        ? Colors.white
                        : (isIos
                            ? SoloForteSheetSkinIos.subtitleColor
                            : Colors.white24),
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
    required bool isIos,
    bool enabled = true,
    bool isLoading = false,
    String emptyMessage = 'Vazio',
  }) {
    final surface = isIos ? SoloForteSheetSkinIos.cardBackground : _surfaceDark;
    final border = isIos ? SoloForteSheetSkinIos.cardBorder : _borderDark;
    final focus = isIos ? SoloForteSheetSkinIos.iconStroke : _accentGreen;
    final textColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final muted =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.white38;
    final labelColor =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.white54;
    final iconColor =
        isIos ? SoloForteSheetSkinIos.arrowColor : Colors.white54;
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 12.0;

    final baseField = SizedBox(
      height: 56,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
        style: TextStyle(color: textColor, fontSize: 16),
        dropdownColor: surface,
        borderRadius: BorderRadius.circular(radius),
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: focus, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: border, width: 1),
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
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                );
              }).toList(),
        onChanged: enabled ? onChanged : null,
        hint: isLoading
            ? Text('Carregando...', style: TextStyle(color: muted, fontSize: 16))
            : (!enabled
                  ? Text(
                      'Selecione o anterior primeiro',
                      style: TextStyle(color: muted, fontSize: 16),
                    )
                  : (items.isEmpty
                        ? Text(
                            emptyMessage,
                            style: TextStyle(color: muted, fontSize: 16),
                          )
                        : null)),
        disabledHint: Text(
          items.isEmpty && enabled ? emptyMessage : 'Selecione...',
          style: TextStyle(color: muted, fontSize: 16),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
        const SizedBox(height: 6),
        if (!enabled) Opacity(opacity: 0.45, child: baseField) else baseField,
      ],
    );
  }
}
