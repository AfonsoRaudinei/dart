import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';

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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Adicionar Talhão: Em breve'),
                                  ),
                                );
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
                              children: fields
                                  .map(
                                    (field) => Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                        tileColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey[200]!,
                                          ),
                                        ),
                                        title: Text(
                                          field.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(_fieldSubtitle(field)),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey,
                                        ),
                                        onTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Talhão: ${field.name}',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
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
}
