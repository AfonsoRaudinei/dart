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
    final isIos = soloForteSheetIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
    final panelBg = v.cardBackground;
    final panelBorder = v.cardBorder;
    final labelColor = v.subtitleColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(
          isIos
              ? SoloForteSheetSkinIos.cardRadius
              : PremiumTokens.borderRadiusSm,
        ),
        border: Border.all(
          color: panelBorder,
          width: PremiumTokens.hairlineThickness,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.square_foot, size: 16, color: labelColor),
              const SizedBox(width: 6),
              Text(
                'MÉTRICAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
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
    final pendingCount = widget.controller.pendingSyncCount;
    final isIos = soloForteSheetIsIos(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          DrawingToolSelector(
            selectedToolKey: _selectedToolKey,
            onToolSelected: _onToolSelected,
          ),
          if (pendingCount > 0) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _syncPendingFeatures(context),
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
              label: Text('Enviar alterações ($pendingCount)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isIos
                    ? SoloForteSheetSkinIos.ctaBackground
                    : Colors.orange,
                foregroundColor: Colors.white,
                shape: isIos
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          SoloForteSheetSkinIos.ctaRadius,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _syncPendingFeatures(BuildContext context) async {
    final result = await widget.controller.syncFeatures();
    if (!context.mounted || result == null || result.conflicts.isEmpty) {
      return;
    }

    for (final conflict in result.conflicts) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => ConflictResolutionDialog(
          title: 'Conflito de sincronização',
          description:
              'A geometria "${conflict.properties.nome}" foi alterada '
              'localmente e no servidor. Escolha qual versão manter.',
          onUseLocal: () {
            widget.controller.resolveConflictUseLocal(conflict.id);
          },
          onUseRemote: () {
            widget.controller.resolveConflictUseRemote(conflict);
          },
        ),
      );
    }
  }

  // Métodos de construção de modo

  Widget _buildImportingMode(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.sectionLabel;
    final hintColor = v.subtitleColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Importar Arquivo',
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione o arquivo KML ou KMZ para importar:',
            style: TextStyle(color: hintColor),
          ),
          const SizedBox(height: 24),
          _FormatButton(
            label: 'Importar Arquivo',
            sublabel: 'KML ou KMZ',
            icon: Icons.upload_file_rounded,
            onTap: () => widget.controller.pickImportFile(),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () =>
                _requestClose(DrawingCloseIntent.cancelFlowAndClose),
            style: isIos
                ? OutlinedButton.styleFrom(
                    foregroundColor: SoloForteSheetSkinIos.ghostText,
                    side: const BorderSide(
                      color: SoloForteSheetSkinIos.ghostBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        SoloForteSheetSkinIos.ghostRadius,
                      ),
                    ),
                  )
                : OutlinedButton.styleFrom(
                    foregroundColor: context.themeAccent,
                    side: BorderSide(
                      color: context.themeAccent.withValues(alpha: 0.4),
                    ),
                  ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isIos
                    ? SoloForteSheetSkinIos.ghostText
                    : context.themeAccent,
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
    final isIos = soloForteSheetIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.sectionLabel;
    final hintColor = v.subtitleColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
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
              style: TextStyle(color: hintColor),
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
                child: OutlinedButton(
                  onPressed: () =>
                      _requestClose(DrawingCloseIntent.cancelFlowAndClose),
                  style: isIos
                      ? OutlinedButton.styleFrom(
                          foregroundColor: SoloForteSheetSkinIos.ghostText,
                          side: const BorderSide(
                            color: SoloForteSheetSkinIos.ghostBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              SoloForteSheetSkinIos.ghostRadius,
                            ),
                          ),
                        )
                      : OutlinedButton.styleFrom(
                          foregroundColor: context.themeAccent,
                          side: BorderSide(
                            color: context.themeAccent.withValues(alpha: 0.4),
                          ),
                        ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isIos
                          ? SoloForteSheetSkinIos.ghostText
                          : context.themeAccent,
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
                    backgroundColor: isIos
                        ? SoloForteSheetSkinIos.ctaBackground
                        : context.themeAccent,
                    foregroundColor: Colors.white,
                    shape: isIos
                        ? RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              SoloForteSheetSkinIos.ctaRadius,
                            ),
                          )
                        : null,
                  ),
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
    final previewGeometry = widget.controller.liveGeometry;
    final detectedParts = widget.controller.polygonPartCount(previewGeometry);

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
          if (detectedParts > 1) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.themeAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.themeAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '$detectedParts talhões detectados no arquivo. '
                'Cada um será salvo separadamente.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: SoloForteSheetTokens.sectionLabel,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: context.themeAccent,
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
                    backgroundColor: context.themeAccent, // Keep import green
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
