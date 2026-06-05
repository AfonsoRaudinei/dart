import 'package:flutter/material.dart';

import '../../../../core/contracts/i_active_visit_context_lookup.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
import 'novo_case_sheet.dart';

/// Wrappers tipados para abertura direta dos fluxos de marketing.
///
/// Mantem a montagem do [MarketingCase], validacoes, upload e persistencia no
/// [NovoCaseSheet] atual. Estes widgets apenas fixam o tipo inicial.
class NovoResultadoCaseSheet extends StatelessWidget {
  final double lat;
  final double lng;
  final ActiveVisitContext? initialVisitContext;
  final VoidCallback onClose;
  final void Function(MarketingCase) onPublicar;

  const NovoResultadoCaseSheet({
    super.key,
    required this.lat,
    required this.lng,
    this.initialVisitContext,
    required this.onClose,
    required this.onPublicar,
  });

  @override
  Widget build(BuildContext context) {
    return NovoCaseSheet(
      lat: lat,
      lng: lng,
      tipo: CaseTipo.resultado,
      initialVisitContext: initialVisitContext,
      onClose: onClose,
      onPublicar: onPublicar,
    );
  }
}

class NovoAntesDepoisCaseSheet extends StatelessWidget {
  final double lat;
  final double lng;
  final ActiveVisitContext? initialVisitContext;
  final VoidCallback onClose;
  final void Function(MarketingCase) onPublicar;

  const NovoAntesDepoisCaseSheet({
    super.key,
    required this.lat,
    required this.lng,
    this.initialVisitContext,
    required this.onClose,
    required this.onPublicar,
  });

  @override
  Widget build(BuildContext context) {
    return NovoCaseSheet(
      lat: lat,
      lng: lng,
      tipo: CaseTipo.antesDepois,
      initialVisitContext: initialVisitContext,
      onClose: onClose,
      onPublicar: onPublicar,
    );
  }
}

class NovaAvaliacaoCaseSheet extends StatelessWidget {
  final double lat;
  final double lng;
  final ActiveVisitContext? initialVisitContext;
  final VoidCallback onClose;
  final void Function(MarketingCase) onPublicar;

  const NovaAvaliacaoCaseSheet({
    super.key,
    required this.lat,
    required this.lng,
    this.initialVisitContext,
    required this.onClose,
    required this.onPublicar,
  });

  @override
  Widget build(BuildContext context) {
    return NovoCaseSheet(
      lat: lat,
      lng: lng,
      tipo: CaseTipo.avaliacao,
      initialVisitContext: initialVisitContext,
      onClose: onClose,
      onPublicar: onPublicar,
    );
  }
}
