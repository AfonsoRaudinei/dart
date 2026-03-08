import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/premium/design_tokens.dart';
import '../../../core/domain/map_models.dart';
import '../../../core/domain/publicacao.dart';
import '../../../core/state/map_state.dart';

class BaseMapSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback?
  onClose; // 🔧 FIX: Callback externo (não usar Navigator.pop)

  const BaseMapSheet({
    required this.title,
    required this.child,
    this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PremiumTokens.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: PremiumTokens.premiumShadow,
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
              color: PremiumTokens.backgroundLight,
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
                  child: Text(
                    title,
                    style:
                        (Theme.of(context).textTheme.titleLarge ??
                        const TextStyle()),
                  ),
                ),
                // 🔧 FIX: Só mostrar botão X se onClose foi fornecido
                if (onClose != null)
                  TextButton(
                    onPressed: onClose,
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
          const Divider(height: 1, color: PremiumTokens.hairlineLight),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class LayersSheet extends ConsumerWidget {
  final VoidCallback? onClose; // 🔧 FIX: Callback de fechamento externo

  const LayersSheet({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLayer = ref.watch(activeLayerProvider);
    final showMarkers = ref.watch(showMarkersProvider);

    return BaseMapSheet(
      title: 'Camadas',
      onClose: onClose, // 🔧 FIX: Passar callback para BaseMapSheet
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          // Grid de Camadas com Preview Visual
          Row(
            children: [
              Expanded(
                child: _LayerCardPreview(
                  label: 'Padrão',
                  isSelected: currentLayer == LayerType.standard,
                  color: Colors.orange.shade100,
                  onTap: () => ref
                      .read(activeLayerProvider.notifier)
                      .setLayer(LayerType.standard),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LayerCardPreview(
                  label: 'Satélite',
                  isSelected: currentLayer == LayerType.satellite,
                  color: Colors.green.shade200,
                  onTap: () => ref
                      .read(activeLayerProvider.notifier)
                      .setLayer(LayerType.satellite),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LayerCardPreview(
                  label: 'Relevo',
                  isSelected: currentLayer == LayerType.relevo,
                  color: Colors.brown.shade200,
                  onTap: () => ref
                      .read(activeLayerProvider.notifier)
                      .setLayer(LayerType.relevo),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Seção de Sobreposições
          Text(
            'Sobreposições',
            style:
                (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                    .copyWith(
                      color: PremiumTokens.textSecondaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: PremiumTokens.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                'Mostrar Pinos',
                style:
                    (Theme.of(context).textTheme.bodyMedium ??
                    const TextStyle()),
              ),
              value: showMarkers,
              activeTrackColor: PremiumTokens.brandGreen,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                ref.read(showMarkersProvider.notifier).toggle();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Novo widget: Card de preview de camada
class _LayerCardPreview extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final Color color;
  final VoidCallback? onTap;

  const _LayerCardPreview({
    required this.label,
    required this.isSelected,
    required this.color,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Column(
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? PremiumTokens.brandGreen
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Center(
                    child: Icon(
                      SFIcons.checkCircle,
                      color: PremiumTokens.brandGreen,
                      size: 32,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
                .copyWith(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDisabled
                      ? PremiumTokens.textTertiaryLight
                      : PremiumTokens.textPrimaryLight,
                ),
          ),
        ],
      ),
    );
  }
}

/// 📄 Sheet de Publicações — Reconstruído conforme design_soloforte.md
/// ADR-007: Entidade canônica do mapa
class PublicacoesSheet extends ConsumerWidget {
  final VoidCallback? onClose;

  const PublicacoesSheet({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubsAsync = ref.watch(publicacoesDataProvider);

    return BaseMapSheet(
      title: 'Publicações',
      onClose: onClose,
      child: pubsAsync.when(
        data: (pubs) {
          if (pubs.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16), // Grid 16
            itemCount: pubs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16), // Grid 16
            itemBuilder: (ctx, index) => _PublicacaoCard(pub: pubs[index]),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(
              color: PremiumTokens.brandGreen,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  SFIcons.warningOutlined,
                  size: 48,
                  color: PremiumTokens.alertError,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar publicações',
                  style:
                      (Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle())
                          .copyWith(color: PremiumTokens.alertError),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              SFIcons.article,
              size: 64,
              color: PremiumTokens.textTertiaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma publicação',
              style:
                  (Theme.of(context).textTheme.titleLarge ?? const TextStyle())
                      .copyWith(color: PremiumTokens.textSecondaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              'As publicações aparecerão aqui',
              style:
                  (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                      .copyWith(color: PremiumTokens.textTertiaryLight),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card individual de publicação
/// Segue design_soloforte: consistência, hierarquia, clareza
class _PublicacaoCard extends StatelessWidget {
  final Publicacao pub;

  const _PublicacaoCard({required this.pub});

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo(pub.type);

    return Container(
      decoration: BoxDecoration(
        color: PremiumTokens.surfaceLight,
        borderRadius: BorderRadius.circular(16), // Radius padrão
        border: Border.all(color: PremiumTokens.hairlineLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ Imagem de capa
          _buildCoverImage(),

          // 📝 Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de tipo
                _buildTypeBadge(context, typeInfo),
                const SizedBox(height: 8),

                // Título
                if (pub.title != null && pub.title!.isNotEmpty)
                  Text(
                    pub.title!,
                    style:
                        (Theme.of(context).textTheme.titleLarge ??
                                const TextStyle())
                            .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Descrição
                if (pub.description != null && pub.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    pub.description!,
                    style:
                        (Theme.of(context).textTheme.bodyMedium ??
                                const TextStyle())
                            .copyWith(
                              fontSize: 14,
                              color: PremiumTokens.textSecondaryLight,
                            ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Metadados (Cliente, Área)
                if (pub.clientName != null || pub.areaName != null) ...[
                  const SizedBox(height: 12),
                  _buildMetadata(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    final cover = pub.coverMedia;

    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: PremiumTokens.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: cover.path.isNotEmpty
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.asset(
                cover.path,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        SFIcons.image,
        size: 48,
        color: PremiumTokens.textTertiaryLight.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, _TypeInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99), // Pill
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 12, color: info.color),
          const SizedBox(width: 4),
          Text(
            info.label,
            style:
                (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                    .copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: info.color,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Row(
      children: [
        if (pub.clientName != null) ...[
          const Icon(
            SFIcons.person,
            size: 14,
            color: PremiumTokens.textTertiaryLight,
          ),
          const SizedBox(width: 4),
          Text(
            pub.clientName!,
            style:
                (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                    .copyWith(
                      fontSize: 12,
                      color: PremiumTokens.textSecondaryLight,
                    ),
          ),
        ],
        if (pub.clientName != null && pub.areaName != null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '•',
              style: TextStyle(color: PremiumTokens.textTertiaryLight),
            ),
          ),
        if (pub.areaName != null) ...[
          const Icon(
            SFIcons.locationOn,
            size: 14,
            color: PremiumTokens.textTertiaryLight,
          ),
          const SizedBox(width: 4),
          Text(
            pub.areaName!,
            style:
                (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                    .copyWith(
                      fontSize: 12,
                      color: PremiumTokens.textSecondaryLight,
                    ),
          ),
        ],
      ],
    );
  }

  _TypeInfo _getTypeInfo(PublicacaoType type) {
    switch (type) {
      case PublicacaoType.institucional:
        return const _TypeInfo(
          label: 'Institucional',
          icon: SFIcons.business,
          color: PremiumTokens.brandGreen,
        );
      case PublicacaoType.tecnico:
        return const _TypeInfo(
          label: 'Técnico',
          icon: SFIcons.science,
          color: Color(0xFF3B82F6), // Blue
        );
      case PublicacaoType.resultado:
        return const _TypeInfo(
          label: 'Resultado',
          icon: SFIcons.barChart,
          color: PremiumTokens.brandGreen,
        );
      case PublicacaoType.comparativo:
        return const _TypeInfo(
          label: 'Comparativo',
          icon: SFIcons.compareArrows,
          color: Color(0xFFF59E0B), // Orange
        );
      case PublicacaoType.caseSucesso:
        return const _TypeInfo(
          label: 'Case de Sucesso',
          icon: SFIcons.star,
          color: Color(0xFFA855F7), // Purple
        );
    }
  }
}

/// Helper para informações de tipo
class _TypeInfo {
  final String label;
  final IconData icon;
  final Color color;

  const _TypeInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Legacy alias — mantido para backward-compatibility.
@Deprecated('Use PublicacoesSheet instead — ADR-007')
typedef PublicationsSheet = PublicacoesSheet;
