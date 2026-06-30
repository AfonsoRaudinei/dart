import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import 'drawing_models.dart';

/// Define os estados puramente visuais que um talhão/desenho pode assumir no mapa.
enum FieldVisualState {
  /// Estado padrão: Talhão salvo, sincronizado e inativo.
  standard,

  /// Estado de rascunho: Ainda não salvo ou em edição local.
  draft,

  /// Estado de sincronização pendente: Salvo localmente, aguardando nuvem.
  pendingSync,

  /// Estado de conflito: Erro de sincronização ou validação.
  conflict,

  /// Estado selecionado: O usuário clicou neste talhão.
  selected,

  /// Estado em edição: O talhão está sendo modificado ativamente (vértices visíveis).
  editing,

  /// Estado desativado/arquivado: Visibilidade reduzida.
  archived,
}

/// Encapsula todas as propriedades de estilo para renderização no mapa.
class FieldStyle {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final bool isDashed;
  final double fillOpacity;

  const FieldStyle({
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 2.0,
    this.isDashed = false,
    this.fillOpacity = 0.3, // Opacidade padrão
  });

  /// Estilo padrão para talhões consolidados (Verde SoloForte)
  static const standard = FieldStyle(
    fillColor: PremiumTokens.brandGreen,
    borderColor: Color(0xFF145A2A),
    borderWidth: 3.0,
    fillOpacity: 0.28, // Mais legível sobre satélite sem cobrir demais
  );

  /// Estilo para rascunhos (Cinza/Neutro, tracejado)
  static const draft = FieldStyle(
    fillColor: Colors.grey,
    borderColor: Colors.blueGrey,
    borderWidth: 2.5,
    isDashed: true,
    fillOpacity: 0.24,
  );

  /// Estilo para pendente de sincronização (Laranja sutil)
  static const pendingSync = FieldStyle(
    fillColor: Colors.orange,
    borderColor: Colors.deepOrange,
    borderWidth: 2.5,
    isDashed: true, // Indica que ainda "não está lá"
    fillOpacity: 0.24,
  );

  /// Estilo para conflito/erro (Vermelho alerta)
  static const conflict = FieldStyle(
    fillColor: Colors.red,
    borderColor: Colors.redAccent,
    borderWidth: 3.0,
    fillOpacity: 0.3,
  );

  /// Estilo para selecionado (Azul destaque, borda mais grossa)
  static const selected = FieldStyle(
    fillColor: Colors.blue,
    borderColor: Colors.blueAccent,
    borderWidth: 4.5, // Destaque na borda
    fillOpacity: 0.34, // Seleção precisa ficar inequívoca
  );

  /// Estilo para modo de edição (Roxo, muito transparente para ver vértices)
  static const editing = FieldStyle(
    fillColor: Colors.purple,
    borderColor: Colors.purpleAccent,
    borderWidth: 2.0,
    isDashed: true, // Ajuda a identificar que está mudando
    fillOpacity: 0.1, // Quase transparente
  );

  /// Estilo para arquivado (Cinza claro, muito sutil)
  static const archived = FieldStyle(
    fillColor: Colors.grey,
    borderColor: Colors.grey,
    borderWidth: 1.0,
    fillOpacity: 0.1,
  );
}

/// Extensão para obter o estilo diretamente de uma DrawingFeature
extension DrawingFeatureStyle on DrawingFeature {
  static Color _emphasizeBorder(Color base) {
    final hsl = HSLColor.fromColor(base);
    final darkerLightness = (hsl.lightness - 0.22).clamp(0.12, 0.45);
    final strongerSaturation = (hsl.saturation + 0.08).clamp(0.0, 1.0);
    return hsl
        .withLightness(darkerLightness)
        .withSaturation(strongerSaturation)
        .toColor();
  }

  FieldVisualState get visualState {
    if (!properties.ativo) return FieldVisualState.archived;

    // Prioridade 1: Edição/Seleção (precisam ser estados passados externamente ou inferidos)
    // Como a feature em si não sabe se está selecionada no controller,
    // aqui baseamos apenas nas propriedades intrínsecas.
    // O controller deverá sobrescrever o estilo se estiver selecionado.

    if (properties.syncStatus == SyncStatus.conflict) {
      return FieldVisualState.conflict;
    }

    if (properties.syncStatus == SyncStatus.pending_sync) {
      return FieldVisualState.pendingSync;
    }

    if (properties.status == DrawingStatus.rascunho) {
      return FieldVisualState.draft;
    }

    return FieldVisualState.standard;
  }

  FieldStyle get style {
    switch (visualState) {
      case FieldVisualState.standard:
        // 🆕 Se tiver cor personalizada definida (via grupo ou manual), usa ela
        if (properties.cor != null) {
          final customColor = Color(properties.cor!);
          return FieldStyle(
            fillColor: customColor,
            borderColor: _emphasizeBorder(customColor),
            borderWidth: 3.0,
            fillOpacity: 0.26,
          );
        }
        return FieldStyle.standard;
      case FieldVisualState.draft:
        return FieldStyle.draft;
      case FieldVisualState.pendingSync:
        return FieldStyle.pendingSync;
      case FieldVisualState.conflict:
        return FieldStyle.conflict;
      case FieldVisualState.archived:
        return FieldStyle.archived;
      default:
        return FieldStyle.standard;
    }
  }
}
