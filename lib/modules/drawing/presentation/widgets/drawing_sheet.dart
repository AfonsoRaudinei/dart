import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/drawing_controller.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/models/gps_walk_session.dart';
import '../../domain/drawing_state.dart';
import '../../domain/repositories/i_clients_repository.dart';
import '../providers/drawing_client_provider.dart';
import '../providers/gps_walk_providers.dart';
import '../providers/drawing_export_provider.dart';
import '../../../dashboard/providers/location_providers.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import 'components/drawing_tool_selector.dart';
import 'components/drawing_actions_bar.dart';
import 'drawing_info_edit_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import 'gps_walk_controls_overlay.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

// Responsabilidade: container/shell do sheet de desenho
// (layout, estado e ciclo de vida; não concentra os itens de ferramenta).
// Os itens de ferramenta ficam em:
// lib/modules/drawing/presentation/widgets/components/drawing_tool_selector.dart
class DrawingSheet extends ConsumerStatefulWidget {
  final DrawingController controller;
  final ValueChanged<DrawingFeature>? onFocusFeature;
  final VoidCallback? onGpsMeasureStarted;
  final VoidCallback? onSaved;

  const DrawingSheet({
    super.key,
    required this.controller,
    this.onFocusFeature,
    this.onGpsMeasureStarted,
    this.onSaved,
  });

  @override
  ConsumerState<DrawingSheet> createState() => _DrawingSheetState();
}

class _DrawingSheetState extends ConsumerState<DrawingSheet> {
  String? _selectedToolKey;
  bool _isSaving = false;

  // 🆕 ESTADO LOCAL PARA REVISÃO COMPLETA
  final _formKey = GlobalKey<FormState>();

  // Hierarquia: Cliente -> Fazenda -> Talhão
  Client? _selectedClient;
  Farm? _selectedFarm;
  final bool _isConsultant = true; // TODO: Obter do AuthProvider

