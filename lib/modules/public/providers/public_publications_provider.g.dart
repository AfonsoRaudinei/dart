// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_publications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicPublicationsHash() =>
    r'b018b0ffa54a877b65b55afa64b1a01804b527cd';

/// Provider de publicações públicas para o mapa público.
///
/// Retorna lista de publicações visíveis (isVisible: true, status: 'published')
/// Essas publicações são exibidas como pins no mapa, mas sem ações de edição.
///
/// Copied from [publicPublications].
@ProviderFor(publicPublications)
final publicPublicationsProvider =
    AutoDisposeFutureProvider<List<Publicacao>>.internal(
      publicPublications,
      name: r'publicPublicationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicPublicationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicPublicationsRef = AutoDisposeFutureProviderRef<List<Publicacao>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
