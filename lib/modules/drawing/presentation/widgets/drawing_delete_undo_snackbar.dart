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
      content: Row(
        children: [
          Expanded(child: Text('"$fieldName" removido')),
          TextButton(
            onPressed: () {
              messenger.hideCurrentSnackBar();
              controller.restoreFeature(deletedFeature);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('DESFAZER'),
          ),
          IconButton(
            key: const Key('drawing_delete_snackbar_close'),
            onPressed: () => messenger.hideCurrentSnackBar(),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: Colors.white,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Fechar',
          ),
        ],
      ),
      duration: const Duration(seconds: 5),
    ),
  );
}
