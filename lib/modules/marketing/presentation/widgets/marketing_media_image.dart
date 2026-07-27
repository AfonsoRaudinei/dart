import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/marketing_media_ref.dart';

/// Thumbnail de mídia de marketing (URL remota ou arquivo local offline).
class MarketingMediaImage extends StatelessWidget {
  final String? source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context) placeholder;
  final Duration fadeInDuration;

  const MarketingMediaImage({
    super.key,
    required this.source,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fadeInDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    final value = source?.trim();
    if (value == null || value.isEmpty) {
      return placeholder(context);
    }

    if (MarketingMediaRef.isLocalPath(value)) {
      final path = MarketingMediaRef.toFilePath(value);
      if (path == null || !File(path).existsSync()) {
        return placeholder(context);
      }
      return Image.file(
        File(path),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => placeholder(context),
      );
    }

    if (!MarketingMediaRef.isRemoteUrl(value)) {
      return placeholder(context);
    }

    return CachedNetworkImage(
      imageUrl: value,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => placeholder(context),
      errorWidget: (_, __, ___) => placeholder(context),
      fadeInDuration: fadeInDuration,
    );
  }
}
