import 'package:flutter/material.dart';
import 'drawing_controller.dart';
import 'drawing_models.dart';

class DrawingSheet extends StatelessWidget {
  final DrawingController controller;

  const DrawingSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.interactionMode == DrawingInteraction.unionSelection) {
          return _buildUnionMode(context);
        }
        if (controller.interactionMode == DrawingInteraction.cutDrawing) {
          return _buildCutMode(context);
        }
        if (controller.selectedFeature != null) {
          return _buildSelectedMode(context);
        }
        return _buildDefaultTools(context);
      },
    );
  }

  Widget _buildDefaultTools(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ferramentas de Desenho',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              _ToolButton(icon: Icons.hexagon_outlined, label: 'Polígono'),
              _ToolButton(icon: Icons.gesture, label: 'Livre'),
              _ToolButton(icon: Icons.radio_button_checked, label: 'Pivô'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Trigger KML Import
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar KML/KMZ'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMode(BuildContext context) {
    final feature = controller.selectedFeature!;
    final isConsultant =
        feature.properties.autorTipo ==
        AuthorType.consultor; // Example permission check
    final isEditable = feature.properties.status != DrawingStatus.arquivado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Área: ${feature.properties.nome}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            'Status: ${feature.properties.status.name}',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(height: 24),
          if (isEditable) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar geometria'),
              onTap: () {
                // Trigger edit mode
              },
            ),
            if (isConsultant) ...[
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Unir com outra área'),
                onTap: controller.startUnionMode,
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Recortar área'),
                onTap: controller.startCutMode,
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicar'),
              onTap: () {
                // Duplicate logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: Colors.red),
              title: const Text(
                'Arquivar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // Archive logic
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnionMode(BuildContext context) {
    final hasCandidate = controller.pendingFeatureB != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '➕ Unir áreas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          if (!hasCandidate)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Toque em outra área no mapa para unir...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else ...[
            Text('Área A: ${controller.pendingFeatureA?.properties.nome}'),
            Text('Área B: ${controller.pendingFeatureB?.properties.nome}'),
            const SizedBox(height: 12),
            const Text(
              'Resultado: Área única',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.cancelOperation,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.confirmUnion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Confirmar União',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!hasCandidate)
            OutlinedButton(
              onPressed: controller.cancelOperation,
              child: const Text('Cancelar'),
            ),
        ],
      ),
    );
  }

  Widget _buildCutMode(BuildContext context) {
    final hasPreview = controller.previewGeometry != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '➖ Recortar área',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          if (!hasPreview)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Desenhe o polígono de recorte dentro da área...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else ...[
            Text('Área: ${controller.pendingFeatureA?.properties.nome}'),
            const SizedBox(height: 8),
            const Text('Tipo: Recorte interno (buraco)'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.cancelOperation,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.confirmCut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Confirmar Recorte',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!hasPreview)
            OutlinedButton(
              onPressed: controller.cancelOperation,
              child: const Text('Cancelar'),
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ToolButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
