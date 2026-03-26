import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider local para índice de navegação entre datas no sheet.
// autoDispose garante descarte ao fechar o sheet.
// family por fieldId — cada talhão tem seu próprio índice.

final ndviDateIndexProvider =
    StateProvider.family.autoDispose<int, String>((ref, fieldId) => 0);
