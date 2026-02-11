import 'package:flutter/material.dart';

class FieldDetailScreen extends StatelessWidget {
  final String farmId;
  final String fieldId; // Talhao

  const FieldDetailScreen({
    super.key,
    required this.farmId,
    required this.fieldId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Talhão',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Center(child: Text('Detalhes do Talhão: $fieldId')),
            ),
          ],
        ),
      ),
    );
  }
}