  Color _selectedColor = PremiumTokens.brandGreen;

  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto-load clients via DrawingClientNotifier (ADR-019)
      if (_isConsultant) {
        ref.read(drawingClientProvider.notifier).loadClients();
      }
      // Sincronizar pré-seleção inicial
      _syncPreSelectedClient(ref.read(drawingClientProvider));
    });

    // Suggest logical name
    _nomeController.text = "Talhão Novo";
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  /// Aplica pré-seleção de cliente proveniente de query param Map-First.
  /// Chamado via ref.listen e no postFrameCallback inicial.
  void _syncPreSelectedClient(DrawingClientState clientState) {
    final preId = clientState.preSelectedClientId;
    if (preId == null) return;

    final match = clientState.clients.where((c) => c.id == preId).toList();
    if (match.isNotEmpty &&
        !identical(_selectedClient, match.first) &&
        mounted) {
      setState(() => _selectedClient = match.first);
    } else if (_selectedClient == null &&
        clientState.preSelectedClientName != null &&
        mounted) {
      setState(
        () => _selectedClient = Client(
          id: preId,
          name: clientState.preSelectedClientName!,
        ),
      );
    }
  }

  void _onToolSelected(String key) {
    if (key == 'import') {
      widget.controller.pickImportFile();
      setState(() {
        _selectedToolKey = null; // No visual toggle for import, it changes mode
      });
      return;
    }

    // GPS Walk Mode — tratamento especial via GpsWalkController (não via selectTool)
    if (key == 'gps') {
      final bool isActive = _selectedToolKey == 'gps';
      if (isActive) {
        // Toggle OFF: cancela sessão GPS Walk ativa
        ref.read(gpsWalkProvider.notifier).cancel();
        setState(() => _selectedToolKey = null);
      } else {
        // Toggle ON: ativa GPS Walk em estado idle (NÃO inicia GPS stream ainda)
        setState(() => _selectedToolKey = 'gps');
        ref.read(gpsWalkProvider.notifier).activate();
        // Registra listener para sincronizar métricas quando gpsVertices muda
        _setupGpsVerticesListener();
      }
      return;
    }

    // Toggle: se já está selecionado, desativa
    final bool shouldActivate = _selectedToolKey != key;

    setState(() {
      _selectedToolKey = shouldActivate ? key : null;
    });

    // 🔧 FIX CRÍTICO: Notificar o controller para ativar/desativar a ferramenta
    if (shouldActivate) {
      widget.controller.selectTool(key);
      // 🔧 FIX-DRAW-FLOW-01: Ativar modo de desenho sem fechar bottom sheet
      // O MapBottomSheet permanece aberto para o usuário ver ferramentas ativas
    } else {
      widget.controller.selectTool('none'); // Desativa ferramenta
    }
  }

  /// Registra listener para sincronizar pontos GPS → GpsWalkController.
  ///
  /// Chamado uma vez ao ativar GPS Walk. O listener atualiza métricas
  /// no GpsWalkController sempre que novos vértices GPS são coletados.
  void _setupGpsVerticesListener() {
    // A sincronização ocorre no build() via ListenableBuilder.
    // Este método existe apenas para compatibilidade semântica.
  }

  /*
  Widget _buildSyncBadge(SyncStatus status) {
  ...
  */

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // ADR-019: escuta mudancas de clientes para pre-selecao Map-First
    ref.listen<DrawingClientState>(drawingClientProvider, (_, next) {
      _syncPreSelectedClient(next);
    });

    // ── GPS Walk: resetar seleção quando sessão é cancelada/finalizada ───────
    ref.listen<GpsWalkSession?>(gpsWalkProvider, (prev, next) {
      if (prev != null && next == null && _selectedToolKey == 'gps') {
        setState(() => _selectedToolKey = null);
      }
      if (prev?.status == GpsWalkStatus.idle &&
          next?.status == GpsWalkStatus.measuring) {
        widget.onGpsMeasureStarted?.call();
      }
    });

    ref.listen<ExportState>(drawingExportProvider, (_, next) {
      if (!mounted) return;
      if (next is ExportSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exportado: ${next.fileName}')));
        ref.read(drawingExportProvider.notifier).reset();
      } else if (next is ExportError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
        ref.read(drawingExportProvider.notifier).reset();
      }
    });

    // NOTA ARQUITETURAL: O handle (pílula de drag) é renderizado pelo
    // componente pai (lib/ui/screens/private_map_sheets.dart / MapBottomSheet).
    // Este widget não inclui handle próprio.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: SoloForteSheetTokens.sheetBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 4. Cabeçalho Fixo (Fonte Única)
            const _SheetHeader(),

            // Conteúdo Dinâmico
            Flexible(
              child: SingleChildScrollView(
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    // ── GPS Walk: sincronizar métricas a cada novo vértice GPS ────
                    final gpsSession = ref.watch(gpsWalkProvider);
                    if (gpsSession != null) {
                      // Sincroniza pontos do DrawingController → GpsWalkNotifier
                      final pts = widget.controller.gpsVertices;
                      if (pts.length != gpsSession.points.length) {
                        // Schedule post-frame para não chamar durante build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(gpsWalkProvider.notifier)
                              .syncFromController(pts);
                        });
                      }
                      return const GpsWalkControlsOverlay();
                    }

                    final content = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Always calculate and show metrics if available
                        _buildMetricsPanel(context),

                        if (widget.controller.errorMessage != null)
                          _buildErrorState(context)
                        // 🆕 Modo de revisão: Formulário após desenhar
                        else if (widget.controller.currentState ==
                            DrawingState.reviewing)
                          _buildReviewingMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.importing)
                          _buildImportingMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.importPreview)
                          _buildImportPreviewMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.unionSelection)
                          _buildUnionMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.differenceSelection)
                          _buildDifferenceMode(context) // Replaces cut
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.intersectionSelection)
                          _buildIntersectionMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.editing)
                          _buildEditingMode(context)
                        else if (widget.controller.selectedFeature != null)
                          _buildSelectedMode(context)
                        else
                          _buildToolsGrid(context),
                      ],
                    );
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: kFabSafeArea + safeBottom + 40,
                      ),
                      child: content,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    final geometry = widget.controller.liveGeometry;
    if (geometry == null) return;

    setState(() => _isSaving = true);
    final DrawingFeature? savedFeature;
    try {
      savedFeature = await widget.controller.addFeature(
        geometry: geometry,
        nome: _nomeController.text.trim(),
        tipo: DrawingType.talhao,
        origem:
            widget.controller.pendingImportOrigin ??
            DrawingOrigin.desenho_manual,
        autorId: 'current_user',
        autorTipo: _isConsultant ? AuthorType.consultor : AuthorType.cliente,
        clienteId: _selectedClient?.id ?? 'SELF',
        fazendaId: _selectedFarm?.id,
        grupo: _selectedFarm?.name,
        cor: _selectedColor.toARGB32(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (!mounted) return;
    if (savedFeature == null) return;

    _resetReviewForm();
    widget.onSaved?.call();
  }

  Widget _buildMetricsPanel(BuildContext context) {
    // BUG 3: Ocultar durante revisão — as métricas já aparecem em _buildReviewingMode
    if (widget.controller.currentState == DrawingState.reviewing) {
      return const SizedBox.shrink();
    }

    final area = widget.controller.reviewAreaHa;
    final perimeter = widget.controller.reviewPerimeterKm;

    if (area <= 0 && perimeter <= 0) return const SizedBox.shrink();

    final f = NumberFormat("##0.##", "pt_BR");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens
            .sheetBackground, // ✅ iOS Premium: Superfícies elevadas (Cards) são brancas
        borderRadius: BorderRadius.circular(
          PremiumTokens.borderRadiusSm,
        ), // ✅ iOS Premium: Inset com 12px
        border: Border.all(
          color: SoloForteSheetTokens.inputBackground,
          width: PremiumTokens.hairlineThickness,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.square_foot, size: 16, color: Colors.blueGrey),
              SizedBox(width: 6),
              Text(
                'MÉTRICAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricItem(label: 'Área', value: '${f.format(area)} ha'),
              _MetricItem(
                label: 'Perímetro',
                value: '${f.format(perimeter)} km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 40),
          const SizedBox(height: 8),
          Text(
            widget.controller.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: SoloForteSheetTokens.sectionLabel),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.controller.clearError,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    // 🆕 REFATORADO: Usar DrawingToolSelector component
    final pendingCount = widget.controller.pendingSyncCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          DrawingToolSelector(
            selectedToolKey: _selectedToolKey,
            onToolSelected: _onToolSelected,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openGroupMeasurementsNavigator(context),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Grupo > Medições'),
          ),
          if (pendingCount > 0) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => widget.controller.syncFeatures(),
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
              label: Text('Enviar alterações ($pendingCount)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openGroupMeasurementsNavigator(BuildContext context) async {
    final all = widget.controller.features;
    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma medição disponível.')),
      );
      return;
    }

    final groups =
        all
            .map((f) => (f.properties.grupo ?? 'Sem Grupo').trim())
            .toSet()
            .toList()
          ..sort();
    final currentPosition = await ref.read(initialLocationProvider.future);
    final distance = const Distance();
    String query = '';
    String selectedGroup = 'Todos';
    bool orderByProximity = true;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          List<DrawingFeature> filtered = all.where((f) {
            final g = (f.properties.grupo ?? 'Sem Grupo').trim();
            final name = f.properties.nome.toLowerCase();
            final matchesGroup = selectedGroup == 'Todos' || g == selectedGroup;
            final matchesQuery =
                query.isEmpty ||
                name.contains(query.toLowerCase()) ||
                g.toLowerCase().contains(query.toLowerCase());
            return matchesGroup && matchesQuery;
          }).toList();

          if (orderByProximity && currentPosition != null) {
            filtered.sort((a, b) {
              final da = _featureDistanceM(a, currentPosition, distance);
              final db = _featureDistanceM(b, currentPosition, distance);
              return da.compareTo(db);
            });
          } else {
            filtered.sort(
              (a, b) => a.properties.nome.compareTo(b.properties.nome),
            );
          }

          return AlertDialog(
            title: const Text('Grupo > Medições'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar por grupo ou medição',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setLocalState(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: 'Todos',
                    items: [
                      const DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todos'),
                      ),
                      ...groups.map(
                        (g) => DropdownMenuItem(value: g, child: Text(g)),
                      ),
                    ],
                    onChanged: (v) =>
                        setLocalState(() => selectedGroup = v ?? 'Todos'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ordenar por proximidade'),
                    value: orderByProximity,
                    onChanged: (v) => setLocalState(() => orderByProximity = v),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final f = filtered[i];
                        final g = (f.properties.grupo ?? 'Sem Grupo').trim();
                        final d = currentPosition == null
                            ? null
                            : _featureDistanceM(f, currentPosition, distance);
                        return ListTile(
                          title: Text(f.properties.nome),
                          subtitle: Text(
                            '$g · ${f.properties.areaHa.toStringAsFixed(2)} ha'
                            '${d == null ? '' : ' · ${(d / 1000).toStringAsFixed(2)} km'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            widget.controller.selectFeature(f);
                            widget.onFocusFeature?.call(f);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      ),
    );
  }

  double _featureDistanceM(
    DrawingFeature feature,
    LatLng user,
    Distance distance,
  ) {
    final c = _featureCentroid(feature.geometry);
    if (c == null) return double.infinity;
    return distance.as(LengthUnit.Meter, user, c);
  }

  LatLng? _featureCentroid(DrawingGeometry geometry) {
    if (geometry is DrawingPolygon &&
        geometry.coordinates.isNotEmpty &&
        geometry.coordinates.first.isNotEmpty) {
      final ring = geometry.coordinates.first;
      double sumLat = 0;
      double sumLng = 0;
      for (final p in ring) {
        sumLng += p[0];
        sumLat += p[1];
      }
      return LatLng(sumLat / ring.length, sumLng / ring.length);
    }
    if (geometry is DrawingMultiPolygon &&
        geometry.coordinates.isNotEmpty &&
        geometry.coordinates.first.isNotEmpty &&
        geometry.coordinates.first.first.isNotEmpty) {
      final ring = geometry.coordinates.first.first;
      double sumLat = 0;
      double sumLng = 0;
      for (final p in ring) {
        sumLng += p[0];
        sumLat += p[1];
      }
      return LatLng(sumLat / ring.length, sumLng / ring.length);
    }
    return null;
  }

  // 🆕 REFATORADO: Métodos de construção de modo

  Widget _buildImportingMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Importar Arquivo',
            style: TextStyle(
              color: SoloForteSheetTokens.sectionLabel,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecione o arquivo KML ou KMZ para importar:',
            style: TextStyle(color: SoloForteSheetTokens.inputHint),
          ),
          const SizedBox(height: 24),
          _FormatButton(
            label: 'Importar Arquivo',
            sublabel: 'KML ou KMZ',
            icon: Icons.upload_file_rounded,
            onTap: () => widget.controller.pickImportFile(),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.controller.cancelOperation,
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: PremiumTokens.brandGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnionMode(BuildContext context) {
    return _buildBooleanOpMode(
      context,
      "Unir Áreas",
      "Selecione a segunda área para unir.",
      widget.controller.confirmBooleanOp,
    );
  }

  Widget _buildDifferenceMode(BuildContext context) {
    return _buildBooleanOpMode(
      context,
      "Subtrair Área",
      "Selecione a área a ser subtraída da original.",
      widget.controller.confirmBooleanOp,
    );
  }

  Widget _buildIntersectionMode(BuildContext context) {
    return _buildBooleanOpMode(
      context,
      "Interseção",
      "O resultado será apenas a área comum.",
      widget.controller.confirmBooleanOp,
    );
  }

  Widget _buildBooleanOpMode(
    BuildContext context,
    String title,
    String instructions,
    VoidCallback onConfirm,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: SoloForteSheetTokens.sectionLabel,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              instructions,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SoloForteSheetTokens.inputHint),
            ),
          ),
          if (widget.controller.errorMessage != null)
            Text(
              widget.controller.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.controller.cancelOperation,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: PremiumTokens.brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTokens.brandGreen,
                  ), // ✅ iOS Premium
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportPreviewMode(BuildContext context) {
    final hasImportWarning = widget.controller.hasPendingImportWarning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Visualizar Importação',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'A geometria foi carregada no mapa como visualização.\nConfirme para adicionar ao desenho.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SoloForteSheetTokens.sectionLabel),
            ),
          ),
          if (hasImportWarning) ...[
            _buildSelfIntersectionWarning(),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.controller.cancelOperation,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: PremiumTokens.brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.controller.confirmImport();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        PremiumTokens.brandGreen, // Keep import green
                  ),
                  child: Text(
                    hasImportWarning ? 'Importar assim mesmo' : 'Confirmar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMode(BuildContext context) {
    final feature = widget.controller.selectedFeature!;

    // 🆕 REFATORADO: Usar DrawingActionsBar component
    return DrawingActionsBar(
      selectedFeature: feature,
      onEditGeometry: widget.controller.startEditMode,
      onEditMetadata: () {
        showSoloForteSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          showDragHandle: false,
          useSafeArea: false,
          shape: const RoundedRectangleBorder(),
          clipBehavior: Clip.none,
          builder: (_) => DrawingInfoEditSheet(
            feature: feature,
            controller: widget.controller,
          ),
        );
      },
      onUnion: widget.controller.startUnionMode,
      onDifference: widget.controller.startDifferenceMode,
      onIntersection: widget.controller.startIntersectionMode,
      onExport: () => _exportSelected(context, feature),
      onExportAll: () => _exportAll(context),
      onToggleMultiSelect: () {
        widget.controller.setMultiSelectEnabled(
          !widget.controller.isMultiSelectEnabled,
        );
      },
      onDuplicateSelected: () async {
        await widget.controller.duplicateSelectedFeatures();
      },
      onMoveSelected: () async {
        final delta = await _askMoveDelta(context);
        if (delta == null) return;
        await widget.controller.moveSelectedFeatures(
          deltaLat: delta.$1,
          deltaLng: delta.$2,
        );
      },
      onSelectByGroup: () async {
        final group = await _askGroupName(context, feature.properties.grupo);
        if (group == null || group.trim().isEmpty) return;
        widget.controller.selectByGroup(group);
      },
      onDeleteSelected: () {
        widget.controller.deleteSelectedFeatures();
      },
      isMultiSelectEnabled: widget.controller.isMultiSelectEnabled,
      selectedCount: widget.controller.selectedFeatureIds.length,
      onDelete: () async {
        // 1. Guardar referência para undo
        final deletedFeature = feature;

        // 2. Deletar imediatamente
        widget.controller.deleteFeature(feature.id);

        // 3. Fechar o sheet
        Navigator.of(context, rootNavigator: false).pop();

        // 4. Mostrar feedback com Undo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${deletedFeature.properties.nome}" removido'),
            action: SnackBarAction(
              label: 'DESFAZER',
              onPressed: () {
                widget.controller.restoreFeature(deletedFeature);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      },
    );
  }

  Widget _buildEditingMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '✏️ Editando geometria',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(),
          if (widget.controller.hasSelfIntersection ||
              widget.controller.intersectionWarningMessage != null) ...[
            _buildSelfIntersectionWarning(),
            const SizedBox(height: 12),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Arraste os pontos para modificar a área.\nUse os controles laterais para salvar, desfazer, refazer ou cancelar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SoloForteSheetTokens.inputHint),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 ESTADO LOCAL JÁ DEFINIDO NO INÍCIO DA CLASSE
  // init state logic merged above

  // ... (dispose and other methods remain)

  // 🆕 FORMULÁRIO DE METADADOS (Climate FieldView Style - Hierárquico)
  Widget _buildReviewingMode(BuildContext context) {
    final area = widget.controller.liveAreaHa;
    final perimeter = widget.controller.livePerimeterKm;
    final f = NumberFormat("##0.##", "pt_BR");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Salvar Polígono',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              key: const Key('drawing_review_save_hint'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PremiumTokens.brandGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PremiumTokens.brandGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.save_outlined,
                    color: PremiumTokens.brandGreen,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Revise os dados e toque em salvar para criar o desenho no mapa.',
                      style: TextStyle(fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    key: const Key('drawing_review_save_cta_top'),
                    onPressed: _isSaving ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTokens.brandGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Salvar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.controller.hasSelfIntersection ||
                widget.controller.intersectionWarningMessage != null) ...[
              _buildSelfIntersectionWarning(),
              const SizedBox(height: 12),
            ],

            // 📊 Métricas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BigMetric(
                    icon: Icons.aspect_ratio,
                    value: '${f.format(area)} ha',
                    label: 'Área',
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _BigMetric(
                    icon: Icons.straighten,
                    value: '${f.format(perimeter)} km',
                    label: 'Perímetro',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Selecionar Cliente
            const Text(
              '👤 Cliente',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            _buildClientField(),
            const SizedBox(height: 16),

            // 2. Selecionar Fazenda
            const Text(
              '🚜 Fazenda / Grupo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<dynamic>(
              // Dynamic to allow 'NEW_FARM' string or Farm object
              initialValue: _selectedFarm,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              hint: const Text('Selecione a fazenda...'),
              items: [
                ...ref
                    .watch(drawingClientProvider)
                    .farms
                    .map(
                      (f) => DropdownMenuItem(value: f, child: Text(f.name)),
                    ),
                const DropdownMenuItem(
                  value: 'NEW_FARM',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Nova Fazenda',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (getValue) {
                if (getValue == 'NEW_FARM') {
                  if (_selectedClient == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecione o Cliente primeiro'),
                      ),
                    );
                    return;
                  }
                  _showCreateFarmDialog();
                } else {
                  setState(() => _selectedFarm = getValue as Farm?);
                }
              },
              validator: (v) => v == null && _selectedFarm == null
                  ? 'Selecione uma fazenda'
                  : null,
            ),
            const SizedBox(height: 16),

            // 3. Nome do Talhão
            const Text(
              '🏷️ Nome do Talhão',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                hintText: 'Ex: Talhão Norte',
                suffixText: '${f.format(area)} ha',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),

            // 4. Cor e Ações
            Row(
              children: [
                // Seletor de cor simplificado
                _ColorOption(
                  color: _selectedColor,
                  selected: _selectedColor,
                  onTap: (_) {},
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ColorOption(
                          color: PremiumTokens.brandGreen,
                          selected: _selectedColor,
                          onTap: (c) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = c);
                          },
                        ),
                        _ColorOption(
                          color: Colors.blue,
                          selected: _selectedColor,
                          onTap: (c) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = c);
                          },
                        ),
                        _ColorOption(
                          color: Colors.amber,
                          selected: _selectedColor,
                          onTap: (c) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = c);
                          },
                        ),
                        _ColorOption(
                          color: Colors.redAccent,
                          selected: _selectedColor,
                          onTap: (c) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = c);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _resetReviewForm();
                      widget.controller.cancelOperation();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('drawing_review_save_cta_bottom'),
                    onPressed: _isSaving ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTokens.brandGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isSaving ? 'SALVANDO...' : 'SALVAR',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfIntersectionWarning() {
    final message =
        widget.controller.intersectionWarningMessage ??
        'Linhas se cruzam. Salve e edite os vértices depois.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateFarmDialog() {
    final nameController = TextEditingController();
    final cityController = TextEditingController(
      text: _selectedClient?.city ?? '',
    );
    final stateController = TextEditingController(
      text: _selectedClient?.state ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Fazenda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome da Fazenda'),
              autofocus: true,
            ),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'Município'),
            ),
            TextField(
              controller: stateController,
              decoration: const InputDecoration(labelText: 'UF'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final clientId =
                  _selectedClient?.id ??
                  'SELF'; // TODO: Handle Producer ID properly
              await ref
                  .read(drawingClientProvider.notifier)
                  .createFarm(
                    nameController.text,
                    clientId,
                    cityController.text,
                    stateController.text,
                  );
              if (context.mounted) {
                Navigator.of(context, rootNavigator: false).pop();
              }

              // Auto-select the newly created farm (Assume it's the last one or find by name)
              // Simple approach: reload farms handled by controller, then user selects.
              // Or better: controller could return the ID.
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Widget _buildClientField() {
    final clientState = ref.watch(drawingClientProvider);
    if (clientState.preSelectedClientId != null) {
      final name =
          _selectedClient?.name ??
          clientState.preSelectedClientName ??
          'Cliente selecionado';
      return InputDecorator(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.lock_outline, size: 18),
        ),
        child: Text(name),
      );
    }

    return DropdownButtonFormField<Client>(
      initialValue: _selectedClient,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      hint: const Text('Selecione o cliente...'),
      items: clientState.clients.map((c) {
        return DropdownMenuItem(value: c, child: Text(c.name));
      }).toList(),
      onChanged: (client) {
        setState(() {
          _selectedClient = client;
          _selectedFarm = null;
        });
        if (client != null) {
          ref.read(drawingClientProvider.notifier).loadFarms(client.id);
        }
      },
      validator: (v) => v == null ? 'Selecione um cliente' : null,
    );
  }

  // Antigo helper de limpar form
  void _resetReviewForm() {
    _nomeController.text = "Talhão Novo";
    // _descricaoController.clear(); // Removed as per instruction
    final preserveContextClient =
        ref.read(drawingClientProvider).preSelectedClientId != null;
    setState(() {
      if (!preserveContextClient) _selectedClient = null;
      _selectedFarm = null;
      _selectedColor = PremiumTokens.brandGreen;
    });
  }

  Future<void> _exportSelected(
    BuildContext context,
    DrawingFeature feature,
  ) async {
    final format = await _selectExportFormat(context);
    if (format == null || !mounted) return;
    await ref
        .read(drawingExportProvider.notifier)
        .exportFeature(feature, format: format);
  }

  Future<void> _exportAll(BuildContext context) async {
    final format = await _selectExportFormat(context);
    if (format == null || !mounted) return;
    await ref
        .read(drawingExportProvider.notifier)
        .exportAll(widget.controller.features, format: format);
  }

  Future<DrawingExportFormat?> _selectExportFormat(BuildContext context) async {
    return showSoloForteSheet<DrawingExportFormat>(
      context: context,
      backgroundColor: SoloForteSheetTokens.sheetBackground,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Formato de exportação',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ..._ExportOption.values.map(
              (opt) => ListTile(
                leading: Icon(opt.icon, color: PremiumTokens.brandGreen),
                title: Text(opt.label),
                subtitle: Text(opt.subtitle),
                onTap: () => Navigator.of(ctx).pop(opt.format),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<(double, double)?> _askMoveDelta(BuildContext context) async {
    final latController = TextEditingController(text: '0.0000');
    final lngController = TextEditingController(text: '0.0000');
    return showDialog<(double, double)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mover polígonos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Delta latitude'),
            ),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Delta longitude'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final dLat = double.tryParse(latController.text);
              final dLng = double.tryParse(lngController.text);
              if (dLat == null || dLng == null) return;
              Navigator.of(ctx).pop((dLat, dLng));
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askGroupName(
    BuildContext context,
    String? initialValue,
  ) async {
    final controller = TextEditingController(text: initialValue ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecionar por grupo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome do grupo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Selecionar'),
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 12),
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF8E8E93),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ferramentas de Desenho',
              style: TextStyle(
                color: SoloForteSheetTokens.titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ],
    );
  }
}

enum _ExportOption {
  geojson(
    DrawingExportFormat.geojson,
    'GeoJSON',
    'Padrão GIS moderno',
    Icons.map_outlined,
  ),
  gpx(
    DrawingExportFormat.gpx,
    'GPX',
    'Trilhas e pontos GPS',
    Icons.route_outlined,
  ),
  dxf(
    DrawingExportFormat.dxf,
    'DXF',
    'CAD/AutoCAD',
    Icons.architecture_outlined,
  ),
  csv(
    DrawingExportFormat.csv,
    'CSV',
    'Planilha com vértices',
    Icons.table_chart_outlined,
  ),
  txt(
    DrawingExportFormat.txt,
    'TXT',
    'Relatório textual',
    Icons.description_outlined,
  ),
  pdf(
    DrawingExportFormat.pdf,
    'PDF',
    'Coordenadas para operação',
    Icons.picture_as_pdf_outlined,
  );

  final DrawingExportFormat format;
  final String label;
  final String subtitle;
  final IconData icon;

  const _ExportOption(this.format, this.label, this.subtitle, this.icon);
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetricItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData icon;
  final VoidCallback onTap;
  const _FormatButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.sublabel,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (sublabel != null) ...[
              const SizedBox(height: 4),
              Text(
                sublabel!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _BigMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: PremiumTokens.textSecondaryLight, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final Color selected;
  final ValueChanged<Color> onTap;

  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = color.toARGB32() == selected.toARGB32();
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                ),
              )
            : null,
      ),
    );
  }
}
