import '../../../screens/map/providers/pin_position_correction_provider.dart';
import '../../../../modules/marketing/domain/enums/plano_marketing.dart';
import '../../../../modules/marketing/presentation/widgets/marketing_case_marker.dart';
import '../occurrence_pins.dart';

/// Layout em pixels do pin de correção sobre o mapa.
///
/// Espelha as políticas de âncora dos [Marker]s reais:
/// - ocorrência → [Alignment.center] (centro do círculo na coordenada)
/// - marketing → [Alignment.topCenter] (ponteiro na base aponta para a coordenada)
class PinCorrectionScreenLayout {
  const PinCorrectionScreenLayout({
    required this.width,
    required this.height,
    required this.left,
    required this.top,
  });

  final double width;
  final double height;
  final double left;
  final double top;
}

/// Calcula posição/tamanho do widget de preview durante correção de pin.
PinCorrectionScreenLayout layoutPinCorrectionOnScreen({
  required PinCorrectionKind kind,
  required double screenX,
  required double screenY,
  PlanoMarketing marketingTier = PlanoMarketing.bronze,
}) {
  switch (kind) {
    case PinCorrectionKind.occurrence:
      final size = OccurrencePinGenerator.pinSize;
      return PinCorrectionScreenLayout(
        width: size,
        height: size,
        left: screenX - (size / 2),
        top: screenY - (size / 2),
      );
    case PinCorrectionKind.marketing:
      final width = MarketingCaseMarker.pinWidth(marketingTier);
      final height = MarketingCaseMarker.pinHeight(marketingTier) + 10;
      return PinCorrectionScreenLayout(
        width: width,
        height: height,
        left: screenX - (width / 2),
        top: screenY - height,
      );
  }
}
