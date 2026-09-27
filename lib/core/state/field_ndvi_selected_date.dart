import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data `yyyy-MM-dd` visível no card e no sheet do talhão.
/// Nula usa a cena mais nova.
final fieldNdviSelectedDateProvider = StateProvider.autoDispose
    .family<String?, String>((ref, fieldId) => null);
