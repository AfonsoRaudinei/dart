import 'enums/perfil_atendimento_tipo.dart';

/// Copy de venda de um perfil de atendimento. Dart puro, sem Flutter.
class PerfilAtendimentoAbordagem {
  const PerfilAtendimentoAbordagem({
    required this.tipo,
    required this.essencia,
    required this.resumo,
    required this.comoVender,
    required this.scriptAbertura,
    required this.evite,
    required this.abordagemIdeal,
    required this.prova,
    required this.fechamento,
    this.fechamentoAdequado,
    this.estruturaProposta,
  });

  final PerfilAtendimentoTipo tipo;

  /// Parágrafo completo da essência.
  final String essencia;

  /// Primeira frase da essência, usada no resultado do diagnóstico.
  final String resumo;

  final List<String> comoVender;
  final String scriptAbertura;
  final List<String> evite;
  final String abordagemIdeal;
  final String prova;
  final String fechamento;

  /// Só afável e expressivo.
  final String? fechamentoAdequado;

  /// Só analítico: 10 itens, nesta ordem.
  final List<String>? estruturaProposta;
}

const String kPrincipioAbordagem =
    'Para aumentar a efetividade, sua venda deve mudar de ritmo, linguagem, prova e fechamento conforme o perfil do cliente.\n'
    'Não venda do jeito que você prefere falar. Venda do jeito que o cliente prefere decidir.';

const List<String> kDicasConversao = [
  'Diagnostique antes de vender: faça perguntas sobre situação, objetivo, urgência, orçamento, decisores e experiências anteriores.',
  'Espelhe o ritmo do cliente: fale mais rápido e direto com o pragmático; mais pausado e detalhado com o analítico; mais caloroso com o afável; mais dinâmico com o expressivo.',
  'Use uma linguagem orientada a benefício: em vez de “meu serviço tem consultoria mensal”, diga “você terá um plano claro para reduzir [problema] e alcançar [resultado]”.',
  'Sempre confirme por escrito: principalmente para analíticos e pragmáticos, proposta, escopo, prazos e responsabilidades evitam mal-entendidos.',
  'Trate objeção como informação: pergunte “O que exatamente faria essa proposta fazer mais sentido para você?” em vez de tentar vencer a objeção na força.',
  'Adapte a proposta, não a sua ética: você pode mudar a forma de comunicar, mas nunca deve prometer o que não pode entregar.',
  'Faça um follow-up com propósito: não pergunte apenas “decidiu?”. Envie um resumo, uma resposta à dúvida dele ou um próximo passo útil.',
];

const String _fraseAfavelPragmatico =
    'Vou acompanhar você de perto e manter tudo simples: etapas claras, prazo definido e foco no resultado que você precisa.';

const String _fraseAnaliticoAfavel =
    'Vou te apresentar os dados, as etapas e as garantias com total clareza. E, durante todo o processo, você terá um acompanhamento próximo para tirar dúvidas e se sentir seguro em cada decisão.';

const List<String> _passosAfavelPragmatico = [
  'Crie conexão e segurança.',
  'Faça perguntas sobre a situação e o objetivo.',
  'Apresente uma solução clara e prática.',
  'Mostre prazo, investimento e resultado.',
  'Explique o acompanhamento.',
  'Ofereça um próximo passo simples.',
];

const PerfilAtendimentoAbordagem _pragmatico = PerfilAtendimentoAbordagem(
  tipo: PerfilAtendimentoTipo.pragmatico,
  essencia:
      'O pragmático quer entender rapidamente o problema, a solução, o custo, o prazo e o resultado. Ele se irrita com conversa longa, detalhes excessivos no início e falta de clareza.',
  resumo:
      'O pragmático quer entender rapidamente o problema, a solução, o custo, o prazo e o resultado.',
  comoVender: [
    'Comece pelo resultado: “Isso vai resolver o seu problema em X tempo, com este investimento.”',
    'Use frases curtas, objetivas e sem rodeios.',
    'Apresente no máximo 2 ou 3 opções, para que ele escolha sem se sentir perdido.',
    'Mostre o próximo passo com clareza: “Posso iniciar na segunda-feira” ou “Posso enviar a proposta hoje até as 18h.”',
    'Use provas rápidas: casos parecidos, resultados anteriores e prazos realistas.',
    'Dê a ele a sensação de controle: pergunte “Qual dessas opções faz mais sentido para você?”',
  ],
  scriptAbertura:
      'Vou ser direto: pelo que você me contou, seu principal desafio é [problema]. A solução que costuma funcionar melhor é [solução], porque entrega [resultado concreto]. Posso te mostrar em 3 minutos como isso funcionaria no seu caso?',
  evite: [
    'Apresentar 10 benefícios antes de explicar o resultado.',
    'Falar de teoria, metodologia ou detalhes técnicos sem necessidade.',
    'Deixar o próximo passo indefinido.',
  ],
  abordagemIdeal: 'Direto, rápido e orientado a resultado',
  prova: 'Casos rápidos, prazos e resultados concretos',
  fechamento: 'Qual opção você prefere: A ou B?',
);

