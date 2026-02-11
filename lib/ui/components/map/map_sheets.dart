import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../../../core/domain/map_models.dart';
import '../../../core/domain/publicacao.dart';
import '../../../core/state/map_state.dart';

class BaseMapSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const BaseMapSheet({required this.title, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoloForteColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(SoloRadius.lg),
          topRight: Radius.circular(SoloRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SoloForteColors.grayLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: SoloTextStyles.headingMedium),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: SoloForteColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SoloForteColors.borderLight),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class LayersSheet extends ConsumerWidget {
  const LayersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLayer = ref.watch(activeLayerProvider);
    final showMarkers = ref.watch(showMarkersProvider);

    return BaseMapSheet(
      title: 'Camadas',
      child: ListView(
        shrinkWrap: true,
        padding: SoloSpacing.paddingCard,
        children: [
          _LayerItem(
            label: 'Padrão',
            isSelected: currentLayer == LayerType.standard,
            icon: Icons.map,
            onTap: () => ref
                .read(activeLayerProvider.notifier)
                .setLayer(LayerType.standard),
          ),
          _LayerItem(
            label: 'Satélite',
            isSelected: currentLayer == LayerType.satellite,
            icon: Icons.satellite_alt,
            onTap: () => ref
                .read(activeLayerProvider.notifier)
                .setLayer(LayerType.satellite),
          ),
          _LayerItem(
            label: 'Relevo',
            isSelected: currentLayer == LayerType.terrain,
            icon: Icons.lock_outline,
            isDisabled: true,
            onTap: null,
          ),
          const SizedBox(height: 20),
          const Text('Sobreposições', style: SoloTextStyles.label),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Mostrar Pinos', style: SoloTextStyles.body),
            value: showMarkers,
            activeTrackColor: SoloForteColors.greenIOS,
            onChanged: (v) => ref.read(showMarkersProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }
}

class _LayerItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final IconData icon;
  final VoidCallback? onTap;

  const _LayerItem({
    required this.label,
    required this.isSelected,
    required this.icon,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? SoloForteColors.bgSuccess : Colors.white,
          border: Border.all(
            color: isSelected
                ? SoloForteColors.greenIOS
                : (isDisabled ? Colors.transparent : SoloForteColors.border),
          ),
          borderRadius: SoloRadius.radiusMd,
        ),
        child: ListTile(
          enabled: !isDisabled,
          leading: Icon(
            icon,
            color: isSelected
                ? SoloForteColors.greenIOS
                : (isDisabled
                      ? SoloForteColors.textTertiary
                      : SoloForteColors.textSecondary),
          ),
          title: Text(
            label,
            style: isSelected
                ? SoloTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SoloForteColors.textSuccess,
                  )
                : (isDisabled
                      ? SoloTextStyles.body.copyWith(
                          color: SoloForteColors.textTertiary,
                        )
                      : SoloTextStyles.body),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: SoloForteColors.greenIOS)
              : null,
        ),
      ),
    );
  }
}

class OccurrencesSheet extends ConsumerWidget {
  const OccurrencesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrencesAsync = ref.watch(occurrencesListProvider);

