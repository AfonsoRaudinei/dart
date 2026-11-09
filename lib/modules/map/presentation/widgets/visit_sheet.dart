import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup.dart';
import 'package:soloforte_app/core/domain/talhao_condicao.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup_provider.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

final _visitClientsProvider =
    FutureProvider.autoDispose<List<VisitClientSummary>>(
      (ref) => ref.watch(visitClientLookupProvider).listActiveClients(),
    );

final _visitFarmsProvider = FutureProvider.family
    .autoDispose<List<VisitFarmSummary>, String>((ref, clientId) {
      return ref.watch(visitClientLookupProvider).listFarmsByClient(clientId);
    });

/// Talhão mostrado no check-in. [canRate] só é verdadeiro para polígono desenhado.
class VisitTalhaoOption {
  const VisitTalhaoOption({
    required this.id,
    required this.name,
    required this.areaHa,
    required this.canRate,
    required this.condicao,
    this.centroid,
  });

  final String id;
  final String name;
  final double areaHa;
  final bool canRate;
  final TalhaoCondicao condicao;
  final LatLng? centroid;

  VisitTalhaoOption copyWith({TalhaoCondicao? condicao}) {
    return VisitTalhaoOption(
      id: id,
      name: name,
      areaHa: areaHa,
      canRate: canRate,
      condicao: condicao ?? this.condicao,
      centroid: centroid,
    );
  }
}

/// Host de check-in usa [preserveMaterialDefaults] (DraggableScrollableSheet),
/// que força o Scope em `light`. A variante real vem de
/// [SoloForteThemeExtension.themeId] e é re-propagada para o conteúdo.
SoloForteSheetVariant _visitSheetVariant(BuildContext context) =>
    soloForteSheetVariantFromThemeId(
      Theme.of(context).extension<SoloForteThemeExtension>()?.themeId,
    );

class VisitSheet extends ConsumerStatefulWidget {
  // Bug 2: areaId e activityType são opcionais — apenas produtor é obrigatório.
  final Function(
    String clientId,
    String? farmId,
    String? areaId,
    String? activityType,
  )
  onConfirm;

  final void Function(
    String clientId,
    String clientName,
    String? farmId,
    String? farmName,
    String? talhaoId,
    String? talhaoName,
  )
  onNavigateToArea;

  /// ID do cliente pré-selecionado via query param modo=visita (P5).
  /// Quando informado, o dropdown de Produtor já inicia selecionado.
  final String? preSelectedClienteId;
  // Bug 1: scrollController do DraggableScrollableSheet para expandir via drag.
  final ScrollController? scrollController;

  final Future<List<VisitTalhaoOption>> Function(String farmId) loadTalhoes;
  final Future<void> Function(String talhaoId, TalhaoCondicao condicao)
  onRateTalhao;
  final LatLng? userPosition;

  const VisitSheet({
    super.key,
    required this.onConfirm,
    required this.onNavigateToArea,
    required this.loadTalhoes,
    required this.onRateTalhao,
    this.userPosition,
    this.preSelectedClienteId,
    this.scrollController,
  });

  @override
  ConsumerState<VisitSheet> createState() => _VisitSheetState();
}

enum _VisitSheetStep { selecaoTalhao, condicaoEAtividade }

class _VisitSheetState extends ConsumerState<VisitSheet> {
  VisitClientSummary? _selectedClient;
  VisitFarmSummary? _selectedFarm;
  VisitTalhaoOption? _selectedTalhao;
  _VisitSheetStep _step = _VisitSheetStep.selecaoTalhao;
  String _selectedActivity = 'Monitoramento';
  String _talhaoQuery = '';
  final _talhaoSearchController = TextEditingController();
  List<VisitTalhaoOption> _talhoes = const [];
  bool _loadingTalhoes = false;
  int _talhaoLoadGeneration = 0;

  final List<String> _activities = [
    'Monitoramento',
    'Aplicação',
    'Semeadura',
    'Colheita',
    'Outro',
  ];

