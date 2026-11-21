import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/widgets/photo/soloforte_photo_picker_sheet.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_sync_service.dart';
import 'package:soloforte_app/modules/drawing/data/services/teste_execucao_photo_service.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/models/teste_execucao.dart';
import 'package:uuid/uuid.dart';

/// Abre o sheet de implementação após salvar um polígono de teste.
Future<void> showTesteExecucaoSheet({
  required BuildContext context,
  required String drawingId,
  String? initialTalhao,
}) {
  return showSoloForteSheet<void>(
    context: context,
    useRootNavigator: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: null,
    builder: (sheetContext) => TesteExecucaoSheet(
      drawingId: drawingId,
      initialTalhao: initialTalhao,
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class TesteExecucaoSheet extends StatefulWidget {
  const TesteExecucaoSheet({
    super.key,
    required this.drawingId,
    this.initialTalhao,
    required this.onClose,
    this.localStore,
    this.photoService,
    this.syncService,
  });

  final String drawingId;
  final String? initialTalhao;
  final VoidCallback onClose;
  final TesteExecucaoLocalStore? localStore;
  final TesteExecucaoPhotoService? photoService;
  final DrawingSyncService? syncService;

  @override
  State<TesteExecucaoSheet> createState() => _TesteExecucaoSheetState();
}

class _TesteExecucaoSheetState extends State<TesteExecucaoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _talhaoCtrl;
  late final TextEditingController _implementacaoCtrl;
  String? _localPhotoPath;
  String? _fotoUrl;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _talhaoCtrl = TextEditingController(text: widget.initialTalhao ?? '');
    _implementacaoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _talhaoCtrl.dispose();
    _implementacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    await showSoloFortePhotoPicker(
      context: context,
      label: 'Foto da implementação',
      onPhotoSelected: (path) async {
        if (!mounted) return;
        setState(() {
          _localPhotoPath = path;
          _fotoUrl = null;
        });
      },
    );
  }

  Future<void> _confirm() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      String? uploadedUrl = _fotoUrl;
      if (_localPhotoPath != null && _localPhotoPath!.isNotEmpty) {
        setState(() => _isUploadingPhoto = true);
        final service =
            widget.photoService ?? TesteExecucaoPhotoService.live();
        uploadedUrl = await service.uploadPickedPath(
          context: context,
          path: _localPhotoPath!,
          folder: widget.drawingId,
        );
        if (!mounted) return;
        setState(() => _isUploadingPhoto = false);
      }

      final now = DateTime.now();
      final store = widget.localStore ?? TesteExecucaoLocalStore();
      final row = TesteExecucao(
        id: const Uuid().v4(),
        drawingId: widget.drawingId,
        userId: '',
        syncStatus: SyncStatus.pending_sync,
        talhao: _nullableTrim(_talhaoCtrl.text),
        implementacao: _nullableTrim(_implementacaoCtrl.text),
        fotoUrl: uploadedUrl,
        criadoEm: now,
        atualizadoEm: now,
      );
      await store.insert(row);

      final sync = widget.syncService ?? DrawingSyncService();
      unawaited(sync.synchronize());

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      widget.onClose();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingPhoto = false;
        });
      }
    }
  }

  String? _nullableTrim(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final isIos = soloForteSheetIsIos(context);
    final titleColor = v.titleColor;
    final inputText = v.titleColor;
    final inputHint = v.subtitleColor;
    final inputFill = v.cardBackground;
    final focusBorder = v.accent;
    final muted = v.subtitleColor;
    final busy = _isSaving || _isUploadingPhoto;
    final hasPhoto =
        (_localPhotoPath != null && _localPhotoPath!.isNotEmpty) ||
        (_fotoUrl != null && _fotoUrl!.isNotEmpty);

    InputDecoration fieldDecoration(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: inputHint),
          filled: true,
          fillColor: inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: isIos ? BorderSide(color: v.cardBorder) : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: isIos ? BorderSide(color: v.cardBorder) : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: focusBorder),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Implementação do teste',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Opcional: registre talhão, implementação e uma foto. O desenho já foi salvo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: muted),
            ),
            const SizedBox(height: 20),
            Text(
              'Talhão',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _talhaoCtrl,
              style: TextStyle(color: inputText),
              decoration: fieldDecoration('Nome ou código do talhão'),
            ),
            const SizedBox(height: 16),
            Text(
              'Implementação',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _implementacaoCtrl,
              style: TextStyle(color: inputText),
              minLines: 2,
              maxLines: 4,
              decoration: fieldDecoration('Descrição da implementação'),
            ),
            const SizedBox(height: 16),
            Text(
              'Foto (opcional)',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_localPhotoPath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_localPhotoPath!),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _pickPhoto,
                    icon: Icon(hasPhoto ? Icons.swap_horiz : Icons.add_a_photo),
                    label: Text(hasPhoto ? 'Trocar foto' : 'Adicionar foto'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : widget.onClose,
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : _confirm,
                    child: Text(
                      busy ? 'SALVANDO...' : 'CONFIRMAR',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}