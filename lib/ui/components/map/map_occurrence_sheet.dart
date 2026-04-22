import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/premium/design_tokens.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../../modules/consultoria/relatorio_visita/data/draft_storage_service.dart';
import '../../../../modules/consultoria/relatorio_visita/data/image_storage_service.dart';
import 'widgets/visit_panels.dart';
import '../../../../modules/consultoria/relatorio_visita/data/visita_model.dart';
import '../../../../modules/consultoria/relatorio_visita/data/visita_database_service.dart';
import '../../../core/utils/app_logger.dart';

// ════════════════════════════════════════════════════════════════════
// MODELS AUXILIARES (ESTÁGIOS)
// ════════════════════════════════════════════════════════════════════

enum EstagioTipo { vegetativo, reprodutivo }

class EstagioSoja {
  final String codigo;
  final String nome;
  final String descricao;
  final String emoji;
  final String dapEsperado;
  final EstagioTipo tipo;
  final List<String> alertas;

  const EstagioSoja({
    required this.codigo,
    required this.nome,
    required this.descricao,
    required this.emoji,
    required this.dapEsperado,
    required this.tipo,
    required this.alertas,
  });
}

const List<EstagioSoja> estagiosSoja = [
  EstagioSoja(
    codigo: 'VE',
    nome: 'Emergência',
    descricao: 'Cotilédones acima do solo',
    emoji: '🌱',
    dapEsperado: '5–7 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Monitorar tombamento', 'Verificar estande'],
  ),
  EstagioSoja(
    codigo: 'VC',
    nome: 'Cotilédones',
    descricao: 'Cotilédones completamente abertos',
    emoji: '🌿',
    dapEsperado: '7–10 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Iniciar monitoramento de pragas', 'Verificar nodulação'],
  ),
  EstagioSoja(
    codigo: 'V1',
    nome: '1ª Trifoliolada',
    descricao: 'Primeiro nó com folha trifoliolada',
    emoji: '🍃',
    dapEsperado: '10–14 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Monitoramento de percevejos', 'Deficiência de ferro'],
  ),
  EstagioSoja(
    codigo: 'V2',
    nome: '2ª Trifoliolada',
    descricao: 'Segundo nó com folha trifoliolada',
    emoji: '🍃',
    dapEsperado: '14–20 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Monitorar lagarta-da-soja', 'Herbicida pós-emergente'],
  ),
  EstagioSoja(
    codigo: 'V3',
    nome: '3ª Trifoliolada',
    descricao: 'Terceiro nó com folha trifoliolada',
    emoji: '🍃',
    dapEsperado: '20–28 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Monitorar oídio', 'Deficiência de manganês'],
  ),
  EstagioSoja(
    codigo: 'V4',
    nome: '4ª Trifoliolada',
    descricao: 'Quarto nó com folha trifoliolada',
    emoji: '🌳',
    dapEsperado: '28–35 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Tripes e mosca-branca', 'Herbicida antes de V5'],
  ),
  EstagioSoja(
    codigo: 'Rn',
    nome: 'Início do Florescimento',
    descricao: 'Uma flor aberta em qualquer nó',
    emoji: '🌸',
    dapEsperado: '45–55 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: [
      'Pico de demanda hídrica',
      'Ferrugem asiática',
      'Percevejo-marrom',
    ],
  ),
  EstagioSoja(
    codigo: 'R2',
    nome: 'Floração Plena',
    descricao: 'Flor aberta nos nós superiores',
    emoji: '🌺',
    dapEsperado: '50–60 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Mancha alvo e antracnose', 'Cuidado com abelhas'],
  ),
  EstagioSoja(
    codigo: 'R3',
    nome: 'Vagens com 1 cm',
    descricao: 'Vagem com 1 cm nos 4 nós superiores',
    emoji: '🫛',
    dapEsperado: '55–65 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Percevejo reduz enchimento', 'Lagarta-da-soja'],
  ),
  EstagioSoja(
    codigo: 'R4',
    nome: 'Vagens com 2 cm',
    descricao: 'Vagem com 2 cm nos 4 nós superiores',
    emoji: '🫛',
    dapEsperado: '60–70 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Monitorar percevejo com rigor', 'Inseticida se > 2/pano'],
  ),
  EstagioSoja(
    codigo: 'R5',
    nome: 'Enchimento de Grãos',
    descricao: 'Grão perceptível ao tato',
    emoji: '🌾',
    dapEsperado: '65–80 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Máxima demanda hídrica', 'Dano irreversível de percevejo'],
  ),
  EstagioSoja(
    codigo: 'R6',
    nome: 'Grãos Formados',
    descricao: 'Grãos preenchem a cavidade',
    emoji: '🟡',
    dapEsperado: '100–110 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Deiscência precoce', 'Evitar aplicações'],
  ),
  EstagioSoja(
    codigo: 'R7',
    nome: 'Início Maturação',
    descricao: 'Vagem com cor de maturação',
    emoji: '🟠',
    dapEsperado: '110–120 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Uniformidade de maturação', 'Estimar colheita'],
  ),
  EstagioSoja(
    codigo: 'R8',
    nome: 'Maturação Plena',
    descricao: '95% das vagens maduras',
    emoji: '🟤',
    dapEsperado: '120–135 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Ponto de colheita', 'Umidade ideal 14%'],
  ),
];