const PerfilAtendimentoAbordagem _analitico = PerfilAtendimentoAbordagem(
  tipo: PerfilAtendimentoTipo.analitico,
  essencia:
      'O analítico é o perfil mais próximo do calculista. Ele quer dados, comparativos, riscos, garantias, processo e justificativas antes de decidir. Não confunda cautela com falta de interesse: ele está avaliando se sua proposta é consistente.',
  resumo: 'O analítico é o perfil mais próximo do calculista.',
  comoVender: [
    'Apresente uma proposta estruturada: diagnóstico, solução, etapas, prazo, investimento, indicadores e garantias.',
    'Use números, exemplos, referências e evidências sempre que possível.',
    'Explique não apenas o que será feito, mas por que aquela é a melhor escolha.',
    'Antecipe objeções: “Você pode estar se perguntando se o resultado é garantido; aqui está o que podemos medir e como acompanhar.”',
    'Dê tempo para análise, mas mantenha um prazo de acompanhamento definido.',
    'Confirme tudo por escrito: e-mail, proposta, plano de ação e próximos passos.',
  ],
  scriptAbertura:
      'Antes de falar de preço, quero entender seus critérios de decisão. Quais informações você considera indispensáveis para comparar essa solução com outras opções?',
  evite: [
    'Prometer resultados sem base.',
    'Pressionar por uma decisão imediata.',
    'Responder “depende” sem explicar os critérios.',
    'Usar linguagem emocional como principal argumento.',
  ],
  abordagemIdeal: 'Detalhado, lógico e seguro',
  prova: 'Números, comparativos, garantias e referências',
  fechamento: 'Quais informações faltam para você decidir com segurança?',
  estruturaProposta: [
    'Situação atual e problema.',
    'Causa provável.',
    'Solução recomendada.',
    'Etapas e responsáveis.',
    'Prazo.',
    'Investimento.',
    'Resultados esperados e indicadores.',
    'Riscos, limitações e garantias.',
    'Provas: casos, depoimentos ou referências.',
    'Próximo passo.',
  ],
);

const PerfilAtendimentoAbordagem _afavel = PerfilAtendimentoAbordagem(
  tipo: PerfilAtendimentoTipo.afavel,
  essencia:
      'O afável compra primeiro confiança, segurança e relacionamento. Ele precisa sentir que será bem atendido, que você entende a situação dele e que não ficará sozinho durante o processo.',
  resumo: 'O afável compra primeiro confiança, segurança e relacionamento.',
  comoVender: [
    'Comece ouvindo mais do que falando.',
    'Use perguntas abertas: “Como isso tem afetado você no dia a dia?”, “O que seria uma solução ideal para você?”',
    'Mostre empatia antes de apresentar a solução.',
    'Explique como será o acompanhamento, quem estará disponível e como ele poderá tirar dúvidas.',
    'Use depoimentos, indicações e histórias de clientes semelhantes.',
    'Reduza o risco percebido: garantia, suporte, acompanhamento e comunicação frequente.',
    'Não force o fechamento; conduza com segurança e ofereça uma decisão simples.',
  ],
  scriptAbertura:
      'Antes de eu apresentar qualquer solução, quero entender bem a sua situação. O que mais preocupa você nesse momento e qual seria o resultado ideal para você?',
  evite: [
    'Ser frio, apressado ou excessivamente técnico.',
    'Usar pressão, urgência artificial ou argumentos agressivos.',
    'Tratar a venda como uma simples transação.',
    'Ignorar dúvidas emocionais, como medo de errar ou insegurança.',
  ],
  abordagemIdeal: 'Humano, próximo e sem pressão',
  prova: 'Depoimentos, indicações e acompanhamento',
  fechamento:
      'Podemos começar com uma etapa inicial e você acompanha o resultado?',
  fechamentoAdequado:
      'Com base no que você me contou, acredito que essa é a melhor opção para você. Podemos começar com uma etapa inicial, sem compromisso maior, para você acompanhar de perto como funciona o nosso atendimento. Faz sentido?',
);

