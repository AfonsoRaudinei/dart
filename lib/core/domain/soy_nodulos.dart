/// Avaliação de nódulos de soja (categoria "Nódulos" da ocorrência).
///
/// Guardada em `metricas_json` como `{"nodulos": {chave: 1..3}}` (0 = não
/// informado), sem coluna nova. Compartilhado entre formulário, lista,
/// detalhe e relatório HTML.
library;

const String kNodulosCategory = 'nodulos';

const String kNodulosQuantidade = 'quantidade';
const String kNodulosCor = 'cor';
const String kNodulosDistribuicao = 'distribuicao';
const String kNodulosAvaliacao = 'avaliacao';

/// Chaves na ordem em que aparecem no formulário.
const List<String> kNodulosKeys = [
  kNodulosQuantidade,
  kNodulosCor,
  kNodulosDistribuicao,
  kNodulosAvaliacao,
];

const Map<String, String> kNodulosTitles = {
  kNodulosQuantidade: 'Nódulos por planta',
  kNodulosCor: 'Cor por dentro',
  kNodulosDistribuicao: 'Onde estão',
  kNodulosAvaliacao: 'Avaliação geral',
};

/// Opções por chave; o valor salvo é o índice + 1.
const Map<String, List<String>> kNodulosOptions = {
  kNodulosQuantidade: ['Poucos (<10)', 'Bom (10–30)', 'Muito (>30)'],
  kNodulosCor: ['Rosa/vermelho', 'Branco', 'Verde/cinza'],
  kNodulosDistribuicao: ['Raiz principal', 'Raízes laterais', 'Mista'],
  kNodulosAvaliacao: ['Bom', 'Médio', 'Ruim'],
};

bool isNodulosMetric(String key) => kNodulosOptions.containsKey(key);

/// Texto da opção salva ou null se não informada/inválida.
String? nodulosValueLabel(String key, Object? value) {
  final options = kNodulosOptions[key];
  final index = value is num ? value.toInt() - 1 : -1;
  if (options == null || index < 0 || index >= options.length) return null;
  return options[index];
}
