import 'package:soloforte_app/core/contracts/i_teste_execucao_lookup.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

/// Implementa [ITesteExecucaoLookup] a partir de `drawings` + `teste_execucoes`.
class TesteExecucaoLookupAdapter implements ITesteExecucaoLookup {
  TesteExecucaoLookupAdapter({
    required DrawingLocalStore drawingStore,
    required TesteExecucaoLocalStore execucaoStore,
  })  : _drawingStore = drawingStore,
        _execucaoStore = execucaoStore;

  final DrawingLocalStore _drawingStore;
  final TesteExecucaoLocalStore _execucaoStore;

  @override
  Future<List<TesteExecucaoOption>> listByClient({
    required String clientId,
    String? farmId,
  }) async {
    final trimmedClient = clientId.trim();
    if (trimmedClient.isEmpty) return const [];

    final drawings = await _drawingStore.getAll();
    final filteredDrawings = drawings.where((f) {
      if (f.properties.tipo != DrawingType.teste) return false;
      if (!f.properties.ativo) return false;
      if (f.properties.clienteId != trimmedClient) return false;
      final fFarm = f.properties.fazendaId?.trim() ?? '';
      final filterFarm = farmId?.trim() ?? '';
      if (filterFarm.isNotEmpty && fFarm.isNotEmpty && fFarm != filterFarm) {
        return false;
      }
      return true;
    });

    final options = <TesteExecucaoOption>[];
    for (final drawing in filteredDrawings) {
      final execucoes = await _execucaoStore.findByDrawingId(drawing.id);
      for (final exec in execucoes) {
        final talhao = exec.talhao?.trim();
        final nomeDesenho = drawing.properties.nome.trim();
        final labelParts = <String>[
          if (talhao != null && talhao.isNotEmpty) talhao else nomeDesenho,
          '${drawing.properties.areaHa.toStringAsFixed(2)} ha',
        ];
        options.add(
          TesteExecucaoOption(
            id: exec.id,
            drawingId: drawing.id,
            label: labelParts.join(' · '),
            talhao: talhao?.isNotEmpty == true ? talhao : nomeDesenho,
            fotoUrl: exec.fotoUrl,
            areaHa: drawing.properties.areaHa,
            farmId: drawing.properties.fazendaId,
          ),
        );
      }
    }

    options.sort((a, b) => a.label.compareTo(b.label));
    return options;
  }
}