// ════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ════════════════════════════════════════════════════════════════════

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: PremiumTokens.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: PremiumTokens.tightShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: PremiumTokens.textSecondaryLight,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class FormFieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const FormFieldRow({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: PremiumTokens.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class DapBadge extends StatelessWidget {
  final int dap;

  const DapBadge({super.key, required this.dap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dap > 0
            ? PremiumTokens.brandGreen.withValues(alpha: 0.1)
            : PremiumTokens.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dap > 0
              ? PremiumTokens.brandGreen.withValues(alpha: 0.3)
              : PremiumTokens.hairlineLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'DAP: ',
            style: TextStyle(
              fontSize: 12,
              color: PremiumTokens.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$dap dias',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: dap > 0
                  ? PremiumTokens.brandGreen
                  : PremiumTokens.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class StageSelector extends StatelessWidget {
  final String? selectedStageCode;
  final ValueChanged<String?> onChanged;

  const StageSelector({
    super.key,
    required this.selectedStageCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(selectedStageCode),
      isExpanded: true,
      initialValue: selectedStageCode,
      decoration: InputDecoration(
        filled: true,
        fillColor: PremiumTokens.backgroundLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: const Text(
        'Selecione o estádio',
        style: TextStyle(color: PremiumTokens.textTertiaryLight),
      ),
      items: estagiosSoja.map((stage) {
        return DropdownMenuItem(
          value: stage.codigo,
          child: Row(
            children: [
              Text(stage.emoji),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${stage.codigo} - ${stage.nome}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final List<String> selectedCategories;
  final ValueChanged<String> onToggle;
  final Map<String, int> photoCounts;

  const CategoryGrid({
    super.key,
    required this.selectedCategories,
    required this.onToggle,
    this.photoCounts = const {},
  });

  static const categories = [
    {'id': 'doenca', 'label': 'Doenças', 'icon': SFIcons.warning},
    {'id': 'insetos', 'label': 'Pragas', 'icon': SFIcons.bugReport},
    {'id': 'ervas', 'label': 'Daninhas', 'icon': SFIcons.grass},
    {'id': 'nutrientes', 'label': 'Nutrição', 'icon': SFIcons.science},
    {'id': 'fisiologico', 'label': 'Fisiológico', 'icon': SFIcons.waterDrop},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((cat) {
        final id = cat['id'] as String;
        final isSelected = selectedCategories.contains(id);
        final count = photoCounts[id] ?? 0;
        return GestureDetector(
          onTap: () => onToggle(id),
          child: Container(
            width:
                (MediaQuery.of(context).size.width - 80) / 3, // 3 cols approx
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? PremiumTokens.brandGreen : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? PremiumTokens.brandGreen
                    : PremiumTokens.hairlineLight,
              ),
              boxShadow: [
                if (!isSelected)
                  const BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  cat['icon'] as IconData,
                  color: isSelected
                      ? Colors.white
                      : PremiumTokens.textPrimaryLight,
                ),
                const SizedBox(height: 8),
                Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : PremiumTokens.textPrimaryLight,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : PremiumTokens.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count 📷',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : PremiumTokens.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ════════════════════════════════════════════════════════════════════

class MapOccurrenceSheet extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;
  final Function(String category, String urgency, String description) onConfirm;
  final VoidCallback? onCancel;
  final ScrollController? scrollController;

  /// Opcional: ID do cliente vindo do Hub (WS-6 / ADR-016).
  /// Quando presente, `produtor` é auto-preenchido com [clienteNome].
  final String? clienteId;
  final String? clienteNome;

  const MapOccurrenceSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onConfirm,
    this.onCancel,
    this.scrollController,
    this.clienteId,
    this.clienteNome,
  });

  @override
  ConsumerState<MapOccurrenceSheet> createState() => _MapOccurrenceSheetState();
}

class _MapOccurrenceSheetState extends ConsumerState<MapOccurrenceSheet> {
  late VisitaModel _draft;
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _areaController = TextEditingController();
  final _cultivarController = TextEditingController();
  final _obsController = TextEditingController();
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    // Initialize temporary draft to avoid UI errors before load
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['full_name'] as String? ?? '';
    _draft = VisitaModel(
      dataVisita: DateTime.now(),
      latitude: widget.latitude,
      longitude: widget.longitude,
      // Se vier do Hub do Cliente, auto-preenche produtor (WS-6)
      produtor: widget.clienteNome ?? '',
      propriedade: '',
      tecnico: userName,
      clienteId: widget.clienteId,
    );

    _loadDraft();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _cultivarController.dispose();
    _obsController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final draftService = ref.read(draftStorageServiceProvider);
    final savedDraft = await draftService.loadDraft();
    if (savedDraft != null) {
      // Check if coordinates match (approximate check for "same location")
      const double tolerance = 0.0001; // ~11 meters
      if ((savedDraft.latitude - widget.latitude).abs() < tolerance &&
          (savedDraft.longitude - widget.longitude).abs() < tolerance) {
        setState(() {
          _draft = savedDraft;
          // Restore TextControllers
          if (_draft.area != null) {
            _areaController.text = _draft.area.toString();
          }
          if (_draft.cultivar != null) {
            _cultivarController.text = _draft.cultivar!;
          }
          _obsController.text = _draft.observacoes;
        });
        AppLogger.debug(
          'Draft restaurado para o local.',
          tag: 'OccurrenceSheet',
        );
      } else {
        AppLogger.debug(
          'Local diferente. Iniciando novo relatório.',
          tag: 'OccurrenceSheet',
        );
      }
    }
  }

  void _scheduleAutoSave() {
    if (_autoSaveTimer?.isActive ?? false) _autoSaveTimer!.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 400), () {
      final draftService = ref.read(draftStorageServiceProvider);
      draftService.saveDraft(_draft);
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.dataPlantio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _draft.dataPlantio = picked;
        _scheduleAutoSave();
      });
    }
  }

  void _submit() async {
    // Garantir que clienteId vindo do widget está no draft
    if (widget.clienteId != null && _draft.clienteId == null) {
      _draft = _draft.copyWith(clienteId: widget.clienteId);
    }
    // Injetar userId para isolamento offline (FIX-C1B)
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (_draft.userId.isEmpty) {
      _draft = _draft.copyWith(userId: userId);
    }
    // 1. Save to SQLite
    await VisitaDatabaseService.instance.save(_draft);

    // 2. Clear Local Draft
    final draftService = ref.read(draftStorageServiceProvider);
    await draftService.clearDraft();
    _autoSaveTimer?.cancel();

    AppLogger.debug(
      'VISITA TÉCNICA SALVA COM SUCESSO: ${_draft.id}',
      tag: 'OccurrenceSheet',
    );

    if (!mounted) return;

    // 3. Confirm to Parent
    widget.onConfirm(
      _draft.categorias.isNotEmpty ? _draft.categorias.first : 'Geral',
      'Média',
      'RELATÓRIO DE VISITA: ${_draft.observacoes}',
    );
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar Visita?'),
        content: const Text(
          'As alterações não salvas serão perdidas. O rascunho será excluído.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Voltar',
              style: TextStyle(color: PremiumTokens.textSecondaryLight),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final draftService = ref.read(draftStorageServiceProvider);
              draftService.clearDraft();
              widget.onCancel?.call();
            },
            child: const Text(
              'Descartar',
              style: TextStyle(color: PremiumTokens.alertError),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePhotoAdd(String category) async {
    final path = await ImageStorageService().captureAndSaveImage();
    if (path != null) {
      setState(() {
        if (_draft.fotos[category] == null) {
          _draft.fotos[category] = [];
        }
        _draft.fotos[category]!.add(path);
        _scheduleAutoSave();
      });
    }
  }

  void _handlePhotoRemove(String category, String path) async {
    // Optimistic UI update
    setState(() {
      _draft.fotos[category]?.remove(path);
      _scheduleAutoSave();
    });
    // Async physical delete
    await ImageStorageService().deleteImage(path);
  }

  // Helper to extract counts for grid
  Map<String, int> get _photoCounts {
    return _draft.fotos.map((key, value) => MapEntry(key, value.length));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PremiumTokens.backgroundLight, // Background scaffold color
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: PremiumTokens.hairlineLight,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Relatório de Visita',
                  style:
                      (Theme.of(context).textTheme.titleLarge ??
                              const TextStyle())
                          .copyWith(fontSize: 20),
                ),
                TextButton(
                  onPressed: _handleCancel,
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
          ),

          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // SECTION 1: INFORMAÇÕES DA VISITA
                SectionCard(
                  title: 'Informações da Visita',
                  children: [
                    // Produtor/Propriedade (Read-only Mocks)
                    Row(
                      children: [
                        Expanded(
                          child: FormFieldRow(
                            label: 'Produtor',
                            child: Text(
                              _draft.produtor,
                              style:
                                  (Theme.of(context).textTheme.bodyMedium ??
                                          const TextStyle())
                                      .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: FormFieldRow(
                            label: 'Propriedade',
                            child: Text(
                              _draft.propriedade,
                              style:
                                  (Theme.of(context).textTheme.bodyMedium ??
                                          const TextStyle())
                                      .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Data Visita & Área
                    Row(
                      children: [
                        Expanded(
                          child: FormFieldRow(
                            label: 'Data da Visita',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: PremiumTokens.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _dateFormat.format(_draft.dataVisita),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormFieldRow(
                            label: 'Área (ha)',
                            child: TextFormField(
                              controller: _areaController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(7),
                              ],
                              decoration: InputDecoration(
                                hintText: '0',
                                filled: true,
                                fillColor: PremiumTokens.backgroundLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (v) {
                                _draft.area = double.tryParse(v);
                                _scheduleAutoSave();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Cultivar & Plantio
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 3,
                          child: FormFieldRow(
                            label: 'Cultivar',
                            child: TextFormField(
                              controller: _cultivarController,
                              decoration: InputDecoration(
                                hintText: 'Ex: Garra 63i64',
                                filled: true,
                                fillColor: PremiumTokens.backgroundLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (v) {
                                _draft.cultivar = v;
                                _scheduleAutoSave();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FormFieldRow(
                            label: 'Data Plantio',
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: PremiumTokens.backgroundLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _draft.dataPlantio == null
                                        ? PremiumTokens.hairlineLight
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  _draft.dataPlantio == null
                                      ? 'Selecionar'
                                      : _dateFormat.format(_draft.dataPlantio!),
                                  style: TextStyle(
                                    color: _draft.dataPlantio == null
                                        ? PremiumTokens.textTertiaryLight
                                        : PremiumTokens.textPrimaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // DAP (Calculated)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [DapBadge(dap: _draft.dap)],
                      ),
                    ),
                  ],
                ),

                // SECTION 2: ESTÁDIO FENOLÓGICO
                SectionCard(
                  title: 'Estádio Fenológico',
                  children: [
                    StageSelector(
                      selectedStageCode: _draft.estagioCodigo,
                      onChanged: (val) {
                        setState(() {
                          _draft.estagioCodigo = val;
                          _scheduleAutoSave();
                        });
                      },
                    ),
                    if (_draft.estagioCodigo != null) ...[
                      const SizedBox(height: 16),
                      ...estagiosSoja
                          .firstWhere((e) => e.codigo == _draft.estagioCodigo)
                          .alertas
                          .map(
                            (alerta) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: PremiumTokens.alertWarning,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      alerta,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: PremiumTokens.textSecondaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ],
                ),

                // SECTION 3: CATEGORIAS
                SectionCard(
                  title: 'Categorias (Problemas Identificados)',
                  children: [
                    CategoryGrid(
                      selectedCategories: _draft.categorias,
                      photoCounts: _photoCounts,
                      onToggle: (id) {
                        setState(() {
                          if (_draft.categorias.contains(id)) {
                            _draft.categorias.remove(id);
                            // Opcional: _draft.detalhes.remove(id);
                          } else {
                            _draft.categorias.add(id);
                            if (!_draft.detalhes.containsKey(id)) {
                              _draft.detalhes[id] = {};
                            }
                          }
                          _scheduleAutoSave();
                        });
                      },
                    ),
                    // Painéis de Detalhe Dinâmicos
                    if (_draft.categorias.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      ..._draft.categorias.map((catId) {
                        return CategoryDetailPanel(
                          categoryId: catId,
                          data: _draft.detalhes[catId] ?? {},
                          photos: _draft.fotos[catId] ?? [],
                          onAddPhoto: () => _handlePhotoAdd(catId),
                          onRemovePhoto: (path) =>
                              _handlePhotoRemove(catId, path),
                          onRemove: () {
                            setState(() {
                              _draft.categorias.remove(catId);
                              _scheduleAutoSave();
                            });
                          },
                          onUpdate: (newData) {
                            setState(() {
                              _draft.detalhes[catId] = newData;
                              _scheduleAutoSave();
                            });
                          },
                        );
                      }),
                    ],
                  ],
                ),

                // SECTION 4: OBSERVAÇÕES
                SectionCard(
                  title: 'Observações Gerais',
                  children: [
                    TextFormField(
                      controller: _obsController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            'Descreva o cenário encontrado, recomendações e observações relevantes...',
                        filled: true,
                        fillColor: PremiumTokens.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        _draft.observacoes = v;
                        _scheduleAutoSave();
                      },
                    ),
                  ],
                ),

                // SECTION 5 & 6: META INFO
                SectionCard(
                  title: 'Metadados',
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: PremiumTokens.textTertiaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Responsável: ${_draft.tecnico}',
                          style: const TextStyle(
                            color: PremiumTokens.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: PremiumTokens.textTertiaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Coords: ${_draft.latitude.toStringAsFixed(6)}, ${_draft.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: PremiumTokens.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Botão Confirmar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTokens.brandGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Gerar Relatório de Visita',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
