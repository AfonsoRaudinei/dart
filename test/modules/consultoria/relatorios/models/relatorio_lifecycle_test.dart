import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_status.dart';

import '../../helpers/consultoria_test_factories.dart';
import '../../helpers/fake_relatorio_repository.dart';

void main() {
  test(
    'ciclo de vida: rascunho -> publicado -> arquivado -> excluido logico',
    () async {
      final repository = FakeRelatorioRepository();
      final draft = makeRelatorio(id: 'rel-life-1');
      await repository.save(draft);

      expect(
        (await repository.getAll()).single.status,
        RelatorioStatus.pendente_revisao,
      );

      final published = draft.copyWith(
        status: RelatorioStatus.publicado,
        syncStatus: RelatorioSyncStatus.pending_sync,
      );
      await repository.update(published);
      expect(repository.get('rel-life-1')?.status, RelatorioStatus.publicado);

      final archived = repository
          .get('rel-life-1')!
          .copyWith(
            status: RelatorioStatus.arquivado,
            syncStatus: RelatorioSyncStatus.pending_sync,
          );
      await repository.update(archived);
      expect(repository.get('rel-life-1')?.status, RelatorioStatus.arquivado);

      await repository.softDelete('rel-life-1');

      final deleted = repository.get('rel-life-1');
      expect(deleted?.deletedAt, isNotNull);
      expect(deleted?.syncStatus, RelatorioSyncStatus.deleted_local);
      expect(await repository.getAll(), isEmpty);
    },
  );
}