    return BaseMapSheet(
      title: 'Ocorrências',
      child: Stack(
        children: [
          occurrencesAsync.when(
            data: (occurrences) {
              if (occurrences.isEmpty) {
                return const Center(
                  child: Text('Nenhuma ocorrência registrada.'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                itemCount: occurrences.length,
                itemBuilder: (context, index) {
                  final occurrence = occurrences[index];
                  // Determine color based on type
                  Color color;
                  switch (occurrence.type) {
                    case 'Urgente':
                      color = SoloForteColors.error;
                      break;
                    case 'Aviso':
                      color = Colors.orange;
                      break;
                    default:
                      color = SoloForteColors.brand;
                  }

                  return _OccurrenceItem(
                    title: occurrence.type,
                    description: occurrence.description,
                    time: _formatDate(occurrence.createdAt),
                    type: occurrence.visitSessionId != null
                        ? 'Em Visita'
                        : 'Avulso',
                    color: color,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Erro: $e')),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: SoloForteColors.greenIOS,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddOccurrenceDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours} horas';
    return '${date.day}/${date.month}';
  }

  void _showAddOccurrenceDialog(BuildContext context, WidgetRef ref) {
    final descriptionController = TextEditingController();
    String selectedType = 'Aviso';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Ocorrência'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: [
                'Urgente',
                'Aviso',
                'Info',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => selectedType = v!,
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SoloForteColors.greenIOS,
            ),
            onPressed: () {
              ref
                  .read(occurrenceControllerProvider)
                  .createOccurrence(
                    type: selectedType,
                    description: descriptionController.text,
                    lat:
                        0, // Mock lat/long for now or get from provider if needed
                    long: 0,
                  );
              Navigator.pop(context);
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceItem extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final String type;
  final Color color;

  const _OccurrenceItem({
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: SoloForteColors.grayLight,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.warning_amber_rounded, color: color),
        ),
        title: Text(
          title,
          style: SoloTextStyles.headingMedium.copyWith(fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: SoloTextStyles.body),
            const SizedBox(height: 4),
            Text(time, style: SoloTextStyles.label),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            type,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet de listagem de Publicações — migrado para Publicacao canônica (ADR-007).
class PublicacoesSheet extends ConsumerWidget {
  const PublicacoesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubsAsync = ref.watch(publicacoesDataProvider);

    return BaseMapSheet(
      title: 'Publicações',
      child: pubsAsync.when(
        data: (pubs) => ListView.separated(
          shrinkWrap: true,
          padding: SoloSpacing.paddingCard,
          itemCount: pubs.length,
          separatorBuilder: (_, __) => const Divider(height: 30),
          itemBuilder: (ctx, index) {
            final pub = pubs[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _typeColor(pub.type).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _typeIcon(pub.type),
                        size: 16,
                        color: _typeColor(pub.type),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pub.title ?? 'Sem título',
                            style: SoloTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (pub.clientName != null)
                            Text(pub.clientName!, style: SoloTextStyles.label),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  pub.description ?? '',
                  style: SoloTextStyles.body.copyWith(
                    color: SoloForteColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                // Cover image or placeholder
                Builder(builder: (context) {
                  final cover = pub.coverMedia;
                  if (cover.path.isNotEmpty) {
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: SoloForteColors.grayLight,
                        borderRadius: SoloRadius.radiusMd,
                        image: DecorationImage(
                          image: AssetImage(cover.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: SoloForteColors.grayLight,
                      borderRadius: SoloRadius.radiusMd,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image,
                        color: SoloForteColors.textTertiary,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: SoloForteColors.greenIOS),
        ),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Color _typeColor(PublicacaoType type) {
    switch (type) {
      case PublicacaoType.institucional:
        return SoloForteColors.brand;
      case PublicacaoType.tecnico:
        return Colors.blue;
      case PublicacaoType.resultado:
        return SoloForteColors.greenIOS;
      case PublicacaoType.comparativo:
        return Colors.orange;
      case PublicacaoType.caseSucesso:
        return Colors.purple;
    }
  }

  IconData _typeIcon(PublicacaoType type) {
    switch (type) {
      case PublicacaoType.institucional:
        return Icons.business;
      case PublicacaoType.tecnico:
        return Icons.science;
      case PublicacaoType.resultado:
        return Icons.bar_chart;
      case PublicacaoType.comparativo:
        return Icons.compare_arrows;
      case PublicacaoType.caseSucesso:
        return Icons.star;
    }
  }
}

/// Legacy alias — mantido para backward-compatibility.
@Deprecated('Use PublicacoesSheet instead — ADR-007')
typedef PublicationsSheet = PublicacoesSheet;
