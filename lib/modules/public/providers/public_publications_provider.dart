import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/publicacao.dart';
import '../../../core/state/map_state.dart';

part 'public_publications_provider.g.dart';

/// Provider de publicações públicas para o mapa público.
///
/// Retorna lista de publicações visíveis (isVisible: true, status: 'published')
/// Essas publicações são exibidas como pins no mapa, mas sem ações de edição.
@riverpod
Future<List<Publicacao>> publicPublications(Ref ref) async {
  final repository = ref.read(mapRepositoryProvider);
  return repository.fetchPublicPublicacoes();
}
