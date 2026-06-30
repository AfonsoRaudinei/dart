part of 'drawing_sheet.dart';

extension _DrawingSheetBuildersA on _DrawingSheetState {
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
            onPressed: () =>
                _requestClose(DrawingCloseIntent.cancelFlowAndClose),
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
                  onPressed: () =>
                      _requestClose(DrawingCloseIntent.cancelFlowAndClose),
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
                  onPressed: () =>
                      _requestClose(DrawingCloseIntent.cancelFlowAndClose),
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

}
