import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/ui/screens/map/controllers/map_camera_animator.dart';

void main() {
  testWidgets('MapCameraAnimator move ease até destino', (tester) async {
    final mapController = MapController();
    late MapCameraAnimator animator;

    await tester.pumpWidget(
      MaterialApp(
        home: _AnimatorHost(
          mapController: mapController,
          onReady: (a) => animator = a,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final start = mapController.camera.center;
    final dest = LatLng(start.latitude + 0.05, start.longitude + 0.05);

    animator.animateTo(
      mapController: mapController,
      dest: dest,
      zoom: 14,
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(mapController.camera.center, isNot(dest));

    await tester.pumpAndSettle();
    expect(mapController.camera.center.latitude, closeTo(dest.latitude, 0.0001));
    expect(
      mapController.camera.center.longitude,
      closeTo(dest.longitude, 0.0001),
    );
    expect(mapController.camera.zoom, closeTo(14, 0.01));

    animator.dispose();
  });
}

class _AnimatorHost extends StatefulWidget {
  const _AnimatorHost({required this.mapController, required this.onReady});

  final MapController mapController;
  final ValueChanged<MapCameraAnimator> onReady;

  @override
  State<_AnimatorHost> createState() => _AnimatorHostState();
}

class _AnimatorHostState extends State<_AnimatorHost>
    with TickerProviderStateMixin {
  late final MapCameraAnimator _animator = MapCameraAnimator(vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReady(_animator);
    });
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: widget.mapController,
      options: const MapOptions(
        initialCenter: LatLng(-15.8, -47.9),
        initialZoom: 10,
      ),
      children: const [],
    );
  }
}
