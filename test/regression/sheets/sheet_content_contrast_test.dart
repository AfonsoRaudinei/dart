import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contraste do conteúdo de sheets nos 3 temas (Verde · Azul · Black).
///
/// `isIos ? <skin iOS> : Colors.white…` só conhece Azul e Black: no Verde o
/// fundo do sheet é claro e o texto some. O conteúdo destes arquivos deve
/// resolver cores via `SoloForteSheetVisuals.of(context)`.
const _guardedFiles = <String>[
  'lib/ui/components/map/widgets/map_mark_sheet.dart',
  'lib/ui/components/map/widgets/map_offline_widgets.dart',
  'lib/ui/components/map/widgets/publication_actions_bottom_sheet.dart',
  'lib/ui/components/map/widgets/location_export_bottom_sheet.dart',
  'lib/ui/components/map/map_offline_download_sheet.dart',
  'lib/ui/components/map/map_municipality_search_sheet.dart',
  'lib/ui/components/map/map_coordinate_search_sheet.dart',
  'lib/ui/components/map/map_go_to_local_sheet.dart',
  'lib/ui/components/map/map_layers_sheet.dart',
  'lib/ui/components/map/map_bottom_sheet.dart',
  'lib/ui/screens/map/widgets/active_visit_sheet.dart',
  'lib/modules/map/presentation/widgets/visit_sheet.dart',
  'lib/modules/map/presentation/widgets/visit_active_card.dart',
  'lib/modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart',
  'lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart',
  'lib/modules/consultoria/occurrences/presentation/widgets/occurrence_andamento_section.dart',
  'lib/modules/consultoria/occurrences/presentation/widgets/occurrence_client_selector.dart',
  'lib/modules/consultoria/occurrences/presentation/widgets/occurrence_filters.dart',
  'lib/modules/marketing/presentation/screens/novo_case_sheet.dart',
  'lib/modules/marketing/presentation/widgets/marketing_case_sheet.dart',
  'lib/modules/marketing/presentation/widgets/edit_case_sheet.dart',
  'lib/modules/marketing/presentation/widgets/novo_case_resultado_section.dart',
  'lib/modules/marketing/presentation/widgets/novo_case_publicar_button.dart',
  'lib/modules/marketing/presentation/widgets/novo_case_header.dart',
  'lib/modules/marketing/presentation/widgets/novo_case_form_helpers.dart',
  'lib/modules/marketing/presentation/widgets/marketing_client_selector.dart',
  'lib/modules/marketing/presentation/widgets/foto_picker_widget.dart',
  'lib/modules/marketing/presentation/widgets/conclusao_bloco_widget.dart',
  'lib/modules/marketing/presentation/widgets/case_selectors_widget.dart',
  'lib/modules/marketing/presentation/widgets/marketing_comparativo_read_only_section.dart',
  'lib/modules/marketing/presentation/widgets/marketing_case_resultado_read_only_section.dart',
  'lib/modules/marketing/presentation/widgets/avaliacao_card.dart',
];

/// Exceções legítimas: `arquivo` → trechos exatos (whitespace normalizado).
const _allowed = <String, List<String>>{
  // Card de ROI pinta fundo verde-escuro fixo (#123D2A) fora do Azul.
  'lib/modules/marketing/presentation/widgets/novo_case_resultado_section.dart':
      [
        'isIos ? SoloForteSheetSkinIos.titleColor : Colors.white',
        'isIos ? SoloForteSheetSkinIos.titleColor : Colors.white',
      ],
};

/// Ternário cujo condicional é `isIos`/`soloForteSheetIsIos(...)` e o ramo
/// `else` é `Colors.white*`, `Colors.black*` ou `SoloForteSheetTokens.titleColor`.
final _bifurcation = RegExp(
  r'(?:\bisIos\b|soloForteSheetIsIos\([^)]*\))\s*\?\s*[^;?,{}]+?:\s*\(?\s*'
  r'(?:Colors\.(?:white|black)\w*|SoloForteSheetTokens\.titleColor)\b',
);

String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  group('Contraste de conteúdo de sheet (Verde/Azul/Black)', () {
    for (final path in _guardedFiles) {
      test('$path não bifurca cor só por isIos com branco/preto fixo', () {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'arquivo ausente: $path');

        final source = file.readAsStringSync();
        final remaining = List<String>.of(_allowed[path] ?? const []);
        final violations = <String>[];

        for (final match in _bifurcation.allMatches(source)) {
          final snippet = _normalize(match.group(0)!);
          if (remaining.remove(snippet)) continue;
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          violations.add('$path:$line → $snippet');
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Use SoloForteSheetVisuals.of(context) (titleColor, '
              'subtitleColor, dividerColor, ctaText…) em vez de '
              '`isIos ? … : Colors.white/black`.',
        );
      });
    }

    test('whitelist não guarda exceções que já não existem', () {
      for (final entry in _allowed.entries) {
        final source = _normalize(File(entry.key).readAsStringSync());
        for (final snippet in entry.value) {
          expect(source, contains(snippet), reason: '${entry.key}: $snippet');
        }
      }
    });
  });
}
