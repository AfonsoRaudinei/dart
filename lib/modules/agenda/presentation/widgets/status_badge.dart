import 'package:flutter/material.dart';
import '../../domain/enums/event_status.dart';

/// Badge visual para status do evento
class StatusBadge extends StatelessWidget {
  final EventStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: config.color,
          height: 1.2,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(EventStatus status) {
    switch (status) {
      case EventStatus.agendado:
        return _StatusConfig(Colors.blue);
      case EventStatus.emAndamento:
        return _StatusConfig(Colors.orange);
      case EventStatus.finalizando:
        return _StatusConfig(Colors.amber);
      case EventStatus.concluido:
        return _StatusConfig(Colors.green);
      case EventStatus.cancelado:
        return _StatusConfig(Colors.grey);
    }
  }
}

class _StatusConfig {
  final Color color;
  _StatusConfig(this.color);
}
