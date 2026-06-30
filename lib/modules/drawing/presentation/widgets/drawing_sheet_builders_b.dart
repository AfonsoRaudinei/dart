part of 'drawing_sheet.dart';

extension _DrawingSheetBuildersB on _DrawingSheetState {
  Widget _buildSelectedMode(BuildContext context) {
    final feature = widget.controller.selectedFeature!;

    if (_isEditingMetadata) {
      return DrawingInfoEditSheet(
        feature: feature,
        controller: widget.controller,
        embedded: true,
        onCancel: () => setState(() => _isEditingMetadata = false),
        onSaved: () {
          setState(() => _isEditingMetadata = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados do talhão salvos')),
          );
        },
      );
    }

    return DrawingActionsBar(
      selectedFeature: feature,
      onEditGeometry: widget.controller.startEditMode,
      onEditMetadata: () => setState(() => _isEditingMetadata = true),
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
        widget.onSaved?.call();
      },
      isMultiSelectEnabled: widget.controller.isMultiSelectEnabled,
      selectedCount: widget.controller.selectedFeatureIds.length,
      onDelete: () async {
        // 1. Guardar referência para undo
        final deletedFeature = feature;

        // 2. Deletar imediatamente
        widget.controller.deleteFeature(feature.id);

        // 3. Fechar o sheet pelo controlador do mapa, sem navegar.
        widget.onSaved?.call();

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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('drawing_edit_cancel_button'),
                  onPressed: () => _requestClose(
                    DrawingCloseIntent.cancelEditAndStaySelected,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('drawing_edit_save_button'),
                  onPressed: () =>
                      _requestClose(DrawingCloseIntent.saveEditAndClose),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTokens.brandGreen,
                  ),
                  child: const Text(
                    'Salvar e sair',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
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
    const sectionLabelStyle = TextStyle(
      color: SoloForteSheetTokens.sectionLabel,
      fontSize: SoloForteSheetTokens.sectionFontSize,
      fontWeight: SoloForteSheetTokens.sectionWeight,
    );

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
              style: TextStyle(
                color: SoloForteSheetTokens.titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                      style: TextStyle(
                        fontSize: 13.5,
                        color: SoloForteSheetTokens.sectionLabel,
                      ),
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
                color: SoloForteSheetTokens.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SoloForteSheetTokens.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BigMetric(
                    icon: Icons.aspect_ratio,
                    value: '${f.format(area)} ha',
                    label: 'Área',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: SoloForteSheetTokens.divider,
                  ),
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
            const Text('Cliente', style: sectionLabelStyle),
            const SizedBox(height: 8),
            _buildClientField(),
            const SizedBox(height: 16),

            // 2. Selecionar Fazenda
            const Text('Fazenda / Grupo', style: sectionLabelStyle),
            const SizedBox(height: 8),
            _buildFarmField(),
            const SizedBox(height: 16),

            // 3. Nome do Talhão
            const Text('Nome do Talhão', style: sectionLabelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomeController,
              style: const TextStyle(color: SoloForteSheetTokens.inputText),
              decoration: InputDecoration(
                hintText: 'Ex: Talhão Norte',
                hintStyle: const TextStyle(
                  color: SoloForteSheetTokens.inputHint,
                ),
                suffixText: '${f.format(area)} ha',
                suffixStyle: const TextStyle(
                  color: SoloForteSheetTokens.inputHint,
                ),
                filled: true,
                fillColor: SoloForteSheetTokens.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: PremiumTokens.brandGreen),
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
                      _requestClose(
                        DrawingCloseIntent.cancelFlowAndClose,
                        preferSavedCallback: true,
                      );
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
            SizedBox(
              height: kFabSafeArea + MediaQuery.of(context).padding.bottom + 16,
            ),
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
    final areaController = TextEditingController();

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
            TextField(
              controller: areaController,
              decoration: const InputDecoration(labelText: 'Área total (ha)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              if (nameController.text.trim().isEmpty) return;

              final clientId =
                  _selectedClient?.id ??
                  'SELF'; // TODO: Handle Producer ID properly
              final newFarm = await ref
                  .read(drawingClientProvider.notifier)
                  .createFarm(
                    nameController.text.trim(),
                    clientId,
                    cityController.text.trim(),
                    stateController.text.trim().toUpperCase(),
                    _parseArea(areaController.text),
                  );
              if (newFarm != null && mounted) {
                setState(() => _selectedFarm = newFarm);
              }
              if (context.mounted) {
                Navigator.of(context, rootNavigator: false).pop();
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      cityController.dispose();
      stateController.dispose();
      areaController.dispose();
    });
  }

  Widget _buildClientField() {
    final clientState = ref.watch(drawingClientProvider);
    if (clientState.preSelectedClientId != null) {
      final name =
          _selectedClient?.name ??
          clientState.preSelectedClientName ??
          'Cliente selecionado';
      return InputDecorator(
        decoration: _sheetFieldDecoration(
          suffixIcon: const Icon(
            Icons.lock_outline,
            size: 18,
            color: SoloForteSheetTokens.inputHint,
          ),
        ),
        child: Text(
          name,
          style: const TextStyle(color: SoloForteSheetTokens.inputText),
        ),
      );
    }

    return DropdownButtonFormField<Client>(
      initialValue: _selectedClient,
      decoration: _sheetFieldDecoration(),
      dropdownColor: SoloForteSheetTokens.inputBackground,
      style: const TextStyle(color: SoloForteSheetTokens.inputText),
      iconEnabledColor: SoloForteSheetTokens.inputHint,
      hint: const Text(
        'Selecione o cliente...',
        style: TextStyle(color: SoloForteSheetTokens.inputHint),
      ),
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

  Widget _buildFarmField() {
    final clientState = ref.watch(drawingClientProvider);
    if (clientState.preSelectedFarmId != null) {
      final name =
          _selectedFarm?.name ??
          clientState.preSelectedFarmName ??
          'Fazenda selecionada';
      return InputDecorator(
        decoration: _sheetFieldDecoration(
          suffixIcon: const Icon(
            Icons.lock_outline,
            size: 18,
            color: SoloForteSheetTokens.inputHint,
          ),
        ),
        child: Text(
          name,
          style: const TextStyle(color: SoloForteSheetTokens.inputText),
        ),
      );
    }

    return DropdownButtonFormField<dynamic>(
      initialValue: _selectedFarm,
      decoration: _sheetFieldDecoration(),
      dropdownColor: SoloForteSheetTokens.inputBackground,
      style: const TextStyle(color: SoloForteSheetTokens.inputText),
      iconEnabledColor: SoloForteSheetTokens.inputHint,
      hint: const Text(
        'Selecione a fazenda...',
        style: TextStyle(color: SoloForteSheetTokens.inputHint),
      ),
      items: [
        ...clientState.farms.map(
          (f) => DropdownMenuItem(value: f, child: Text(f.name)),
        ),
        const DropdownMenuItem(
          value: 'NEW_FARM',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text('Nova Fazenda', style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
      ],
      onChanged: (getValue) {
        if (getValue == 'NEW_FARM') {
          if (_selectedClient == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selecione o Cliente primeiro')),
            );
            return;
          }
          _showCreateFarmDialog();
          return;
        }
        setState(() => _selectedFarm = getValue as Farm?);
      },
      validator: (v) =>
          v == null && _selectedFarm == null ? 'Selecione uma fazenda' : null,
    );
  }

  // Antigo helper de limpar form
  void _resetReviewForm() {
    _nomeController.text = "Talhão Novo";
    // _descricaoController.clear(); // Removed as per instruction
    final clientState = ref.read(drawingClientProvider);
    final preserveContextClient = clientState.preSelectedClientId != null;
    final preserveContextFarm = clientState.preSelectedFarmId != null;
    setState(() {
      if (!preserveContextClient) _selectedClient = null;
      if (!preserveContextFarm) _selectedFarm = null;
      _selectedColor = PremiumTokens.brandGreen;
    });
  }

  InputDecoration _sheetFieldDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: SoloForteSheetTokens.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PremiumTokens.brandGreen),
      ),
    );
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
