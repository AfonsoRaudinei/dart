import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/publicacao.dart';

part 'public_publications_provider.g.dart';

/// Provider de publicações públicas para o mapa público.
///
/// Retorna lista de publicações visíveis (isVisible: true, status: 'published')
/// Essas publicações são exibidas como pins no mapa, mas sem ações de edição.
@riverpod
Future<List<Publicacao>> publicPublications(Ref ref) async {
  // Simula carregamento assíncrono
  await Future.delayed(const Duration(milliseconds: 500));

  // TODO: Integrar com Supabase quando pronto
  // final response = await Supabase.instance.client
  //     .from('publicacoes')
  //     .select()
  //     .eq('isVisible', true)
  //     .eq('status', 'published');

  // Mock de publicações públicas para demonstração
  return _getMockPublicPublications();
}

/// Dados mockados de publicações públicas
/// Baseado nas imagens da solicitação do usuário
List<Publicacao> _getMockPublicPublications() {
  return [
    // Publicação 1 - São Paulo (centro)
    Publicacao(
      id: 'pub_001',
      latitude: -23.5505,
      longitude: -46.6333,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      status: 'published',
      isVisible: true,
      type: PublicacaoType.resultado,
      title: 'Colheita Recorde em SP',
      description: 'Produtividade 30% acima da média regional',
      clientName: 'Fazenda São José',
      areaName: 'Talhão A-3',
      media: [
        MediaItem(
          id: 'media_001',
          path: 'https://picsum.photos/400/300?random=1',
          caption: 'Plantio de soja - Setembro 2025',
          isCover: true,
        ),
        MediaItem(
          id: 'media_002',
          path: 'https://picsum.photos/400/300?random=2',
          caption: 'Colheita mecanizada',
          isCover: false,
        ),
      ],
    ),

    // Publicação 2 - Norte de SP
    Publicacao(
      id: 'pub_002',
      latitude: -23.4500,
      longitude: -46.5800,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      status: 'published',
      isVisible: true,
      type: PublicacaoType.tecnico,
      title: 'Análise de Solo Completa',
      description: 'Mapeamento nutricional e recomendações',
      clientName: 'Agro Consultoria',
      areaName: 'Área Experimental',
      media: [
        MediaItem(
          id: 'media_003',
          path: 'https://picsum.photos/400/300?random=3',
          caption: 'Coleta de amostras',
          isCover: true,
        ),
      ],
    ),

    // Publicação 3 - Leste de SP
    Publicacao(
      id: 'pub_003',
      latitude: -23.5200,
      longitude: -46.7100,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      status: 'published',
      isVisible: true,
      type: PublicacaoType.caseSucesso,
      title: 'Case de Sucesso - Milho',
      description: 'Aumento de 40% na produtividade com manejo integrado',
      clientName: 'Fazenda Santa Clara',
      areaName: 'Pivô Central 02',
      media: [
        MediaItem(
          id: 'media_004',
          path: 'https://picsum.photos/400/300?random=4',
          caption: 'Milho em desenvolvimento',
          isCover: true,
        ),
        MediaItem(
          id: 'media_005',
          path: 'https://picsum.photos/400/300?random=5',
          caption: 'Comparativo antes/depois',
          isCover: false,
        ),
      ],
    ),

    // Publicação 4 - Sul de SP
    Publicacao(
      id: 'pub_004',
      latitude: -23.6200,
      longitude: -46.6500,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: 'published',
      isVisible: true,
      type: PublicacaoType.institucional,
      title: 'Evento Técnico SoloForte',
      description: 'Demonstração de tecnologias agrícolas',
      clientName: 'SoloForte',
      areaName: 'Centro de Treinamento',
      media: [
        MediaItem(
          id: 'media_006',
          path: 'https://picsum.photos/400/300?random=6',
          caption: 'Participantes do evento',
          isCover: true,
        ),
      ],
    ),

    // Publicação 5 - Oeste de SP
    Publicacao(
      id: 'pub_005',
      latitude: -23.5400,
      longitude: -46.5200,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      status: 'published',
      isVisible: true,
      type: PublicacaoType.comparativo,
      title: 'Comparativo de Cultivares',
      description: 'Teste de 5 variedades de soja em mesmas condições',
      clientName: 'Instituto Agrícola',
      areaName: 'Parcelas Experimentais',
      media: [
        MediaItem(
          id: 'media_007',
          path: 'https://picsum.photos/400/300?random=7',
          caption: 'Parcelas lado a lado',
          isCover: true,
        ),
        MediaItem(
          id: 'media_008',
          path: 'https://picsum.photos/400/300?random=8',
          caption: 'Resultados finais',
          isCover: false,
        ),
      ],
    ),
  ];
}
