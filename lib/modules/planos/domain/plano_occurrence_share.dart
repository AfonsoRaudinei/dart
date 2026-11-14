import 'package:soloforte_app/core/access/producer_link_occurrence_policy.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';

extension UserPlanOccurrenceShare on UserPlan {
  bool get consultorPodeCompartilharOcorrenciaNoVinculo =>
      ProducerLinkOccurrencePolicy.consultorPodeCompartilharOcorrencia(
        isAdmin: isAdmin,
        planId: id,
        ocultaPinsMarketingNoMapa: ocultaPinsMarketingNoMapa,
      );

  bool get produtorPodeVerOcorrenciaCompartilhadaNoVinculo =>
      ProducerLinkOccurrencePolicy.usuarioPodeAcessarOcorrenciasNoVinculo(
        isAdmin: isAdmin,
        planId: id,
        ocultaPinsMarketingNoMapa: ocultaPinsMarketingNoMapa,
      );
}