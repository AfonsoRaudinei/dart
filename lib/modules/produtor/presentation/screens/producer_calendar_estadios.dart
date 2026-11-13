import 'package:flutter/material.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/domain/soy_phenology.dart';

class ProducerCalendarEstadios extends StatelessWidget {
  const ProducerCalendarEstadios({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      key: const Key('producer-calendar-estadios'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, kFabSafeArea),
      itemCount: kEstadios.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'O que observar em cada fase da soja.',
            style: theme.textTheme.bodyMedium,
          );
        }
        final estadio = kEstadios[index - 1];
        return Card(
          child: ExpansionTile(
            title: Text(estadio.name),
            subtitle: Text(estadio.description),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'A partir de ${estadio.dap} dias após a emergência',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              for (final note in estadio.attention)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(note),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
