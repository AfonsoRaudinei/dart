import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/utils/area_display_format.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/talhao_card_ndvi_provider.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_map_display_settings.dart';
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
    final clientAsync = ref.watch(clientDetailProvider(clientId));
    final linkedFieldsAsync = ref.watch(farmLinkedFieldsProvider(farmId));
    final areaUnit = ref.watch(areaDisplayUnitProvider);
    final showNdvi = ref.watch(talhaoCardNdviEnabledProvider(farmId));

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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              farm.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            clientAsync.maybeWhen(
                              data: (client) {
                                if (client == null) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Produtor: ${client.name}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              },
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
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
                                formatAreaFromHectares(totalAreaHa, areaUnit),
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
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Text(
                              'Talhões',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TalhaoCardNdviToggle(farmId: farmId),
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
                            showNdvi: showNdvi,
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
                              showNdvi: showNdvi,
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
        error: (e, s) =>
            Center(child: Text(userFacingError(e, action: 'Erro'))),
      ),
    );
  }
}
