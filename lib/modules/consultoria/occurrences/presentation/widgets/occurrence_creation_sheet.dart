// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/access/producer_create_context_resolver.dart';
import 'package:soloforte_app/core/widgets/photo/soloforte_photo_picker_sheet.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_keyboard_inset.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_producer_property_gateway_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/ui/sheets/widgets/sheet_section_header.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/occurrence.dart';
import '../../domain/occurrence_amostra_solo.dart';
import '../../domain/occurrence_plantio_context.dart';
import '../../domain/occurrence_soy_age.dart';
import '../models/occurrence_talhao_prefill.dart';
import '../../domain/occurrence_photo_paths.dart';
import '../../../relatorio_visita/data/image_storage_service.dart';
import '../coordinators/occurrence_form_guard.dart';
import '../providers/occurrence_draft_provider.dart';
import '../providers/occurrence_location_provider.dart';
import '../providers/occurrence_plantio_context_provider.dart';
import '../models/occurrence_form_draft.dart';
import 'occurrence_amostra_solo_section.dart';
import 'occurrence_client_selector.dart';
import 'occurrence_date_field.dart';
import 'package:soloforte_app/core/domain/soy_phenology.dart';
import 'occurrence_fenologia_data.dart' hide EstadioData, kEstadios;
import 'occurrence_form_widgets.dart';
import 'occurrence_ordem_aplicacao_controllers.dart';
import 'occurrence_audio_field.dart';
import 'occurrence_photo_gallery.dart';
import 'occurrence_plantio_summary_card.dart';

part 'occurrence_creation_sheet_models.dart';
part 'occurrence_creation_sheet_ui_helpers.dart';
part 'occurrence_creation_sheet_draft.dart';
part 'occurrence_creation_sheet_submit.dart';
part 'occurrence_creation_sheet_plantio_context.dart';

class OccurrenceCreationSheet extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;
  final OccurrenceConfirmCallback onConfirm;
  final FutureOr<void> Function()? onCancel;
  final ScrollController? scrollController;
  final Occurrence? initialOccurrence;
  final OccurrenceFormGuard? formGuard;

  /// Pré-seleciona categoria na criação (ex.: `area_visitada` via ações rápidas).
  final String? initialCategoryValue;
  final OccurrenceTalhaoPrefill? talhaoPrefill;
  final bool compactHeader;

  /// Sobe a barra Cancelar/Salvar acima do teclado.
  ///
  /// False nos hosts do mapa ([MapBottomSheet] / mark sheet), que já
  /// subtraem `viewInsets` do detent.
  final bool liftStickyActionsForKeyboard;

  const OccurrenceCreationSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onConfirm,
    this.onCancel,
    this.scrollController,
    this.initialOccurrence,
    this.formGuard,
    this.initialCategoryValue,
    this.talhaoPrefill,
    this.compactHeader = false,
    this.liftStickyActionsForKeyboard = true,
  });

  @override
  ConsumerState<OccurrenceCreationSheet> createState() =>
      _OccurrenceCreationSheetState();
}

