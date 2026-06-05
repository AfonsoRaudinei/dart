// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/ui/sheets/widgets/sheet_section_header.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/occurrence.dart';
import 'occurrence_client_selector.dart';
import 'occurrence_fenologia_data.dart';
import 'occurrence_form_widgets.dart';

part 'occurrence_creation_sheet_models.dart';
part 'occurrence_creation_sheet_ui_helpers.dart';

class OccurrenceCreationSheet extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;
  final OccurrenceConfirmCallback onConfirm;
  final VoidCallback? onCancel;
  final ScrollController? scrollController;
  final Occurrence? initialOccurrence;

  const OccurrenceCreationSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onConfirm,
    this.onCancel,
    this.scrollController,
    this.initialOccurrence,
  });

  @override
  ConsumerState<OccurrenceCreationSheet> createState() =>
      _OccurrenceCreationSheetState();
}

class _OccurrenceCreationSheetState
    extends ConsumerState<OccurrenceCreationSheet> {
  final _cultivarCtrl = TextEditingController();
  DateTime? _dataPlantio;
  EstadioData? _estadio;
  bool _estadioCardExpanded = false;
  final Set<OccurrenceCategory> _cats = {};
  final Map<String, Map<String, int>> _metrics = {};
  final Set<String> _nutrientes = {};
  final Map<String, TextEditingController> _notasCtrls = {};
  final Map<String, List<String>> _fotos = {};
  late final Future<List<ClientSummary>> _clientsFuture;
  ClientSummary? _selectedClient;
  String _urgency = 'Média';
  String? _selectedCategoryValue;
  final _descCtrl = TextEditingController();
  final _recomCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _clientsFuture = ref.read(clientLookupProvider).listAtivos();
    _hydrateInitialOccurrence();
    if (widget.initialOccurrence != null) {
      _prefillInitialClient();
    } else {
      _prefillActiveVisitClient();
    }
  }

  void _hydrateInitialOccurrence() {
    final occurrence = widget.initialOccurrence;
    if (occurrence == null) return;

    _cultivarCtrl.text = occurrence.cultivar ?? '';
    _descCtrl.text = occurrence.description;
    _recomCtrl.text = occurrence.recomendacoes ?? '';
    _urgency = occurrence.type;
    _selectedCategoryValue = occurrence.category;
    _dataPlantio = occurrence.dataPlantio != null
        ? DateTime.tryParse(occurrence.dataPlantio!)
        : null;
    _estadio = _findEstadio(occurrence.estadioFenologico);

    final cat = _categories
        .where((item) => item.value == occurrence.category)
        .firstOrNull
        ?.enumValue;
    if (cat != null) _cats.add(cat);

    _metrics.addAll(_decodeNestedIntMap(occurrence.metricasJson));
    _nutrientes.addAll(_decodeStringSet(occurrence.nutrientesJson));
    _fotos.addAll(_decodeStringListMap(occurrence.fotosCategoriasJson));
    final notas = _decodeStringMap(occurrence.notasCategoriasJson);
    for (final entry in notas.entries) {
      _notaCtrl(entry.key).text = entry.value;
    }
  }

  Future<void> _prefillInitialClient() async {
    try {
      final clientId = widget.initialOccurrence?.clientId;
      if (clientId == null || clientId.isEmpty) return;
      final clients = await _clientsFuture;
      if (!mounted || _selectedClient != null) return;
      final selected = clients
          .where((client) => client.id == clientId)
          .firstOrNull;
      if (selected != null) setState(() => _selectedClient = selected);
    } catch (_) {
      // Edição segue disponível mesmo se o cliente não estiver mais na lista.
    }
  }

  Future<void> _prefillActiveVisitClient() async {
    try {
      final activeContext = await ref
          .read(activeVisitContextLookupProvider)
          .getActiveContext();
      if (!mounted || activeContext == null || _selectedClient != null) return;

      final clients = await _clientsFuture;
      if (!mounted || _selectedClient != null) return;

      final selected = clients
          .where((client) => client.id == activeContext.clientId)
          .firstOrNull;
      if (selected != null) setState(() => _selectedClient = selected);
    } catch (_) {
      // Ocorrências continuam disponíveis fora de uma visita ativa.
    }
  }

  @override
  void dispose() {
    _cultivarCtrl.dispose();
    _descCtrl.dispose();
    _recomCtrl.dispose();
    for (final c in _notasCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _notaCtrl(String catName) =>
      _notasCtrls.putIfAbsent(catName, () => TextEditingController());

  Color _catColor(OccurrenceCategory cat) {
    switch (cat) {
      case OccurrenceCategory.doenca:
        return const Color(0xFF34C759);
      case OccurrenceCategory.insetos:
        return const Color(0xFFFF2D55);
      case OccurrenceCategory.daninhas:
        return const Color(0xFFFF9500);
      case OccurrenceCategory.nutricional:
        return const Color(0xFF8E8E93);
      case OccurrenceCategory.agua:
        return const Color(0xFF30B0C7);
      case OccurrenceCategory.amostraSolo:
        return const Color(0xFF8B5CF6);
    }
  }

  int _metricValue(OccurrenceCategory cat, String key) =>
      _metrics[cat.name]?[key] ?? 0;

  void _setMetric(OccurrenceCategory cat, String key, int value) {
    setState(() {
      _metrics.putIfAbsent(cat.name, () => {});
      _metrics[cat.name]![key] = value;
    });
  }

  void _toggleNutriente(String sym, bool selected) {
    setState(() => selected ? _nutrientes.remove(sym) : _nutrientes.add(sym));
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String? _isoDate(DateTime? d) => d == null
      ? null
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? _encodeMetricas() => _metrics.isEmpty ? null : jsonEncode(_metrics);

  String? _encodeNutrientes() =>
      _nutrientes.isEmpty ? null : jsonEncode(_nutrientes.toList());

  String? _encodeCategorias() =>
      _cats.isEmpty ? null : jsonEncode(_cats.map((c) => c.name).toList());

  String? _encodeNotas() {
    final map = _notasCtrls.map((k, v) => MapEntry(k, v.text));
    if (map.values.every((v) => v.isEmpty)) return null;
    return jsonEncode(map);
  }

  String? _encodeFotos() => _fotos.isEmpty ? null : jsonEncode(_fotos);

  EstadioData? _findEstadio(String? code) {
    if (code == null || code.isEmpty) return null;
    return kEstadios.where((item) => item.code == code).firstOrNull;
  }

  Map<String, Map<String, int>> _decodeNestedIntMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((key, value) {
        final inner = value is Map
            ? value.map(
                (innerKey, innerValue) => MapEntry(
                  innerKey.toString(),
                  innerValue is num
                      ? innerValue.toInt()
                      : int.tryParse(innerValue.toString()) ?? 0,
                ),
              )
            : <String, int>{};
        return MapEntry(key.toString(), Map<String, int>.from(inner));
      });
    } catch (_) {
      return {};
    }
  }

  Set<String> _decodeStringSet(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded.map((item) => item.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Map<String, String> _decodeStringMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  Map<String, List<String>> _decodeStringListMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((key, value) {
        final list = value is List
            ? value.map((item) => item.toString()).toList()
            : <String>[];
        return MapEntry(key.toString(), list);
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> _pickPhoto(OccurrenceCategory cat) async {
    final src = await showSoloForteSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (_) =>
          OccurrencePhotoSourceSheet(catEmoji: cat.emoji, catLabel: cat.label),
    );
    if (src == null) return;
    final xFile = await _picker.pickImage(
      source: src,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (xFile == null) return;
    setState(() {
      _fotos.putIfAbsent(cat.name, () => []);
      _fotos[cat.name]!.add(xFile.path);
    });
  }

  void _submit() {
    final desc = _descCtrl.text.trim();
    if (_selectedCategoryValue == null && _cats.isEmpty && desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione ao menos uma categoria ou adicione uma descrição.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();

    final primaryCat = _cats.isNotEmpty ? _cats.first.name : null;
    final firstPhoto = _fotos.values.firstOrNull?.firstOrNull;

    widget.onConfirm(
      OccurrenceFormData(
        type: _urgency,
        description: desc,
        clientId: _selectedClient?.id,
        photoPath: firstPhoto,
        category: _selectedCategoryValue ?? primaryCat,
        cultivar: _cultivarCtrl.text.trim().isEmpty
            ? null
            : _cultivarCtrl.text.trim(),
        dataPlantio: _isoDate(_dataPlantio),
        estadioFenologico: _estadio?.code,
        tipoOcorrencia: null, // FIX 3: removido da UI
        amostraSolo: _selectedCategoryValue == 'amostra_solo', // FIX 4
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
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: const Color(0xFF1C1C1E),
      child: Stack(
        children: [
          ListView(
            controller: widget.scrollController,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + keyboardHeight),
            children: [
              // ── Header padrão ADR-027 (espelha NovoCaseHeader) ──────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PremiumTokens.brandGreen.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PremiumTokens.brandGreen,
                        width: .6,
                      ),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: PremiumTokens.brandGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialOccurrence == null
                              ? 'Nova Ocorrência'
                              : 'Editar Ocorrência',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onCancel != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCancel,
                      color: const Color(0xFF8E8E93),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              const SheetSectionHeader(
                icon: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Colors.white70,
                ),
                label: 'Cliente',
              ),
              OccurrenceClientSelector(
                clientsFuture: _clientsFuture,
                selectedClient: _selectedClient,
                onChanged: (value) => setState(() => _selectedClient = value),
              ),
              const SizedBox(height: 20),

              const OccurrenceSectionHeader(
                icon: '🌱',
                title: 'Cultivar & Plantio',
              ),
              const SizedBox(height: 10),
              OccurrenceDarkField(
                controller: _cultivarCtrl,
                label: 'Cultivar (opcional)',
                hint: 'ex.: Intacta 2 IPRO, M6410 IPRO…',
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dataPlantio ?? DateTime.now(),
                    firstDate: DateTime(2010),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    helpText: 'Data de Plantio',
                  );
                  if (picked != null) setState(() => _dataPlantio = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _dataPlantio != null
                            ? _formatDate(_dataPlantio!)
                            : 'Data de Plantio (opcional)',
                        style: TextStyle(
                          color: _dataPlantio != null
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                      if (_dataPlantio != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _dataPlantio = null),
                          child: const Icon(
                            Icons.clear,
                            size: 16,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_dataPlantio != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.grass, size: 14, color: Colors.white38),
                      const SizedBox(width: 6),
                      Text(
                        '${DateTime.now().difference(_dataPlantio!).inDays} dias desde o plantio (DAP real)',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              const OccurrenceSectionHeader(
                icon: '📊',
                title: 'Estádio Fenológico',
              ),
              const SizedBox(height: 10),
              OccurrenceEstadioDropdown(
                selected: _estadio,
                expanded: _estadioCardExpanded,
                onChanged: (e) => setState(() => _estadio = e),
                onToggleCard: () => setState(
                  () => _estadioCardExpanded = !_estadioCardExpanded,
                ),
              ),
              const SizedBox(height: 20),

              const OccurrenceSectionHeader(
                icon: '🏷',
                title: 'Categorias da Ocorrência',
              ),
              const SizedBox(height: 8),
              // FIX 4: grid compacto de ícones circulares (seleção única)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategoryValue == cat.value;
                  final selectedColor =
                      cat.enumValue?.markerColor ?? const Color(0xFF795548);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategoryValue = cat.value;
                        // sincroniza _cats para manter SEÇÃO 4 (métricas) funcional
                        _cats.clear();
                        if (cat.enumValue != null) {
                          _cats.add(cat.enumValue!);
                        }
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? selectedColor.withValues(alpha: 0.2)
                                : Colors.grey[800],
                            border: isSelected
                                ? Border.all(color: selectedColor, width: 2)
                                : null,
                          ),
                          child: Icon(
                            cat.icon,
                            size: 28,
                            color: isSelected ? selectedColor : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 64,
                          child: Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? selectedColor
                                  : Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              ..._cats.map((cat) => _buildCategorySection(cat)),

              const OccurrenceSectionHeader(icon: '⚡', title: 'Urgência'),
              const SizedBox(height: 8),
              Row(
                children: ['Baixa', 'Média', 'Alta'].map((u) {
                  final sel = _urgency == u;
                  final color = u == 'Baixa'
                      ? const Color(0xFFFFCC00)
                      : u == 'Média'
                      ? const Color(0xFFFF9500)
                      : const Color(0xFFFF3B30);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _urgency = u),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withValues(alpha: .18)
                              : const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel ? color : Colors.white12,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            u,
                            style: TextStyle(
                              color: sel ? color : Colors.white38,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const OccurrenceSectionHeader(
                icon: '📝',
                title: 'Observações Gerais',
              ),
              const SizedBox(height: 8),
              OccurrenceDarkField(
                controller: _descCtrl,
                label: 'Descrição',
                hint: 'Descreva a ocorrência…',
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              const OccurrenceSectionHeader(icon: '✅', title: 'Recomendações'),
              const SizedBox(height: 8),
              OccurrenceDarkField(
                controller: _recomCtrl,
                label: 'Recomendações',
                hint: 'Ações sugeridas para correção…',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onCancel?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTokens.brandGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        widget.initialOccurrence == null
                            ? 'Salvar Ocorrência'
                            : 'Salvar Alterações',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_cats.isNotEmpty)
            Positioned(
              bottom: 12,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'photo_fab',
                backgroundColor: const Color(0xFF2C2C2E),
                foregroundColor: Colors.white,
                onPressed: () async {
                  if (_cats.length == 1) {
                    await _pickPhoto(_cats.first);
                  } else {
                    final cat = await showSoloForteSheet<OccurrenceCategory>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      showDragHandle: false,
                      useSafeArea: false,
                      shape: const RoundedRectangleBorder(),
                      clipBehavior: Clip.none,
                      builder: (_) =>
                          OccurrenceCatPickerSheet(cats: _cats.toList()),
                    );
                    if (cat != null) await _pickPhoto(cat);
                  }
                },
                icon: const Text('📷', style: TextStyle(fontSize: 18)),
                label: const Text('Próxima Foto'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(OccurrenceCategory cat) {
    final color = _catColor(cat);
    final metrics = categoryMetrics(cat.name);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (cat == OccurrenceCategory.nutricional)
              _buildNutrientGrid(color)
            else if (cat == OccurrenceCategory.agua)
              _buildAguaSection(color)
            else
              ...metrics.map(
                (metric) => OccurrenceSliderRow(
                  label: metricLabel(metric),
                  value: _metricValue(cat, metric),
                  color: color,
                  onChanged: (v) => _setMetric(cat, metric, v),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: OccurrenceDarkField(
                controller: _notaCtrl(cat.name),
                label: 'Notas (${cat.label})',
                hint: 'Observações específicas…',
                maxLines: 2,
              ),
            ),
            if (_fotos[cat.name]?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fotos[cat.name]!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final path = _fotos[cat.name]![i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(path),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _fotos[cat.name]!.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
