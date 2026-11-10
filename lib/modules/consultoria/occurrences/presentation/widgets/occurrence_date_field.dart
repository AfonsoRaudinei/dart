import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

/// Campo de data do formulário de ocorrência.
///
/// Mesmo visual de `OccurrenceDarkField`: vazio mostra [label] como
/// placeholder; preenchido mantém [label] pequeno acima da data.
class OccurrenceDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? helperText;

  const OccurrenceDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.helperText,
  });

  static String format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pick(BuildContext context) async {
    final first = firstDate ?? DateTime(2010);
    final last = lastDate ?? DateTime.now().add(const Duration(days: 365));
    var initial = value ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final radius = BorderRadius.circular(v.cardRadius);
    final selected = value;
    final helper = helperText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: radius,
          onTap: () => _pick(context),
          child: InputDecorator(
            isEmpty: selected == null,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: v.inputHint, fontSize: 13),
              filled: true,
              fillColor: v.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: v.inputHint,
              ),
              suffixIcon: selected == null
                  ? null
                  : IconButton(
                      tooltip: 'Limpar $label',
                      icon: Icon(Icons.clear, size: 16, color: v.inputHint),
                      onPressed: () => onChanged(null),
                    ),
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: v.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: v.cardBorder),
              ),
            ),
            child: Text(
              selected == null ? '' : format(selected),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: v.inputText, fontSize: 14),
            ),
          ),
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              helper,
              style: TextStyle(color: v.subtitleColor, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
