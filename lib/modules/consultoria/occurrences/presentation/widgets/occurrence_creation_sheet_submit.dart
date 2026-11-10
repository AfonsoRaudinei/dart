part of 'occurrence_creation_sheet.dart';

/// Compara só o dia — hora do picker não conta.
bool _terminoAntesDoInicio(DateTime? inicio, DateTime? termino) {
  if (inicio == null || termino == null) return false;
  return DateTime(termino.year, termino.month, termino.day)
      .isBefore(DateTime(inicio.year, inicio.month, inicio.day));
}

extension _OccurrenceCreationSheetSubmit on _OccurrenceCreationSheetState {
  bool _hasValidPin() {
    if (!_pinLatitude.isFinite || !_pinLongitude.isFinite) return false;
    if (_pinLatitude < -90 || _pinLatitude > 90) return false;
    if (_pinLongitude < -180 || _pinLongitude > 180) return false;
    return _pinLatitude != 0 || _pinLongitude != 0;
  }

  void _showSubmitError(String message) {
    _notifyStateChanged(() => _submitError = message);
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

  /// Sem adapter registrado (ex.: testes) o write-back é ignorado.
  IDrawingFieldWriter? _readFieldWriter() {
    try {
      return ref.read(iDrawingFieldWriterProvider);
    } on UnimplementedError {
      return null;
    }
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
    if (!_isAreaVisitada &&
        _selectedCategoryValue == null &&
        _cats.isEmpty &&
        desc.isEmpty) {
      _showSubmitError(
        'Selecione ao menos uma categoria ou adicione uma descrição.',
      );
      return;
    }
    if (_terminoAntesDoInicio(_dataPlantio, _dataFimPlantio)) {
      _showSubmitError('O término do plantio não pode ser antes do início.');
      return;
    }

    final fieldId = _plantioFieldId(watch: false);
    final plantio = _plantioValuesForSubmit();

    _notifyStateChanged(() {
      _submitError = null;
      _isSaving = true;
    });
    HapticFeedback.mediumImpact();

    final primaryCat = _cats.isNotEmpty ? _cats.first.name : null;
    final category = _selectedCategoryValue ?? primaryCat;
    final plantios = _loadedPlantiosForWriteBack(fieldId);
    final writeBackFieldId =
        fieldId != null &&
            _shouldWriteBackPlantio(
              fieldId: fieldId,
              values: plantio,
              plantios: plantios,
            )
        ? fieldId
        : null;
    final talhaoWriter = writeBackFieldId == null ? null : _readFieldWriter();
    final firstPhoto = _fotos.values.firstOrNull?.firstOrNull;
    final isAmostra = _isAmostraSolo;
    final tramite = _amostraTramite ?? OccurrenceAmostraTramite.coletada;
    final laudoTrim = _amostraLaudoCtrl.text.trim();

    try {
      await widget.onConfirm(
        OccurrenceFormData(
          type: _urgency,
          description: desc,
          latitude: _pinLatitude,
          longitude: _pinLongitude,
          clientId: _isAreaVisitada && widget.initialOccurrence == null
              ? null
              : _selectedClient?.id,
          photoPath: firstPhoto,
          category: category,
          cultivar: plantio.cultivar,
          cultura: plantio.cultura,
          safra: plantio.safra,
          dataPlantio: plantio.dataPlantio,
          dataEmergencia: plantio.dataEmergencia,
          dataFimPlantio: plantio.dataFimPlantio,
          cicloDias: plantio.cicloDias,
          sementesPorMetro: double.tryParse(
            _sementesPorMetroCtrl.text.trim().replaceAll(',', '.'),
          ),
          estandePlantas: int.tryParse(_estandePlantasCtrl.text.trim()),
          avaliacaoPlantio: sanitizeAvaliacaoPlantio(_avaliacaoPlantio),
          objetivoPlantio: _objetivoPlantioCtrl.text.trim().isEmpty
              ? null
              : _objetivoPlantioCtrl.text.trim(),
          fieldId: fieldId,
          estadioFenologico: _estadio?.code,
          tipoOcorrencia: null,
          amostraSolo: isAmostra,
          amostraCodigo: isAmostra && _amostraCodigoCtrl.text.trim().isNotEmpty
              ? _amostraCodigoCtrl.text.trim()
              : null,
          amostraColetor: isAmostra && _amostraColetorCtrl.text.trim().isNotEmpty
              ? _amostraColetorCtrl.text.trim()
              : null,
          amostraTramite: isAmostra ? tramite.storageValue : null,
          amostraLaudoTexto: isAmostra &&
                  tramite == OccurrenceAmostraTramite.laudoPronto &&
                  laudoTrim.isNotEmpty
              ? laudoTrim
              : null,
          recomendacaoAcao: _ordem.acao.text,
          recomendacaoDose: _ordem.dose.text,
          recomendacaoQuando: _ordem.quando.text,
          recomendacoes: _ordem.legacyText,
          metricasJson: _encodeMetricas(),
          nutrientesJson: _encodeNutrientes(),
          categoriasJson: _encodeCategorias(),
          notasCategoriasJson: _encodeNotas(),
          fotosCategoriasJson: _encodeFotos(),
          audioPath: _audioPath,
          audioDurationSec: _audioDurationSec,
        ),
      );
      if (talhaoWriter != null && writeBackFieldId != null) {
        await writeBackTalhaoPlantio(
          writer: talhaoWriter,
          fieldId: writeBackFieldId,
          category: category,
          cultura: plantio.cultura,
          cultivar: plantio.cultivar,
          safra: plantio.safra,
          dataPlantio: plantio.dataPlantio,
          dataEmergencia: plantio.dataEmergencia,
          cicloDias: plantio.cicloDias,
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showSubmitError(
        error is StateError
            ? error.message
            : 'Não foi possível salvar a ocorrência. Tente novamente.',
      );
      _notifyStateChanged(() => _isSaving = false);
    }
  }
}
