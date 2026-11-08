import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/domain/talhao_condicao.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_visual_style.dart';

void main() {
  test('quatro condições têm cores fixas', () {
    expect(TalhaoCondicao.bom.argb, 0xFF34C759);
    expect(TalhaoCondicao.atencao.argb, 0xFFFFCC00);
    expect(TalhaoCondicao.alerta.argb, 0xFFFF9500);
    expect(TalhaoCondicao.ruim.argb, 0xFFFF3B30);
    expect(TalhaoCondicao.resolve(null), TalhaoCondicao.bom);
    expect(TalhaoCondicao.resolve(0xFF0000FF), TalhaoCondicao.bom);
    expect(
      TalhaoCondicao.fromArgb(TalhaoCondicao.alerta.argb),
      TalhaoCondicao.alerta,
    );
  });

  test('preenchimento segue a condição e o sync fica na borda', () {
    final ruim = _feature(TalhaoCondicao.ruim.argb);
    expect(ruim.style.fillColor, Color(TalhaoCondicao.ruim.argb));
    expect(ruim.style.isDashed, isFalse);

    final pending = _feature(
      TalhaoCondicao.ruim.argb,
      syncStatus: SyncStatus.pending_sync,
    );
    expect(pending.style.fillColor, Color(TalhaoCondicao.ruim.argb));
    expect(pending.style.isDashed, isTrue);

    final conflict = _feature(
      TalhaoCondicao.atencao.argb,
      syncStatus: SyncStatus.conflict,
    );
    expect(conflict.style.fillColor, Color(TalhaoCondicao.atencao.argb));
    expect(conflict.style.borderColor, const Color(0xFFB00020));
    expect(conflict.style.isDashed, isFalse);
  });
}

DrawingFeature _feature(int? cor, {SyncStatus syncStatus = SyncStatus.synced}) {
  final now = DateTime.utc(2026, 11, 8);
  return DrawingFeature(
    id: 'talhao',
    geometry: DrawingPolygon(
      coordinates: const [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 0.0],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Talhão',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.aprovado,
      autorId: 'user',
      autorTipo: AuthorType.consultor,
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: syncStatus,
      cor: cor,
    ),
  );
}
