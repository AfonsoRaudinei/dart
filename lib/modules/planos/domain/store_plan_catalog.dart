class StorePlanOffer {
  final String productId;
  final String label;
  final int months;

  const StorePlanOffer({
    required this.productId,
    required this.label,
    required this.months,
  });

  String get prazo => '$months meses';
}

const storePlanOffers = <StorePlanOffer>[
  StorePlanOffer(
    productId: 'soloforte_plano_bronze',
    label: 'Bronze',
    months: 3,
  ),
  StorePlanOffer(
    productId: 'soloforte_plano_prata',
    label: 'Prata',
    months: 6,
  ),
  StorePlanOffer(
    productId: 'soloforte_plano_ouro',
    label: 'Ouro',
    months: 12,
  ),
];

StorePlanOffer? storePlanOfferFor(String productId) {
  for (final offer in storePlanOffers) {
    if (offer.productId == productId) return offer;
  }
  return null;
}
