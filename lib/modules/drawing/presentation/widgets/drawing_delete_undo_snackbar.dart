import 'package:flutter/material.dart';

import '../../domain/models/drawing_models.dart';
import '../controllers/drawing_controller.dart';

void showDrawingDeleteUndoSnackBar({
  required BuildContext context,
  required DrawingFeature deletedFeature,
  required DrawingController controller,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final fieldName = deletedFeature.properties.nome;
  messenger.showSnackBar(
    SnackBar(
      content: Text('"$fieldName" removido'),
      action: SnackBarAction(
        label: 'DESFAZER',
        onPressed: () {
          messenger.hideCurrentSnackBar();
          controller.restoreFeature(deletedFeature);
        },
      ),
      showCloseIcon: true,
      duration: const Duration(seconds: 5),
    ),
  );
}
