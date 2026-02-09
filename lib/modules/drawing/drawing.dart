/*
════════════════════════════════════════════════════════════════════
DRAWING MODULE BARREL EXPORT
════════════════════════════════════════════════════════════════════

Export file centralizando todas as interfaces públicas do módulo Drawing.

USO:
  import 'package:app/modules/drawing/drawing.dart';

════════════════════════════════════════════════════════════════════
*/

// Domain
export 'domain/drawing_state.dart';
export 'domain/drawing_utils.dart';
export 'domain/models/drawing_models.dart';
export 'domain/models/drawing_visual_style.dart';

// Data
export 'data/repositories/drawing_repository.dart';

// Presentation
export 'presentation/controllers/drawing_controller.dart';
export 'presentation/widgets/drawing_sheet.dart';
export 'presentation/widgets/drawing_state_indicator.dart';
