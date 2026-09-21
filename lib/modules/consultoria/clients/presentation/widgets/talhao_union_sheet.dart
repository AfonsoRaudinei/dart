import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_widgets.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_sheet_widgets.dart';

class TalhaoUnionCandidate {
  const TalhaoUnionCandidate({
    required this.id,
    required this.name,
    required this.areaHa,
    this.vertices = const [],
  });

  final String id;
  final String name;
  final double areaHa;
  final List<LatLng> vertices;
}

Future<bool> showTalhaoUnionSheet(
  BuildContext context, {
  required String clientId,
  String? farmId,
  required String primaryFieldId,
  required String primaryFieldName,
  required double primaryAreaHa,
  List<LatLng> primaryVertices = const [],
  required List<TalhaoUnionCandidate> candidates,
}) async {
  if (candidates.isEmpty) return false;

  final saved = await showSoloForteSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.none,
    builder: (_) => TalhaoUnionSheet(
      clientId: clientId,
      farmId: farmId,
      primaryFieldId: primaryFieldId,
      primaryFieldName: primaryFieldName,
      primaryAreaHa: primaryAreaHa,
      primaryVertices: primaryVertices,
      candidates: candidates,
    ),
  );

  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Talhões combinados com sucesso.')),
    );
  }

  return saved == true;
}

class TalhaoUnionSheet extends ConsumerStatefulWidget {
  const TalhaoUnionSheet({
    super.key,
    required this.clientId,
    this.farmId,
    required this.primaryFieldId,
    required this.primaryFieldName,
    required this.primaryAreaHa,
    this.primaryVertices = const [],
    required this.candidates,
  });

  final String clientId;
  final String? farmId;
  final String primaryFieldId;
  final String primaryFieldName;
  final double primaryAreaHa;
  final List<LatLng> primaryVertices;
  final List<TalhaoUnionCandidate> candidates;

  @override
  ConsumerState<TalhaoUnionSheet> createState() => _TalhaoUnionSheetState();
}

class _TalhaoUnionSheetState extends ConsumerState<TalhaoUnionSheet> {
  String? _selectedFieldId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.candidates.length == 1) {
      _selectedFieldId = widget.candidates.first.id;
    }
  }

  Future<void> _submit() async {
    final secondaryFieldId = _selectedFieldId;
    if (_isSaving || secondaryFieldId == null) return;

    setState(() => _isSaving = true);
    try {
      final writer = ref.read(iDrawingFieldWriterProvider);
      await writer.unionDrawingFields(
        primaryFieldId: widget.primaryFieldId,
        secondaryFieldId: secondaryFieldId,
        clientId: widget.clientId,
      );

      ref.invalidate(clientDetailProvider(widget.clientId));
      ref.invalidate(clientDrawingFieldsProvider(widget.clientId));
      if (widget.farmId != null && widget.farmId!.isNotEmpty) {
        ref.invalidate(farmLinkedFieldsProvider(widget.farmId!));
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(e, action: 'Não foi possível combinar os talhões'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);

    return ClientSheetScaffold(
      title: 'União',
      subtitle: 'Combinar com outra área',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TalhaoSheetPrimaryChip(
            name: widget.primaryFieldName,
            areaHa: widget.primaryAreaHa,
            vertices: widget.primaryVertices,
          ),
          const SizedBox(height: 16),
          const TalhaoSheetSectionLabel(label: 'Escolha a segunda área'),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: visuals.cardBg,
              borderRadius: BorderRadius.circular(visuals.cardRadius),
              border: Border.all(color: visuals.cardBorder),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.candidates.length,
                itemBuilder: (context, index) {
                  final candidate = widget.candidates[index];
                  return TalhaoUnionCandidateRow(
                    name: candidate.name,
                    areaHa: candidate.areaHa,
                    vertices: candidate.vertices,
                    selected: _selectedFieldId == candidate.id,
                    onTap: () => setState(() => _selectedFieldId = candidate.id),
                    showDivider: index < widget.candidates.length - 1,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A segunda área será removida após a união.',
            style: TextStyle(fontSize: 12, color: visuals.muted),
          ),
          const SizedBox(height: 20),
          TalhaoSheetButtonRow(
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () {
              HapticFeedback.mediumImpact();
              _submit();
            },
            confirmLabel: 'Confirmar união',
            isSaving: _isSaving,
            confirmEnabled: _selectedFieldId != null,
          ),
        ],
      ),
    );
  }
}
