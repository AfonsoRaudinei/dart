import 'package:flutter/material.dart';

/// Stub usado em builds release (`dart.vm.product`) — sem dependência de device_preview.
class DevicePreview {
  const DevicePreview._();

  static Locale locale(BuildContext context) => const Locale('pt', 'BR');

  static Widget appBuilder(BuildContext context, Widget child) => child;
}
