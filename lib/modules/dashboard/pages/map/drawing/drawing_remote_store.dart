import 'drawing_models.dart';

class DrawingRemoteStore {
  // Stub for remote API integration
  // This would typically involve HTTP calls (Dio/http) to a backend service

  Future<void> push(DrawingFeature feature) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Simulate random failure (10%)
    if (DateTime.now().millisecond % 10 == 0) {
      throw Exception("Network error simulating failure");
    }

    // Simulate success
    // In real world: POST /api/drawings or PATCH /api/drawings/:id
  }

  Future<List<DrawingFeature>> fetchUpdates(DateTime? lastSync) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Simulate returning some updated features from backend
    // Since we don't have a real backend, we return empty list usually,
    // or stub some conflict scenarios if needed for testing.
    return [];
  }
}
