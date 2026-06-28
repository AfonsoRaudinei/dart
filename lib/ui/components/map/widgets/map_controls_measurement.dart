part of 'map_controls_overlay.dart';

class _FieldMeasurementCard extends StatelessWidget {
  final double areaHa;
  final AreaDisplayUnit areaUnit;
  final bool showDetails;
  final ValueChanged<AreaDisplayUnit> onAreaUnit;
  final VoidCallback onToggleDetails;

  const _FieldMeasurementCard({
    required this.areaHa,
    required this.areaUnit,
    required this.showDetails,
    required this.onAreaUnit,
    required this.onToggleDetails,
  });

  String _formatArea() {
    switch (areaUnit) {
      case AreaDisplayUnit.hectare:
        return '${areaHa.toStringAsFixed(3)} ha';
      case AreaDisplayUnit.squareMeter:
        return '${(areaHa * 10000).toStringAsFixed(0)} m²';
      case AreaDisplayUnit.alqueire:
        return '${(areaHa / 4.84).toStringAsFixed(3)} alq GO/MG';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('measurement_area_card'),
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatArea(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                key: const Key('measurement_details_toggle'),
                behavior: HitTestBehavior.opaque,
                onTap: onToggleDetails,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    showDetails ? Icons.expand_less : Icons.info_outline,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _UnitChip(
                  label: 'ha',
                  selected: areaUnit == AreaDisplayUnit.hectare,
                  onTap: () => onAreaUnit(AreaDisplayUnit.hectare),
                ),
                const SizedBox(width: 6),
                _UnitChip(
                  label: 'm²',
                  selected: areaUnit == AreaDisplayUnit.squareMeter,
                  onTap: () => onAreaUnit(AreaDisplayUnit.squareMeter),
                ),
                const SizedBox(width: 6),
                _UnitChip(
                  label: 'alq GO/MG',
                  selected: areaUnit == AreaDisplayUnit.alqueire,
                  onTap: () => onAreaUnit(AreaDisplayUnit.alqueire),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementDetailsCard extends StatelessWidget {
  final double perimeterKm;
  final double? azimuthDeg;
  final double gpsAccuracyM;
  final DistanceDisplayUnit distanceUnit;
  final ValueChanged<DistanceDisplayUnit> onDistanceUnit;

  const _MeasurementDetailsCard({
    required this.perimeterKm,
    required this.azimuthDeg,
    required this.gpsAccuracyM,
    required this.distanceUnit,
    required this.onDistanceUnit,
  });

  String _formatDistance() {
    switch (distanceUnit) {
      case DistanceDisplayUnit.kilometer:
        return '${perimeterKm.toStringAsFixed(3)} km';
      case DistanceDisplayUnit.meter:
        return '${(perimeterKm * 1000).toStringAsFixed(0)} m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('measurement_details_card'),
      width: 188,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEE1A1A1D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perímetro: ${_formatDistance()}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Azimute: ${azimuthDeg?.toStringAsFixed(1) ?? '--'}°',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            gpsAccuracyM > 0
                ? 'GPS: ±${gpsAccuracyM.toStringAsFixed(1)} m'
                : 'GPS: --',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _UnitChip(
                label: 'km',
                selected: distanceUnit == DistanceDisplayUnit.kilometer,
                onTap: () => onDistanceUnit(DistanceDisplayUnit.kilometer),
              ),
              _UnitChip(
                label: 'm',
                selected: distanceUnit == DistanceDisplayUnit.meter,
                onTap: () => onDistanceUnit(DistanceDisplayUnit.meter),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF34C759) : Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
