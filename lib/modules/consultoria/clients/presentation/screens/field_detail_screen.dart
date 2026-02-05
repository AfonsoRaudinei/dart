import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Talhão', // "Talhão" in Portuguese
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => context.pop(),
                  ),
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
