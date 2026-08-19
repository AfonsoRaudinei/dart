// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soloforte_app/core/access/producer_create_context_resolver.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_producer_property_gateway_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/ui/sheets/widgets/sheet_section_header.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/occurrence.dart';
import '../../../relatorio_visita/data/image_storage_service.dart';
import '../coordinators/occurrence_form_guard.dart';
import '../providers/occurrence_draft_provider.dart';
import '../models/occurrence_form_draft.dart';
import 'occurrence_client_selector.dart';
import 'occurrence_fenologia_data.dart';
import 'occurrence_form_widgets.dart';

part 'occurrence_creation_sheet_models.dart';
part 'occurrence_creation_sheet_ui_helpers.dart';
part 'occurrence_creation_sheet_draft.dart';
part 'occurrence_creation_sheet_submit.dart';

class OccurrenceCreationSheet extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;
  final OccurrenceConfirmCallback onConfirm;
  final FutureOr<void> Function()? onCancel;
  final ScrollController? scrollController;
  final Occurrence? initialOccurrence;
  final OccurrenceFormGuard? formGuard;

  const OccurrenceCreationSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onConfirm,
    this.onCancel,
    this.scrollController,
    this.initialOccurrence,
    this.formGuard,
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
  bool _isSaving = false;
  String? _submitError;

  /// Pin imutável da abertura — ignora rebuild do pendingOccurrenceLocation.
  late final double _pinLatitude;
  late final double _pinLongitude;

  @override
  void initState() {
    super.initState();
    _pinLatitude = widget.latitude;
    _pinLongitude = widget.longitude;
    widget.formGuard?.readIsDirty = _hasUnsavedChanges;
    _clientsFuture = _loadClientsForCurrentRole();
    _hydrateInitialOccurrence();
    _restoreDraftIfAny();
    _cultivarCtrl.addListener(_persistDraft);
    _descCtrl.addListener(_persistDraft);
    _recomCtrl.addListener(_persistDraft);
    if (widget.initialOccurrence != null) {
      _prefillInitialClient();
    } else if (_selectedClient == null) {
      _prefillActiveVisitClient();
    }
  }

  Future<List<ClientSummary>> _loadClientsForCurrentRole() async {
    final lookup = ref.read(clientLookupProvider);
    final clients = List<ClientSummary>.from(await lookup.listAtivos());
    final role = ref.read(currentUserRoleProvider);
    if (!role.isProdutor) return clients;

    final own = await ProducerCreateContextResolver.asClientSummary(
      ref.read(producerPropertyGatewayProvider),
    );
    if (own == null) return clients;
    if (!clients.any((client) => client.id == own.id)) {
      clients.insert(0, own);
    }
    return clients;
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
      if (!mounted || _selectedClient != null) return;

      final clients = await _clientsFuture;
      if (!mounted || _selectedClient != null) return;

      if (activeContext != null) {
        final selected = clients
            .where((client) => client.id == activeContext.clientId)
            .firstOrNull;
        if (selected != null) {
          setState(() => _selectedClient = selected);
          return;
        }
      }

      final role = ref.read(currentUserRoleProvider);
      if (role.isProdutor && clients.isNotEmpty) {
        setState(() => _selectedClient = clients.first);
      }
    } catch (_) {
      // Ocorrências continuam disponíveis fora de uma visita ativa.
    }
  }

  @override
  void dispose() {
    // Sem gravação de rascunho aqui: mexer em provider durante dispose/deactivate
    // é proibido pelo Riverpod. Toda mutação do formulário já persiste na hora
    // (via _patchForm e listeners dos controllers).
    _cultivarCtrl.removeListener(_persistDraft);
    _descCtrl.removeListener(_persistDraft);
    _recomCtrl.removeListener(_persistDraft);
    if (widget.formGuard?.readIsDirty == _hasUnsavedChanges) {
      widget.formGuard?.readIsDirty = null;
    }
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
    _patchForm(() {
      _metrics.putIfAbsent(cat.name, () => {});
      _metrics[cat.name]![key] = value;
    });
  }

  void _toggleNutriente(String sym, bool selected) {
    _patchForm(() => selected ? _nutrientes.remove(sym) : _nutrientes.add(sym));
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

  void _registerPersistedPhoto(OccurrenceCategory cat, String path) {
    _patchForm(() {
      _fotos.putIfAbsent(cat.name, () => []);
      _fotos[cat.name]!.add(path);
    });
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

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    // No map stack o FAB fica fora do sheet — não reservar kFabSafeArea aqui.
    final actionBarBottomPadding = widget.scrollController != null
        ? (safeBottom > 0 ? safeBottom : 12.0)
        : safeBottom + 24.0;
    final isIos = occurrenceFormIsIos(context);
    final sheetBg = isIos
        ? SoloForteSheetSkinIos.background
        : SoloForteSheetTokens.sheetBackground;
    final accent = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : PremiumTokens.brandGreen;
    final titleColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final muted = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : const Color(0xFF8E8E93);
    return Material(
      color: sheetBg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
              if (_buildSubmitErrorBanner() case final banner?) banner,
              // ── Header padrão ADR-027 (espelha NovoCaseHeader) ──────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accent,
                        width: .6,
                      ),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: accent,
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
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Ponto definido no mapa',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onCancel != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _handleCancel,
                      color: muted,
                    ),
                ],
              ),
              const SizedBox(height: 20),

              SheetSectionHeader(
                icon: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: isIos
                      ? SoloForteSheetSkinIos.iconStroke
                      : Colors.white70,
                ),
                label: 'Cliente',
              ),
              OccurrenceClientSelector(
                clientsFuture: _clientsFuture,
                selectedClient: _selectedClient,
                onChanged: (value) => _patchForm(() => _selectedClient = value),
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
                  if (picked != null) _patchForm(() => _dataPlantio = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isIos
                        ? SoloForteSheetSkinIos.cardBackground
                        : const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(
                      isIos ? SoloForteSheetSkinIos.cardRadius : 12,
                    ),
                    border: Border.all(
                      color: isIos
                          ? SoloForteSheetSkinIos.cardBorder
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: isIos
                            ? SoloForteSheetSkinIos.iconStroke
                            : Colors.white54,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _dataPlantio != null
                              ? _formatDate(_dataPlantio!)
                              : 'Data de Plantio (opcional)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _dataPlantio != null
                                ? titleColor
                                : muted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_dataPlantio != null) ...[
                        GestureDetector(
                          onTap: () => _patchForm(() => _dataPlantio = null),
                          child: Icon(
                            Icons.clear,
                            size: 16,
                            color: muted,
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
                      Icon(Icons.grass, size: 14, color: muted),
                      const SizedBox(width: 6),
                      Text(
                        '${DateTime.now().difference(_dataPlantio!).inDays} dias desde o plantio (DAP real)',
                        style: TextStyle(
                          color: muted,
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
                onChanged: (e) => _patchForm(() => _estadio = e),
                onToggleCard: () => _patchForm(
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
                      _patchForm(() {
                        _selectedCategoryValue = cat.value;
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
                                : (isIos
                                      ? SoloForteSheetSkinIos.cardBackground
                                      : Colors.grey[800]),
                            border: isSelected
                                ? Border.all(color: selectedColor, width: 2)
                                : (isIos
                                      ? Border.all(
                                          color: SoloForteSheetSkinIos.cardBorder,
                                        )
                                      : null),
                          ),
                          child: Icon(
                            cat.icon,
                            size: 28,
                            color: isSelected
                                ? selectedColor
                                : (isIos
                                      ? SoloForteSheetSkinIos.subtitleColor
                                      : Colors.white70),
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
                                  : (isIos
                                        ? SoloForteSheetSkinIos.subtitleColor
                                        : Colors.white70),
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
                      onTap: () => _patchForm(() => _urgency = u),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withValues(alpha: .18)
                              : (isIos
                                    ? SoloForteSheetSkinIos.cardBackground
                                    : const Color(0xFF1C1C1E)),
                          borderRadius: BorderRadius.circular(
                            isIos ? SoloForteSheetSkinIos.cardRadius : 16,
                          ),
                          border: Border.all(
                            color: sel
                                ? color
                                : (isIos
                                      ? SoloForteSheetSkinIos.cardBorder
                                      : Colors.white12),
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            u,
                            style: TextStyle(
                              color: sel
                                  ? color
                                  : (isIos
                                        ? SoloForteSheetSkinIos.subtitleColor
                                        : Colors.white38),
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
              const SizedBox(height: 24),
              _buildPhotoActionSection(),
              const SizedBox(height: 20),
            ],
          ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                actionBarBottomPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _handleCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isIos
                            ? SoloForteSheetSkinIos.ghostText
                            : Colors.white54,
                        side: BorderSide(
                          color: isIos
                              ? SoloForteSheetSkinIos.ghostBorder
                              : Colors.white24,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isIos ? SoloForteSheetSkinIos.ghostRadius : 16,
                          ),
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
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isIos
                            ? SoloForteSheetSkinIos.ctaBackground
                            : PremiumTokens.brandGreen,
                        foregroundColor: isIos
                            ? SoloForteSheetSkinIos.ctaText
                            : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isIos ? SoloForteSheetSkinIos.ctaRadius : 50,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: isIos
                                    ? SoloForteSheetSkinIos.ctaText
                                    : Colors.black87,
                              ),
                            )
                          : Text(
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
            ),
          ),
        ],
      ),
    );
  }
}
