import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../ui/theme/premium/design_tokens.dart';
import '../providers/settings_providers.dart';

class ReportBrandingScreen extends ConsumerStatefulWidget {
  const ReportBrandingScreen({super.key});

  @override
  ConsumerState<ReportBrandingScreen> createState() =>
      _ReportBrandingScreenState();
}

class _ReportBrandingScreenState extends ConsumerState<ReportBrandingScreen> {
  late final TextEditingController _brandNameController;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(reportBrandingProvider).brandName ?? '';
    _brandNameController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(reportBrandingProvider);
    final customLogoPath = branding.logoPath?.trim();
    final hasRemoteLogo = customLogoPath?.startsWith('http') ?? false;
    final hasLocalLogo =
        customLogoPath != null &&
        customLogoPath.isNotEmpty &&
        File(customLogoPath).existsSync();
    final hasCustomLogo = hasRemoteLogo || hasLocalLogo;
    final displayName = branding.hasCustomBrandName
        ? branding.brandName!.trim()
        : 'SoloForte';

    return Scaffold(
      backgroundColor: PremiumTokens.backgroundLight,
      appBar: AppBar(
        backgroundColor: PremiumTokens.backgroundLight,
        surfaceTintColor: Colors.transparent,
        title: const Text('Marca dos Relatórios'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PreviewCard(
            displayName: displayName,
            customLogoSource: hasCustomLogo ? customLogoPath : null,
            customized: branding.isCustomized,
          ),
          const SizedBox(height: 16),
          Text(
            'Nome exibido nos relatórios',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _brandNameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Ex.: Agro Forte Consultoria',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              ref.read(reportBrandingProvider.notifier).updateBrandName(value);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Logo do emissor',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Use o logo do consultor ou da empresa. O rodapé continua assinando a plataforma SoloForte.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PremiumTokens.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => _pickLogo(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeria'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickLogo(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Câmera'),
              ),
              OutlinedButton.icon(
                onPressed: branding.isCustomized
                    ? () async {
                        _brandNameController.clear();
                        await ref.read(reportBrandingProvider.notifier).reset();
                      }
                    : null,
                icon: const Icon(Icons.restart_alt_outlined),
                label: const Text('Padrão SoloForte'),
              ),
            ],
          ),
          if (hasCustomLogo) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  ref.read(reportBrandingProvider.notifier).clearLogo(),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remover logo personalizado'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickLogo(ImageSource source) {
    return ref.read(reportBrandingProvider.notifier).updateLogo(source);
  }
}

class _PreviewCard extends StatelessWidget {
  final String displayName;
  final String? customLogoSource;
  final bool customized;

  const _PreviewCard({
    required this.displayName,
    required this.customLogoSource,
    required this.customized,
  });

  @override
  Widget build(BuildContext context) {
    final issuerImage = customLogoSource != null
        ? DecorationImage(
            image: customLogoSource!.startsWith('http')
                ? NetworkImage(customLogoSource!)
                : FileImage(File(customLogoSource!)),
            fit: BoxFit.contain,
          )
        : const DecorationImage(
            image: AssetImage('assets/images/soloforte_logo.png'),
            fit: BoxFit.contain,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prévia de assinatura',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  image: issuerImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customized
                          ? 'Cabeçalho com identidade personalizada'
                          : 'Cabeçalho padrão SoloForte',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PremiumTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _FooterBrandPreview(
                  title: 'Emissor',
                  subtitle: 'Logo e nome configurados',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _FooterBrandPreview(
                  title: 'SoloForte',
                  subtitle: 'Plataforma de relatórios',
                  assetLogo: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterBrandPreview extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool assetLogo;

  const _FooterBrandPreview({
    required this.title,
    required this.subtitle,
    this.assetLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              image: assetLogo
                  ? const DecorationImage(
                      image: AssetImage('assets/images/soloforte_logo.png'),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: assetLogo
                ? null
                : const Icon(Icons.business_outlined, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PremiumTokens.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
