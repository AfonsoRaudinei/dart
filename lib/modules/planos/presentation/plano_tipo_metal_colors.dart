// Cores de metal para UI do módulo planos (local — não altera Design System global).

import 'package:flutter/material.dart';

import '../domain/enums/plano_tipo.dart';

abstract final class PlanoTipoMetalColors {
  static const bronze = Color(0xFFB87333);
  static const prata = Color(0xFF8E8E93);
  static const ouro = Color(0xFFC4A35A);

  static Color forTipo(PlanoTipo tipo) {
    switch (tipo) {
      case PlanoTipo.bronze:
        return bronze;
      case PlanoTipo.prata:
        return prata;
      case PlanoTipo.ouro:
        return ouro;
    }
  }

  static Color badgeBackground(Color metal) => metal.withValues(alpha: 0.12);
}