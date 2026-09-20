import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/farm_linked_field_list.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

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
    final farmAsync = ref.watch(farmDetailProvider(farmId));
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
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                '${formatLinkedFieldAreaHa(totalAreaHa)} ha',
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
                                context.go(
                                  farmMapCreateUri(
                                    clientId: clientId,
                                    farmId: farmId,
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
                          data: (fields) => FarmLinkedFieldList(
                            clientId: clientId,
                            farmId: farmId,
                            fields: fields,
                          ),
                          loading: () {
                            if ((linkedFieldsAsync.asData?.value ?? const [])
                                .isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return FarmLinkedFieldList(
                              clientId: clientId,
                              farmId: farmId,
                              fields: linkedFields!,
                            );
                          },
                          error: (e, s) => Center(
                            child: Text(
                              userFacingError(
                                e,
                                action: 'Erro ao carregar talhões',
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(userFacingError(e, action: 'Erro'))),
      ),
    );
  }
}
