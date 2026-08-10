part of 'occurrence_creation_sheet.dart';

extension _OccurrenceCreationSheetSubmit on _OccurrenceCreationSheetState {
  bool _hasValidPin() {
    if (!_pinLatitude.isFinite || !_pinLongitude.isFinite) return false;
    if (_pinLatitude < -90 || _pinLatitude > 90) return false;
    if (_pinLongitude < -180 || _pinLongitude > 180) return false;
    return _pinLatitude != 0 || _pinLongitude != 0;
  }

  void _showSubmitError(String message) {
    setState(() => _submitError = message);
    _scrollToSubmitError();
  }

  void _scrollToSubmitError() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget? _buildSubmitErrorBanner() {
    final message = _submitError;
    if (message == null) return null;

    return Container(
      key: const Key('occurrence_submit_error_banner'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PremiumTokens.alertError.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PremiumTokens.alertError.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: PremiumTokens.alertError,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final desc = _descCtrl.text.trim();
    if (!_hasValidPin()) {
      _showSubmitError(
        'Ponto do mapa inválido. Toque novamente no mapa para marcar a ocorrência.',
      );
      return;
    }
    if (_selectedCategoryValue == null && _cats.isEmpty && desc.isEmpty) {
      _showSubmitError(
        'Selecione ao menos uma categoria ou adicione uma descrição.',
      );
      return;
    }

    setState(() {
      _submitError = null;
      _isSaving = true;
    });
    HapticFeedback.mediumImpact();

    final primaryCat = _cats.isNotEmpty ? _cats.first.name : null;
    final firstPhoto = _fotos.values.firstOrNull?.firstOrNull;

    try {
      await widget.onConfirm(
        OccurrenceFormData(
          type: _urgency,
          description: desc,
          latitude: _pinLatitude,
          longitude: _pinLongitude,
          clientId: _selectedClient?.id,
          photoPath: firstPhoto,
          category: _selectedCategoryValue ?? primaryCat,
          cultivar: _cultivarCtrl.text.trim().isEmpty
              ? null
              : _cultivarCtrl.text.trim(),
          dataPlantio: _isoDate(_dataPlantio),
          estadioFenologico: _estadio?.code,
          tipoOcorrencia: null,
          amostraSolo: _selectedCategoryValue == 'amostra_solo',
          recomendacoes: _recomCtrl.text.trim().isEmpty
              ? null
              : _recomCtrl.text.trim(),
          metricasJson: _encodeMetricas(),
          nutrientesJson: _encodeNutrientes(),
          categoriasJson: _encodeCategorias(),
          notasCategoriasJson: _encodeNotas(),
          fotosCategoriasJson: _encodeFotos(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showSubmitError(
        error is StateError
            ? error.message
            : 'Não foi possível salvar a ocorrência. Tente novamente.',
      );
      setState(() => _isSaving = false);
    }
  }
}
