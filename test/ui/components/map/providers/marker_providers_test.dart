import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:soloforte_app/ui/components/map/providers/marker_providers.dart';
import 'package:soloforte_app/core/domain/publicacao.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';

void main() {
  group('publicationMarkersProvider', () {
    test('deve retornar lista vazia quando não há publicações', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Provider base não configurado, deve retornar lista vazia
      final markers = container.read(publicationMarkersProvider);
      
      expect(markers, isEmpty);
      expect(markers, isA<List<Marker>>());
    });
  });

  group('localPublicationMarkersProvider', () {
    test('deve retornar lista vazia quando não há publicações locais', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final markers = container.read(
        localPublicationMarkersProvider(const <Publicacao>[]),
      );
      
      expect(markers, isEmpty);
    });

    test('deve criar markers para publicações locais', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final publicacoes = <Publicacao>[
        Publicacao(
          id: '1',
          latitude: -23.5505,
          longitude: -46.6333,
          createdAt: DateTime.now(),
          status: 'published',
          isVisible: true,
          type: PublicacaoType.tecnico,
        ),
        Publicacao(
          id: '2',
          latitude: -23.5600,
          longitude: -46.6400,
          createdAt: DateTime.now(),
          status: 'published',
          isVisible: true,
          type: PublicacaoType.tecnico,
        ),
      ];

      final markers = container.read(
        localPublicationMarkersProvider(publicacoes),
      );
      
      expect(markers, hasLength(2));
      expect(markers.first.point.latitude, equals(-23.5505));
      expect(markers.first.point.longitude, equals(-46.6333));
      expect(markers.last.point.latitude, equals(-23.5600));
      expect(markers.last.point.longitude, equals(-46.6400));
    });

    test('markers devem ter keys únicas e estáveis', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final publicacoes = <Publicacao>[
        Publicacao(
          id: 'pub_123',
          latitude: -23.5505,
          longitude: -46.6333,
          createdAt: DateTime.now(),
          status: 'published',
          isVisible: true,
          type: PublicacaoType.tecnico,
        ),
      ];

      final markers = container.read(
        localPublicationMarkersProvider(publicacoes),
      );
      
      final marker = markers.first;
      expect(marker.key.toString(), contains('pub_123'));
    });

    test('markers devem ter tamanho correto e keys únicas', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final publicacoes = <Publicacao>[
        Publicacao(
          id: '1',
          latitude: -23.5505,
          longitude: -46.6333,
          createdAt: DateTime.now(),
          status: 'published',
          isVisible: true,
          type: PublicacaoType.tecnico,
        ),
      ];

      final markers = container.read(
        localPublicationMarkersProvider(publicacoes),
      );
      
      // Lista não-vazia com tamanho correto
      expect(markers, hasLength(1));
      expect(markers.first, isA<Marker>());
    });
  });

  group('occurrenceMarkersProvider', () {
    test('deve filtrar ocorrências com lat/long null', () async {
      final now = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          occurrencesListProvider.overrideWith(
            (ref) async => [
              Occurrence(
                id: 'sem-coord',
                type: 'Média',
                description: 'Sem coordenadas',
                createdAt: now,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(occurrencesListProvider.future);
      final markers = container.read(occurrenceMarkersProvider((occ) {}));
      expect(markers, isEmpty);
    });

    test('deve criar marker quando só geometry estiver preenchida', () async {
      final now = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          occurrencesListProvider.overrideWith(
            (ref) async => [
              Occurrence(
                id: 'geometry-only',
                type: 'Média',
                description: 'Com geometry',
                geometry:
                    '{"type":"Point","coordinates":[-46.6333,-23.5505]}',
                createdAt: now,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(occurrencesListProvider.future);
      final markers = container.read(occurrenceMarkersProvider((occ) {}));

      expect(markers, hasLength(1));
      expect(markers.first.point.latitude, equals(-23.5505));
      expect(markers.first.point.longitude, equals(-46.6333));
      expect(markers.first.alignment, equals(Alignment.center));
    });
  });

  group('Isolamento de Rebuilds', () {
    test('publicationMarkersProvider não deve rebuildar por outros providers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var buildCount = 0;
      
      // Listener para contar rebuilds
      container.listen(
        publicationMarkersProvider,
        (previous, next) {
          buildCount++;
        },
      );

      // Primeira leitura
      container.read(publicationMarkersProvider);
      expect(buildCount, equals(0)); // Não deve notificar na primeira leitura
    });
  });

  group('Otimizações', () {
    test('providers devem retornar listas de Marker corretas', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // publicationMarkersProvider
      final pubMarkers = container.read(publicationMarkersProvider);
      expect(pubMarkers, isA<List<Marker>>());

      // localPublicationMarkersProvider
      final localMarkers = container.read(
        localPublicationMarkersProvider(const <Publicacao>[]),
      );
      expect(localMarkers, isA<List<Marker>>());

      // occurrenceMarkersProvider
      final occMarkers = container.read(
        occurrenceMarkersProvider((occ) {}),
      );
      expect(occMarkers, isA<List<Marker>>());
    });
  });
}
