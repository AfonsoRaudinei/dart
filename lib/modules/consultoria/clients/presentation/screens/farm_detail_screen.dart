import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_map_preview.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';

final farmDetailProvider = FutureProvider.family.autoDispose<dynamic, String>((
  ref,
  id,
) async {
  final repo = FarmRepository();
  final farm = await repo.getFarmById(id);
  return farm;
});

class FarmDetailScreen extends ConsumerWidget {
  final String clientId;
  final String farmId;

  const FarmDetailScreen({
    super.key,
    required this.clientId,
    required this.farmId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch Farm
    final farmAsync = ref.watch(farmDetailProvider(farmId));

    // 2. Fetch fields + map drawings linked to this farm.
    final linkedFieldsAsync = ref.watch(farmLinkedFieldsProvider(farmId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: farmAsync.when(
        data: (farm) {
          if (farm == null) {
            return const Center(child: Text('Fazenda não encontrada'));
          }

          final linkedFields = linkedFieldsAsync.asData?.value;
          final totalAreaHa = linkedFields == null
              ? farm.totalAreaHa
              : totalFarmLinkedAreaHa(linkedFields);

          return SafeArea(
            child: Column(
              children: [
                // Header (No AppBar)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          farm.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Card
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
                                '${_formatAreaHa(totalAreaHa)} ha',
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
                        const SizedBox(height: 32),

                        // Fields Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Talhões',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                context.go(_mapCreateUri());
                              },
                              icon: const Icon(
                                Icons.add,
                                color: PremiumTokens.brandGreen,
                              ),
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

                        linkedFieldsAsync.when(
                          data: (fields) {
                            if (fields.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: const Center(
                                  child: Text('Nenhum talhão cadastrado'),
                                ),
                              );
                            }

                            return Column(
                              children: fields.map((field) {
                                return TalhaoMapPreviewWidget(
                                  vertices: field.vertices,
                                  nome: field.name,
                                  areaHa: field.areaHa,
                                  subtitle: _fieldSubtitle(field),
                                  onTap: () => _openField(context, field),
                                  actions: _fieldActions(context, ref, field),
                                );
                              }).toList(),
                            );
                          },
                          loading: () {
                            if ((linkedFieldsAsync.asData?.value ?? const [])
                                .isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          error: (e, s) => Center(
                            child: Text('Erro ao carregar talhões: $e'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  String _fieldSubtitle(FarmLinkedFieldSummary field) {
    final parts = <String>['${_formatAreaHa(field.areaHa)} ha'];

    if (field.isDrawing) {
      parts.add('Talhão do mapa');
    }

    if (field.crop != null && field.crop!.trim().isNotEmpty) {
      parts.add(field.crop!.trim());
    }

    return parts.join(' • ');
  }

  String _formatAreaHa(double areaHa) {
    return areaHa.toStringAsFixed(areaHa >= 100 ? 1 : 2);
  }

  List<Widget> _fieldActions(
    BuildContext context,
    WidgetRef ref,
    FarmLinkedFieldSummary field,
  ) {
    final actions = <Widget>[
      IconButton(
        tooltip: 'Abrir no mapa',
        icon: const Icon(Icons.open_in_full, size: 20),
        onPressed: () => _openField(context, field),
      ),
    ];

    if (field.isDrawing) {
      actions.addAll([
        IconButton(
          tooltip: 'Editar no mapa',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => context.go(_mapEditUri(field.id)),
        ),
        IconButton(
          tooltip: 'Excluir talhão',
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          onPressed: () => _confirmDeleteDrawing(context, ref, field),
        ),
      ]);
    }

    return actions;
  }

  void _openField(BuildContext context, FarmLinkedFieldSummary field) {
    if (field.isDrawing) {
      context.go(_mapViewUri(field.id));
      return;
    }

    context.go(AppRoutes.fieldDetail(clientId, farmId, field.id));
  }

  Future<void> _confirmDeleteDrawing(
    BuildContext context,
    WidgetRef ref,
    FarmLinkedFieldSummary field,
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

    final repository = ref.read(drawingRepositoryProvider);
    await repository.deleteFeature(field.id);
    final totalAreaHa = await repository.getTotalAreaByClienteId(clientId);
    await repository.updateClientAreaTotal(clientId, totalAreaHa);

    ref.invalidate(farmLinkedFieldsProvider(farmId));
    ref.invalidate(clientDrawingFieldsProvider(clientId));

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Talhão excluído.')));
  }

  String _mapCreateUri() {
    return Uri(
      path: AppRoutes.map,
      queryParameters: {
        'modo': 'desenho',
        'clienteId': clientId,
        'fazendaId': farmId,
      },
    ).toString();
  }

  String _mapViewUri(String drawingId) {
    return Uri(
      path: AppRoutes.map,
      queryParameters: {
        'modo': 'desenho',
        'clienteId': clientId,
        'fazendaId': farmId,
        'drawingId': drawingId,
      },
    ).toString();
  }

  String _mapEditUri(String drawingId) {
    return Uri(
      path: AppRoutes.map,
      queryParameters: {
        'modo': 'editar',
        'clienteId': clientId,
        'fazendaId': farmId,
        'drawingId': drawingId,
      },
    ).toString();
  }
}