const PerfilAtendimentoAbordagem _expressivo = PerfilAtendimentoAbordagem(
  tipo: PerfilAtendimentoTipo.expressivo,
  essencia:
      'O expressivo decide com mais energia, emoção, visão e reconhecimento. Ele se conecta com histórias, possibilidades, novidades e com a sensação de estar fazendo algo diferenciado.',
  resumo:
      'O expressivo decide com mais energia, emoção, visão e reconhecimento.',
  comoVender: [
    'Comece com uma visão positiva do futuro: “Imagine como seria ter esse problema resolvido e poder focar no que realmente importa.”',
    'Use histórias, exemplos visuais e casos de sucesso.',
    'Destaque diferenciais, inovação, exclusividade e impacto.',
    'Mantenha energia, entusiasmo e linguagem acessível.',
    'Mostre o resultado antes de entrar em detalhes técnicos.',
    'Depois de despertar o interesse, organize os detalhes por escrito para dar segurança à decisão.',
    'Envolva a pessoa: pergunte o que ela gostaria de alcançar e como gostaria de ser reconhecida pelo resultado.',
  ],
  scriptAbertura:
      'Imagine daqui a alguns meses, com esse problema resolvido e você tendo mais tempo, mais tranquilidade e melhores resultados. É exatamente para isso que essa solução foi pensada. Quer que eu te mostre como isso poderia funcionar no seu caso?',
  evite: [
    'Abrir a conversa com planilhas, cláusulas e detalhes técnicos.',
    'Falar de forma monótona ou demorada.',
    'Ignorar o lado emocional da decisão.',
    'Prometer resultados exagerados apenas para gerar entusiasmo.',
  ],
  abordagemIdeal: 'Inspirador, visual e energético',
  prova: 'Histórias, casos de sucesso e visão do futuro',
  fechamento: 'Qual oportunidade você gostaria de conquistar primeiro?',
  fechamentoAdequado:
      'Essa solução pode colocar você à frente e criar um resultado visível rapidamente. Qual das opções você gostaria de começar primeiro?',
);

PerfilAtendimentoAbordagem abordagemDe(PerfilAtendimentoTipo tipo) {
  switch (tipo) {
    case PerfilAtendimentoTipo.pragmatico:
      return _pragmatico;
    case PerfilAtendimentoTipo.analitico:
      return _analitico;
    case PerfilAtendimentoTipo.afavel:
      return _afavel;
    case PerfilAtendimentoTipo.expressivo:
      return _expressivo;
  }
}

/// Frase literal só em afável + pragmático e analítico + afável.
String? fraseCombinacao(
  PerfilAtendimentoTipo dominante,
  PerfilAtendimentoTipo? secundario,
) {
  if (secundario == null) return null;
  if (dominante == PerfilAtendimentoTipo.afavel &&
      secundario == PerfilAtendimentoTipo.pragmatico) {
    return _fraseAfavelPragmatico;
  }
  if (dominante == PerfilAtendimentoTipo.analitico &&
      secundario == PerfilAtendimentoTipo.afavel) {
    return _fraseAnaliticoAfavel;
  }
  return null;
}

/// Seis passos só para afável + pragmático.
List<String>? passosCombinacao(
  PerfilAtendimentoTipo dominante,
  PerfilAtendimentoTipo? secundario,
) {
  if (dominante == PerfilAtendimentoTipo.afavel &&
      secundario == PerfilAtendimentoTipo.pragmatico) {
    return _passosAfavelPragmatico;
  }
  return null;
}
