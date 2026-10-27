import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sinal one-shot: ao abrir o [DrawingSheet], entrar direto no formulário de
/// metadados (fluxo compacto da toolbar no mapa).
final drawingCompactOpenMetadataProvider = StateProvider<bool>((ref) => false);
