import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        borderRadius: BorderRadius.only(
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
                    SFIcons.close,
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
            icon: SFIcons.map,
            onTap: () => ref
                .read(activeLayerProvider.notifier)
                .setLayer(LayerType.standard),
          ),
          _LayerItem(
            label: 'Satélite',
            isSelected: currentLayer == LayerType.satellite,
            icon: SFIcons.satellite,
            onTap: () => ref
                .read(activeLayerProvider.notifier)
                .setLayer(LayerType.satellite),
          ),
          _LayerItem(
            label: 'Relevo',
            isSelected: currentLayer == LayerType.terrain,
            icon: SFIcons.lock,
            isDisabled: true,
            onTap: null,
          ),
          const SizedBox(height: 20),
          Text('Sobreposições', style: SoloTextStyles.label),
          const SizedBox(height: 10),
          SwitchListTile(
            title: Text('Mostrar Pinos', style: SoloTextStyles.body),
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
              ? const Icon(SFIcons.checkCircle, color: SoloForteColors.greenIOS)
              : null,
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
                Builder(
                  builder: (context) {
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
                          SFIcons.image,
                          color: SoloForteColors.textTertiary,
                        ),
                      ),
                    );
                  },
                ),
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
        return SFIcons.business;
      case PublicacaoType.tecnico:
        return SFIcons.science;
      case PublicacaoType.resultado:
        return SFIcons.barChart;
      case PublicacaoType.comparativo:
        return SFIcons.compareArrows;
      case PublicacaoType.caseSucesso:
        return SFIcons.star;
    }
  }
}

/// Legacy alias — mantido para backward-compatibility.
@Deprecated('Use PublicacoesSheet instead — ADR-007')
typedef PublicationsSheet = PublicacoesSheet;
