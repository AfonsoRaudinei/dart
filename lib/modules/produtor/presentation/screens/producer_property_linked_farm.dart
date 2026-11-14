part of 'producer_property_screen.dart';

class _LinkedFarmTile extends StatelessWidget {
  const _LinkedFarmTile({required this.farm});

  final ProducerOwnFarm farm;

  @override
  Widget build(BuildContext context) {
    final location = [
      farm.city,
      farm.state,
    ].where((value) => value.trim().isNotEmpty).join(' - ');

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.premiumSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.premiumHairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.agriculture_outlined, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      farm.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (location.isNotEmpty) location,
                  '${farm.areaHa.toStringAsFixed(1)} ha',
                ].join(' • '),
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              if (farm.fields.isNotEmpty) ...[
                const SizedBox(height: 10),
                const _SectionTitle('Talhões'),
                ...farm.fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      [
                        field.name,
                        '${field.areaHa.toStringAsFixed(1)} ha',
                        if (field.hasGeometry) 'com mapa',
                      ].join(' • '),
                      style: const TextStyle(color: Color(0xFF374151)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go(AppRoutes.map),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Ver no mapa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
