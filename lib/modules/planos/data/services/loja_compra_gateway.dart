class LojaProduto {
  final String productId;
  final String titulo;
  final String preco;
  final String prazo;

  const LojaProduto({
    required this.productId,
    required this.titulo,
    required this.preco,
    required this.prazo,
  });
}

/// Por que a loja não devolveu nenhum produto de plano.
enum LojaMotivoIndisponivel {
  lojaFechada,
  produtosNaoEncontrados,
  erroConsulta,
}

class LojaVitrine {
  final bool disponivel;
  final List<LojaProduto> produtos;
  final LojaMotivoIndisponivel? motivoIndisponivel;

  const LojaVitrine({
    required this.disponivel,
    required this.produtos,
    this.motivoIndisponivel,
  });

  static const indisponivel = LojaVitrine(
    disponivel: false,
    produtos: [],
    motivoIndisponivel: LojaMotivoIndisponivel.lojaFechada,
  );
}

class LojaCompraAviso {
  final String mensagem;
  final bool erro;
  final bool concedido;

  const LojaCompraAviso({
    required this.mensagem,
    this.erro = false,
    this.concedido = false,
  });
}

abstract class LojaCompraGateway {
  Future<LojaVitrine> carregar();
  Future<void> comprar(String productId);
  Future<void> restaurar();
  Stream<LojaCompraAviso> get avisos;
  void dispose();
}
