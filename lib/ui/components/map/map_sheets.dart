import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/map_config.dart';
import '../../theme/premium/design_tokens.dart';
import '../../../core/constants/layout_constants.dart';
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
  static const _sheetBg = Color(0xFF1C1C1E);
  static const _surface = Color(0xFF2C2C2E);
  static const _border = Color(0xFF3A3A3C);
  static const _accent = Color(0xFF4CAF50);

  final VoidCallback? onClose; // 🔧 FIX: Callback de fechamento externo

  const LayersSheet({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLayer = ref.watch(activeLayerProvider);
    final showMarkers = ref.watch(showMarkersProvider);

    return Container(
      decoration: const BoxDecoration(
        color: _sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Camadas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      onClose ??
                      () => Navigator.of(context, rootNavigator: false).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MapPreviewTile(
                      tileUrl: MapConfig.stadiaStamenTerrain,
                      label: 'Padrão',
                      isSelected: currentLayer == LayerType.standard,
                      subdomains: null,
                      onTap: () => ref
                          .read(activeLayerProvider.notifier)
                          .setLayer(LayerType.standard),
                    ),
                    _SolidPreviewTile(
                      label: 'Satélite',
                      isSelected: currentLayer == LayerType.satellite,
                      color: const Color(0xFF2E4A3A),
                      onTap: () => ref
                          .read(activeLayerProvider.notifier)
                          .setLayer(LayerType.satellite),
                    ),
                    _SolidPreviewTile(
                      label: 'Relevo',
                      isSelected: currentLayer == LayerType.relevo,
                      color: const Color(0xFF8D6E63),
                      onTap: () => ref
                          .read(activeLayerProvider.notifier)
                          .setLayer(LayerType.relevo),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 20, bottom: 8),
                  child: Text(
                    'Sobreposições',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border, width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mostrar Pinos',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      Switch(
                        value: showMarkers,
                        activeThumbColor: _accent,
                        activeTrackColor: _accent.withValues(alpha: 0.3),
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          ref.read(showMarkersProvider.notifier).toggle();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kFabSafeArea),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreviewTile extends StatelessWidget {
  static const _accent = Color(0xFF4CAF50);

  final String tileUrl;
  final String label;
  final bool isSelected;
  final List<String>? subdomains;
  final VoidCallback onTap;

  const _MapPreviewTile({
    required this.tileUrl,
    required this.label,
    required this.isSelected,
    required this.subdomains,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _accent : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  IgnorePointer(
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(-10.69, -48.39),
                        initialZoom: 13.0,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: tileUrl,
                          subdomains: subdomains ?? const <String>[],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: _LayerSelectedBadge(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidPreviewTile extends StatelessWidget {
  static const _accent = Color(0xFF4CAF50);

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _SolidPreviewTile({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _accent : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Stack(
              children: [
                if (isSelected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: _LayerSelectedBadge(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerSelectedBadge extends StatelessWidget {
  const _LayerSelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
      child: const Icon(Icons.check, color: Colors.white, size: 12),
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
