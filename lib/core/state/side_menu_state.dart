/*
════════════════════════════════════════════════════════════════════
SIDE MENU STATE PROVIDER — CONTROLE DE OVERLAY
════════════════════════════════════════════════════════════════════

Provider para controlar o estado do SideMenu como overlay.

REGRAS:
- Menu abre/fecha sem depender do Scaffold Drawer
- Estado global controlado via Riverpod
- SmartButton e SideMenu compartilham este estado
════════════════════════════════════════════════════════════════════
*/

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que controla se o SideMenu está aberto ou fechado
final sideMenuOpenProvider = StateProvider<bool>((ref) => false);