class _OccurrenceCreationSheetState
    extends ConsumerState<OccurrenceCreationSheet> {
  final _cultivarCtrl = TextEditingController();
  final _culturaCtrl = TextEditingController();
  final _safraCtrl = TextEditingController();
  DateTime? _dataPlantio;
  DateTime? _dataEmergencia;
  DateTime? _dataFimPlantio;
  final _sementesPorMetroCtrl = TextEditingController();
  final _estandePlantasCtrl = TextEditingController();
  String? _avaliacaoPlantio;
  final _objetivoPlantioCtrl = TextEditingController();
  final _amostraCodigoCtrl = TextEditingController();
  final _amostraColetorCtrl = TextEditingController();
  final _amostraLaudoCtrl = TextEditingController();
  OccurrenceAmostraTramite? _amostraTramite;
  final _cicloDiasCtrl = TextEditingController();
  EstadioData? _estadio;
  bool _estadioSugerido = false;
  bool _estadioSuggestionDone = false;
  bool _plantioContextApplied = false;

  /// Card "Dados do plantio" do último build; null = bloco editável.
  OccurrencePlantioContext? _plantioSummary;
  bool _estadioCardExpanded = false;
  final Set<OccurrenceCategory> _cats = {};
  final Map<String, Map<String, int>> _metrics = {};
  final Set<String> _nutrientes = {};
  final Map<String, TextEditingController> _notasCtrls = {};
  final Map<String, List<String>> _fotos = {};
  final Map<String, String> _photoCaptions = {};
  late final Future<List<ClientSummary>> _clientsFuture;
  ClientSummary? _selectedClient;
  String _urgency = 'Média';
  String? _selectedCategoryValue;
  final _descCtrl = TextEditingController();
  final _ordem = OccurrenceOrdemAplicacaoControllers();
  bool _isSaving = false;
  String? _submitError;
  String? _audioPath;
  int? _audioDurationSec;

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
    _applyInitialCategoryValue();
    _restoreDraftIfAny();
    _applyTalhaoPrefillFields();
    _cultivarCtrl.addListener(_persistDraft);
    _culturaCtrl.addListener(_persistDraft);
    _safraCtrl.addListener(_persistDraft);
    _descCtrl.addListener(_persistDraft);
    _ordem.addListener(_persistDraft);
    _sementesPorMetroCtrl.addListener(_persistDraft);
    _estandePlantasCtrl.addListener(_persistDraft);
    _objetivoPlantioCtrl.addListener(_persistDraft);
    _amostraCodigoCtrl.addListener(_persistDraft);
    _amostraColetorCtrl.addListener(_persistDraft);
    _amostraLaudoCtrl.addListener(_persistDraft);
    _cicloDiasCtrl.addListener(_onCicloDiasChanged);
    if (widget.initialOccurrence != null) {
      _prefillInitialClient();
    } else if (_selectedClient == null && !_isAreaVisitada) {
      _prefillActiveVisitClient();
    }
  }

  /// Usado pelos `part` files — evita `invalid_use_of_protected_member` no analyzer CI.
  void _notifyStateChanged(VoidCallback fn) => setState(fn);

  void _applyInitialCategoryValue() {
    if (widget.initialOccurrence != null) return;
    final value = widget.initialCategoryValue;
    if (value == null || value.isEmpty) return;

    if (value == kOccurrenceAreaVisitadaCategory) {
      _selectedCategoryValue = value;
      _cats
        ..clear()
        ..add(OccurrenceCategory.areaVisitada);
      _selectedClient = null;
      return;
    }

    final cat = _categories.where((item) => item.value == value).firstOrNull;
    if (cat == null) return;

    _selectedCategoryValue = cat.value;
    _cats.clear();
    if (cat.enumValue != null) {
      _cats.add(cat.enumValue!);
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
    _culturaCtrl.text = occurrence.cultura ?? '';
    _safraCtrl.text = occurrence.safra ?? '';
    _descCtrl.text = occurrence.description;
    _ordem.load(occurrence);
    _urgency = occurrence.type;
    _selectedCategoryValue = occurrence.category;
    _dataPlantio = occurrence.dataPlantio != null
        ? DateTime.tryParse(occurrence.dataPlantio!)
        : null;
    _dataEmergencia = occurrence.dataEmergencia != null
        ? DateTime.tryParse(occurrence.dataEmergencia!)
        : null;
    _dataFimPlantio = occurrence.dataFimPlantio != null
        ? DateTime.tryParse(occurrence.dataFimPlantio!)
        : null;
    _cicloDiasCtrl.text = occurrence.cicloDias?.toString() ?? '';
    _sementesPorMetroCtrl.text = occurrence.sementesPorMetro?.toString() ?? '';
    _estandePlantasCtrl.text = occurrence.estandePlantas?.toString() ?? '';
    _avaliacaoPlantio = occurrence.avaliacaoPlantio;
    _objetivoPlantioCtrl.text = occurrence.objetivoPlantio ?? '';
    _amostraCodigoCtrl.text = occurrence.amostraCodigo ?? '';
    _amostraColetorCtrl.text = occurrence.amostraColetor ?? '';
    _amostraLaudoCtrl.text = occurrence.amostraLaudoTexto ?? '';
    _amostraTramite = OccurrenceAmostraTramite.fromStorage(
      occurrence.amostraTramite,
    );
    _estadio = _findEstadio(occurrence.estadioFenologico);

    final cat = _categories
        .where((item) => item.value == occurrence.category)
        .firstOrNull
        ?.enumValue;
    if (cat != null) _cats.add(cat);

    _metrics.addAll(_decodeNestedIntMap(occurrence.metricasJson));
    _nutrientes.addAll(_decodeStringSet(occurrence.nutrientesJson));
    _fotos.addAll(
      parseFotosCategoriasByCategory(occurrence.fotosCategoriasJson),
    );
    _photoCaptions.addAll(parseFotosCaptions(occurrence.fotosCategoriasJson));
    _audioPath = occurrence.audioPath;
    _audioDurationSec = occurrence.audioDurationSec;
    if (_fotos.isEmpty &&
        occurrence.photoPath != null &&
        occurrence.photoPath!.isNotEmpty) {
      final catKey = cat?.name ?? occurrence.category ?? 'geral';
      _fotos[catKey] = [occurrence.photoPath!];
    }
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

  @override
  void dispose() {
    // Sem gravação de rascunho aqui: mexer em provider durante dispose/deactivate
    // é proibido pelo Riverpod. Toda mutação do formulário já persiste na hora
    // (via _patchForm e listeners dos controllers).
    _cultivarCtrl.removeListener(_persistDraft);
    _culturaCtrl.removeListener(_persistDraft);
    _safraCtrl.removeListener(_persistDraft);
    _descCtrl.removeListener(_persistDraft);
    _ordem.removeListener(_persistDraft);
    _sementesPorMetroCtrl.removeListener(_persistDraft);
    _estandePlantasCtrl.removeListener(_persistDraft);
    _objetivoPlantioCtrl.removeListener(_persistDraft);
    _amostraCodigoCtrl.removeListener(_persistDraft);
    _amostraColetorCtrl.removeListener(_persistDraft);
    _amostraLaudoCtrl.removeListener(_persistDraft);
    _cicloDiasCtrl.removeListener(_onCicloDiasChanged);
    if (widget.formGuard?.readIsDirty == _hasUnsavedChanges) {
      widget.formGuard?.readIsDirty = null;
    }
    _cultivarCtrl.dispose();
    _culturaCtrl.dispose();
    _safraCtrl.dispose();
    _descCtrl.dispose();
    _ordem.dispose();
    _sementesPorMetroCtrl.dispose();
    _estandePlantasCtrl.dispose();
    _objetivoPlantioCtrl.dispose();
    _amostraCodigoCtrl.dispose();
    _amostraColetorCtrl.dispose();
    _amostraLaudoCtrl.dispose();
    _cicloDiasCtrl.dispose();
    for (final c in _notasCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _notaCtrl(String catName) =>
      _notasCtrls.putIfAbsent(catName, () => TextEditingController());

  bool get _isAreaVisitada =>
      _selectedCategoryValue == kOccurrenceAreaVisitadaCategory;

  bool get _isAmostraSolo => _selectedCategoryValue == 'amostra_solo';

  bool get _isPlantio => _selectedCategoryValue == 'plantio';

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
      case OccurrenceCategory.plantio:
        return const Color(0xFFA16207);
      case OccurrenceCategory.areaVisitada:
        return const Color(0xFF607D8B);
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

  void _setPhotoCaption(String path, String caption) {
    _patchForm(() {
      final clipped = clipOccurrencePhotoCaption(caption);
      if (clipped.isEmpty) {
        _photoCaptions.remove(path);
      } else {
        _photoCaptions[path] = clipped;
      }
    });
  }

  void _dropCaptionIfOrphan(String path) {
    final stillUsed = _fotos.values.any((list) => list.contains(path));
    if (!stillUsed) _photoCaptions.remove(path);
  }

  String? _encodeFotos() =>
      encodeFotosCategoriasWithCaptions(_fotos, _photoCaptions);

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

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final actionBarBottomPadding = sheetStickyActionBottomPadding(
      safeBottom: safeBottom,
      keyboard: keyboard,
      liftForKeyboard: widget.liftStickyActionsForKeyboard,
      closedExtra: kFabSafeArea,
    );
    final isIos = occurrenceFormIsIos(context);
    final sheetBg = v.sheetBackground;
    final accent = isIos ? v.iconStroke : context.themeAccent;
    final titleColor = v.onSheetPrimary;
    final muted = v.subtitleColor;
    _watchPlantioContext();
    return Material(
      color: sheetBg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (_buildSubmitErrorBanner() case final banner?) banner,
                _buildFormHeader(
                  accent: accent,
                  muted: muted,
                  titleColor: titleColor,
                ),
                _buildLocationLine(muted),
                const SizedBox(height: 20),

                SheetSectionHeader(
                  icon: Icon(
                    Icons.person_outline,
                    size: 18,
                    color: isIos ? v.iconStroke : v.subtitleColor,
                  ),
                  label: _isAreaVisitada ? 'Cliente (opcional)' : 'Cliente',
                ),
                OccurrenceClientSelector(
                  clientsFuture: _clientsFuture,
                  selectedClient: _selectedClient,
                  onChanged: (value) =>
                      _patchForm(() => _selectedClient = value),
                ),
                if (_isAreaVisitada && _selectedClient == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Sem cliente agora? Você pode vincular depois na ficha.',
                    style: TextStyle(color: muted, fontSize: 12, height: 1.35),
                  ),
                ],
                const SizedBox(height: 20),

                if (!_isAreaVisitada) ...[
                  const OccurrenceSectionHeader(
                    title: 'Categorias da Ocorrência',
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryPicker(),
                  const SizedBox(height: 16),
                ],

                if (!_isAreaVisitada) ...[
                  if (!_isPlantio) ...[
                    _buildPlantioDataBlock(),
                    const SizedBox(height: 20),
                  ],

                  const OccurrenceSectionHeader(title: 'Estádio Fenológico'),
                  const SizedBox(height: 10),
                  OccurrenceEstadioDropdown(
                    selected: _estadio,
                    expanded: _estadioCardExpanded,
                    onChanged: _selectEstadio,
                    onToggleCard: () => _patchForm(
                      () => _estadioCardExpanded = !_estadioCardExpanded,
                    ),
                  ),
                  if (_buildEstadioSugeridoHint(muted) case final hint?) hint,
                  const SizedBox(height: 20),

                  ..._cats
                      .where((cat) => cat != OccurrenceCategory.areaVisitada)
                      .map((cat) => _buildCategorySection(cat)),

                  const OccurrenceSectionHeader(title: 'Urgência'),
                  const SizedBox(height: 8),
                  _buildUrgencySelector(),
                  const SizedBox(height: 20),
                ],

                OccurrenceSectionHeader(
                  title: _isAreaVisitada
                      ? 'Observações (opcional)'
                      : 'Observações Gerais',
                ), // ignore: prefer_const_constructors — title dinâmico
                const SizedBox(height: 8),
                OccurrenceDarkField(
                  controller: _descCtrl,
                  label: _isAreaVisitada ? 'Notas' : 'Descrição',
                  hint: _isAreaVisitada
                      ? 'Ex.: trecho da estrada, entrada do talhão…'
                      : 'Descreva a ocorrência…',
                  maxLines: 4,
                ),
                if (!_isAreaVisitada) ...[
                  const SizedBox(height: 16),
                  OccurrenceAudioField(
                    storedPath: _audioPath,
                    durationSec: _audioDurationSec,
                    enabled: !_isSaving,
                    onChanged: (value) {
                      _patchForm(() {
                        _audioPath = value.path;
                        _audioDurationSec = value.durationSec;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  OccurrenceOrdemAplicacaoFields(
                    acao: _ordem.acao,
                    dose: _ordem.dose,
                    quando: _ordem.quando,
                  ),
                  const SizedBox(height: 24),
                  _buildPhotoActionSection(),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, actionBarBottomPadding),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : _handleCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: v.ghostText,
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: v.ctaBackground,
                        foregroundColor: v.ctaText,
                        minimumSize: const Size(48, 44),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(v.ctaRadius),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: v.ctaText,
                              ),
                            )
                          : Text(
                              _primarySaveButtonLabel,
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
