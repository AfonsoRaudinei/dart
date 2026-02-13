import 'package:flutter/material.dart';
import '../../domain/enums/event_type.dart';

/// Badge visual para tipo do evento
class EventTypeBadge extends StatelessWidget {
  final EventType type;
  final double size;

  const EventTypeBadge({
    super.key,
    required this.type,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        type.icon,
        style: TextStyle(
          fontSize: size * 0.5,
          height: 1,
        ),
      ),
    );
  }

  Color _getTypeColor(EventType type) {
    switch (type) {
      case EventType.visitaTecnica:
        return Colors.blue;
      case EventType.aplicacao:
        return Colors.cyan;
      case EventType.consultoria:
        return Colors.purple;
      case EventType.colheita:
        return Colors.amber;
      case EventType.manutencao:
        return Colors.orange;
      case EventType.reuniao:
        return Colors.indigo;
      case EventType.lembrete:
        return Colors.teal;
      case EventType.personalizado:
        return Colors.pink;
    }
  }
}
