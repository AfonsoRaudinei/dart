import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/utils/area_display_format.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/agronomic_models.dart';
import '../../domain/client.dart';
import '../providers/clients_providers.dart';
import '../providers/field_providers.dart';
import '../widgets/client_detail_sub_widgets.dart';
import '../widgets/farm_linked_field_list.dart';
import '../widgets/link_drawing_to_farm_sheet.dart';
import '../widgets/talhao_actions_sheet.dart';
import '../widgets/talhao_union_sheet.dart';
import '../widgets/client_map_display_settings.dart';
import '../widgets/talhao_map_preview.dart';

class ClientFarmWithTalhoesSection extends ConsumerWidget {
  final Client client;
  final Farm farm;

  const ClientFarmWithTalhoesSection({
    super.key,
    required this.client,
    required this.farm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(farmLinkedFieldsProvider(farm.id));
    final linkedFields = fieldsAsync.asData?.value;
    final displayedAreaHa = linkedFields == null
        ? farm.totalAreaHa
        : totalFarmLinkedAreaHa(linkedFields);
    final areaUnit = ref.watch(areaDisplayUnitProvider);
    final areaFormatted = formatAreaFromHectares(displayedAreaHa, areaUnit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          farm.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Produtor: ${client.name}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Área Total',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                areaFormatted,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${farm.city} - ${farm.state}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const ClientMapDisplaySettings(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Talhões',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => context.go(
                farmMapCreateUri(clientId: client.id, farmId: farm.id),
              ),
              icon: const Icon(Icons.add, color: PremiumTokens.brandGreen),
              label: const Text(
                'Novo',
                style: TextStyle(
                  color: PremiumTokens.brandGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        fieldsAsync.when(
          data: (fields) => FarmLinkedFieldList(
            clientId: client.id,
            farmId: farm.id,
            fields: fields,
          ),
          loading: () {
            if ((linkedFields ?? const []).isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return FarmLinkedFieldList(
              clientId: client.id,
              farmId: farm.id,
              fields: linkedFields!,
            );
          },
          error: (err, stack) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class ClientDrawingFieldsSection extends ConsumerWidget {
  final Client client;

  const ClientDrawingFieldsSection({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingFieldsAsync = ref.watch(
      clientDrawingFieldsProvider(client.id),
    );

    return drawingFieldsAsync.when(
      data: (fields) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Talhões avulsos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.add,
                    color: PremiumTokens.brandGreen,
                  ),
                  label: const Text(
                    'Talhão',
                    style: TextStyle(
                      color: PremiumTokens.brandGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => showAdicionarTalhaoModal(context, client),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (fields.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'Nenhum talhão avulso no mapa',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...fields.map((field) {
                return TalhaoMapPreviewWidget(
                  vertices: field.vertices,
                  nome: field.name,
                  areaHa: field.areaHa,
                  subtitle: 'Sem fazenda vinculada',
                  onTap: () => _openActions(context, field, fields),
                  actions: [
                    IconButton(
                      tooltip: 'Vincular à fazenda',
                      icon: const Icon(
                        Icons.link,
                        size: 20,
                        color: PremiumTokens.brandGreen,
                      ),
                      onPressed: () =>
                          _linkDrawingToFarm(context, ref, field),
                    ),
                    IconButton(
                      tooltip: 'Abrir no mapa',
                      icon: const Icon(Icons.open_in_full, size: 20),
                      onPressed: () => context.go(_mapViewUri(field)),
                    ),
                    IconButton(
                      tooltip: 'Ações do talhão',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _openActions(context, field, fields),
                    ),
                    IconButton(
                      tooltip: 'Excluir talhão',
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () =>
                          _confirmDeleteDrawing(context, ref, field),
                    ),
                  ],
                );
              }),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<TalhaoUnionCandidate> _unionCandidates(
    ClientDrawingFieldSummary field,
    List<ClientDrawingFieldSummary> allFields,
  ) {
    return allFields
        .where((candidate) => candidate.id != field.id)
        .map(
          (candidate) => TalhaoUnionCandidate(
            id: candidate.id,
            name: candidate.name,
            areaHa: candidate.areaHa,
            vertices: candidate.vertices,
          ),
        )
        .toList();
  }

  Future<void> _openActions(
    BuildContext context,
    ClientDrawingFieldSummary field,
    List<ClientDrawingFieldSummary> allFields,
  ) {
    return showTalhaoActionsSheet(
      context,
      clientId: client.id,
      farmId: field.farmId,
      fieldId: field.id,
      fieldName: field.name,
      initialCultura: field.crop,
      initialSafra: field.harvest,
      fieldAreaHa: field.areaHa,
      primaryVertices: field.vertices,
      showUnionAction: true,
      unionCandidates: _unionCandidates(field, allFields),
    );
  }

  Future<void> _linkDrawingToFarm(
    BuildContext context,
    WidgetRef ref,
    ClientDrawingFieldSummary field,
  ) async {
    final previousFarmId = field.farmId;
    final linkedFarm = await showLinkDrawingToFarmSheet(
      context,
      client: client,
      field: field,
    );
    if (linkedFarm == null || !context.mounted) return;

    ref.invalidate(clientDetailProvider(client.id));
    ref.invalidate(clientDrawingFieldsProvider(client.id));
    ref.invalidate(farmLinkedFieldsProvider(linkedFarm.id));
    if (previousFarmId != null && previousFarmId != linkedFarm.id) {
      ref.invalidate(farmLinkedFieldsProvider(previousFarmId));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Talhão vinculado à fazenda "${linkedFarm.name}".'),
      ),
    );
  }

  Future<void> _confirmDeleteDrawing(
    BuildContext context,
    WidgetRef ref,
    ClientDrawingFieldSummary field,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir talhão?'),
        content: Text('O talhão "${field.name}" será removido do mapa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref
        .read(iDrawingFieldWriterProvider)
        .deleteFieldAndRecalculateClientArea(
          fieldId: field.id,
          clientId: client.id,
        );

    ref.invalidate(clientDrawingFieldsProvider(client.id));
    if (field.farmId != null) {
      ref.invalidate(farmLinkedFieldsProvider(field.farmId!));
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Talhão excluído.')));
  }

  String _mapViewUri(ClientDrawingFieldSummary field) {
    return talhaoMapUri(
      modo: 'desenho',
      clientId: client.id,
      farmId: field.farmId,
      drawingId: field.id,
    );
  }
}