  @override
  void dispose() {
    _talhaoSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SoloForteSheetSkinScope(
      variant: _visitSheetVariant(context),
      child: Builder(builder: _buildSheet),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final clientsAsync = ref.watch(_visitClientsProvider);
    final farmsAsync = _selectedClient != null
        ? ref.watch(_visitFarmsProvider(_selectedClient!.id))
        : const AsyncData<List<VisitFarmSummary>>([]);

    final isConfirmEnabled = _selectedClient != null;
    final isNavigateEnabled = _selectedClient != null;
    final isIos = v.isIos;
    final sheetBg = v.sheetBackground;
    final handleColor = v.handleColor;
    final titleColor = v.titleColor;
    final ctaBg = v.ctaBackground;
    final ctaDisabled = v.cardBackground;
    final ctaRadius = v.ctaRadius;

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
          top: Radius.circular(v.sheetRadius),
        ),
        border: isIos
            ? Border(
                top: BorderSide(color: v.sheetBorder),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: v.handleSize.width,
              height: v.handleSize.height,
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
                        _talhaoQuery = '';
                        _talhoes = const [];
                        _step = _VisitSheetStep.selecaoTalhao;
                      });
                      _talhaoSearchController.clear();
                      _loadTalhoes(null);
                    },
                    isLoading: clientsAsync.isLoading,
                    v: v,
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
                        _talhaoQuery = '';
                        _step = _VisitSheetStep.selecaoTalhao;
                      });
                      _talhaoSearchController.clear();
                      _loadTalhoes(f?.id);
                    },
                    emptyMessage: 'Nenhuma fazenda encontrada',
                    isLoading: farmsAsync.isLoading,
                    v: v,
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _step == _VisitSheetStep.selecaoTalhao
                        ? KeyedSubtree(
                            key: const ValueKey('visit_step_selecao_talhao'),
                            child: _buildTalhaoPicker(v),
                          )
                        : KeyedSubtree(
                            key: const ValueKey(
                              'visit_step_condicao_atividade',
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTalhaoResumo(v),
                                const SizedBox(height: 12),
                                _buildCondicao(v),
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
                                  v: v,
                                ),
                              ],
                            ),
                          ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _selectedClient != null
                        ? () {
                            if (!isNavigateEnabled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Selecione um produtor.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.82,
                                  ),
                                ),
                              );
                              return;
                            }
                            widget.onNavigateToArea(
                              _selectedClient!.id,
                              _selectedClient!.name,
                              _selectedFarm?.id,
                              _selectedFarm?.name,
                              _selectedTalhao?.id,
                              _selectedTalhao?.name,
                            );
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isNavigateEnabled ? v.iconStroke : v.cardBorder,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ctaRadius),
                      ),
                      foregroundColor: v.titleColor,
                    ),
                    child: Text(
                      'IR ATÉ A ÁREA OU FAZENDA',
                      style: TextStyle(
                        color: isNavigateEnabled
                            ? v.titleColor
                            : v.subtitleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
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
                        color: isConfirmEnabled ? v.ctaText : v.subtitleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTalhoes(String? farmId) async {
    final generation = ++_talhaoLoadGeneration;
    if (farmId == null || farmId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _talhoes = const [];
        _loadingTalhoes = false;
      });
      return;
    }

    setState(() => _loadingTalhoes = true);
    final items = await widget.loadTalhoes(farmId);
    if (!mounted || generation != _talhaoLoadGeneration) return;
    setState(() {
      _talhoes = items;
      _loadingTalhoes = false;
      final selectedId = _selectedTalhao?.id;
      _selectedTalhao = selectedId == null
          ? null
          : items.where((item) => item.id == selectedId).firstOrNull;
    });
  }

  List<VisitTalhaoOption> _visibleTalhoes() {
    final query = _talhaoQuery.trim().toLowerCase();
    final items = _talhoes.where((item) {
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query);
    }).toList();
    final user = widget.userPosition;
    if (user == null) {
      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return items;
    }
    final distance = const Distance();
    double metersOf(VisitTalhaoOption item) {
      final centroid = item.centroid;
      if (centroid == null) return double.infinity;
      return distance.as(LengthUnit.Meter, user, centroid);
    }

    items.sort((a, b) => metersOf(a).compareTo(metersOf(b)));
    return items;
  }

  String _talhaoSubtitle(VisitTalhaoOption item) {
    final area = '${item.areaHa.toStringAsFixed(2)} ha';
    final user = widget.userPosition;
    final centroid = item.centroid;
    final distance = user == null || centroid == null
        ? null
        : const Distance().as(LengthUnit.Kilometer, user, centroid);
    final base = distance == null
        ? area
        : '$area · ${distance.toStringAsFixed(2)} km';
    return item.canRate ? base : '$base · sem polígono';
  }

  Future<void> _rate(TalhaoCondicao condicao) async {
    final selected = _selectedTalhao;
    if (selected == null || !selected.canRate) return;
    try {
      await widget.onRateTalhao(selected.id, condicao);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível marcar a condição.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _selectedTalhao = selected.copyWith(condicao: condicao));
    await _loadTalhoes(_selectedFarm?.id);
  }

  Widget _buildTalhaoPicker(SoloForteSheetVisuals v) {
    final enabled = _selectedFarm != null;
    final surface = v.cardBackground;
    final border = v.cardBorder;
    final radius = v.cardRadius;
    final items = enabled ? _visibleTalhoes() : const <VisitTalhaoOption>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Área / Talhão',
          style: TextStyle(color: v.subtitleColor, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _talhaoSearchController,
          enabled: enabled,
          onChanged: (value) => setState(() => _talhaoQuery = value),
          style: TextStyle(color: v.titleColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: enabled
                ? 'Buscar talhão'
                : 'Selecione a fazenda primeiro',
            hintStyle: TextStyle(color: v.subtitleColor, fontSize: 16),
            prefixIcon: Icon(Icons.search, color: v.subtitleColor),
            filled: true,
            fillColor: surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: v.focusBorder, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!enabled)
          Text(
            'Selecione a fazenda para ver os talhões.',
            style: TextStyle(color: v.subtitleColor, fontSize: 13),
          )
        else if (_loadingTalhoes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Carregando...',
              style: TextStyle(color: v.subtitleColor, fontSize: 14),
            ),
          )
        else if (items.isEmpty)
          Text(
            'Nenhum talhão encontrado',
            style: TextStyle(color: v.subtitleColor, fontSize: 14),
          )
        else
          // Com um único talhão o usuário ainda toca o tile (sem auto-pular o passo 1).
          for (final item in items)
            _TalhaoTile(
              item: item,
              subtitle: _talhaoSubtitle(item),
              selected: item.id == _selectedTalhao?.id,
              visuals: v,
              onTap: () {
                setState(() {
                  _selectedTalhao = item;
                  _step = _VisitSheetStep.condicaoEAtividade;
                });
              },
            ),
      ],
    );
  }

  Widget _buildTalhaoResumo(SoloForteSheetVisuals v) {
    final selected = _selectedTalhao;
    if (selected == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Área / Talhão',
          style: TextStyle(color: v.subtitleColor, fontSize: 12),
        ),
        const SizedBox(height: 6),
        _TalhaoTile(
          item: selected,
          subtitle: _talhaoSubtitle(selected),
          selected: true,
          visuals: v,
          onTap: () {},
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              setState(() {
                _step = _VisitSheetStep.selecaoTalhao;
                _selectedTalhao = null;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: v.titleColor,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Trocar talhão'),
          ),
        ),
      ],
    );
  }

  Widget _buildCondicao(SoloForteSheetVisuals v) {
    final selected = _selectedTalhao;
    if (selected == null) return const SizedBox.shrink();
    if (!selected.canRate) {
      return Text(
        'Desenhe o talhão no mapa para marcar a condição.',
        style: TextStyle(color: v.subtitleColor, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condição',
          style: TextStyle(color: v.subtitleColor, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final condicao in TalhaoCondicao.values)
              _CondicaoChip(
                condicao: condicao,
                selected: selected.condicao == condicao,
                onTap: () => _rate(condicao),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required Function(T?) onChanged,
    required SoloForteSheetVisuals v,
    bool enabled = true,
    bool isLoading = false,
    String emptyMessage = 'Vazio',
  }) {
    final surface = v.cardBackground;
    final border = v.cardBorder;
    final focus = v.focusBorder;
    final textColor = v.titleColor;
    final muted = v.subtitleColor;
    final labelColor = v.subtitleColor;
    final iconColor = v.isIos ? v.arrowColor : v.subtitleColor;
    final radius = v.cardRadius;

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
            ? Text(
                'Carregando...',
                style: TextStyle(color: muted, fontSize: 16),
              )
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

class _TalhaoTile extends StatelessWidget {
  const _TalhaoTile({
    required this.item,
    required this.subtitle,
    required this.selected,
    required this.visuals,
    required this.onTap,
  });

  final VisitTalhaoOption item;
  final String subtitle;
  final bool selected;
  final SoloForteSheetVisuals visuals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = visuals.cardRadius;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: visuals.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected ? visuals.focusBorder : visuals.cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: visuals.titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: visuals.subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.canRate)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(item.condicao.argb),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CondicaoChip extends StatelessWidget {
  const _CondicaoChip({
    required this.condicao,
    required this.selected,
    required this.onTap,
  });

  final TalhaoCondicao condicao;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = Color(condicao.argb);
    final onFill = fill.computeLuminance() > 0.6
        ? const Color(0xFF1D1D1F)
        : const Color(0xFFFFFFFF);
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? onFill : const Color(0x00000000),
              width: 2,
            ),
          ),
          child: Text(
            condicao.label,
            style: TextStyle(
              color: onFill,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
