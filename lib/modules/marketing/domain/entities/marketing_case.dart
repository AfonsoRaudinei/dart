import 'dart:convert';

import '../enums/case_tipo.dart';
import '../enums/plano_marketing.dart';
import '../enums/produtividade_unidade.dart';
import '../enums/marketing_case_status.dart';
import 'avaliacao_bloco.dart';
import 'avaliacao_item.dart';
import 'marketing_roi_calculation.dart';
import 'parametro_comparativo.dart';
import 'roi_bloco.dart';

class MarketingCase {
  final String id;
  final CaseTipo tipo;
  final PlanoMarketing visibilidade;
  final double lat;
  final double lng;
  final String localizacaoTexto;
  final String produtorFazenda;
  final String produtoUtilizado;
  final DateTime? dataCase;

  // Opcionais
  final double? produtividadeValor;
  final ProdutividadeUnidade? produtividadeUnidade;
  final String? nomeVendedor;
  final String? telefoneVendedor;
  final String? descricao;

  // Campos de Resultado
  final String? fotoPrincipalUrl;
  final double? quantidadeProduzida;
  final double? prodSemProduto;
  final double? prodComProduto;
  final String? unidadeProdutividade;
  final double? custoProdutoPorHa;
  final double? valorGrao;
  final String? clientId;

  /// Autoria remota (`marketing_cases.user_id`). Usado no ACL do produtor.
  final String? ownerUserId;

  // Campos de Antes/Depois
  final String? fotoAntesUrl;
  final String? fotoDepoisUrl;
  final String? ganhoProdutividade;
  final String? economiaGerada;
  final String? parametrosJson;

  // Campos de Avaliacao
  final String? nomeTalhao;
  final double? tamanhoHa;
  final List<AvaliacaoBloco> avaliacoes;
  final String? avaliacoesJson;
  final RoiBloco? roi;
  final String? conclusao;
  final String? conclusaoTecnica;

  // Sync e Status
  final bool ativo;
  final MarketingCaseStatus status;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String syncStatus;
  final DateTime? deletadoEm;

  const MarketingCase({
    required this.id,
    required this.tipo,
    required this.visibilidade,
    required this.lat,
    required this.lng,
    required this.localizacaoTexto,
    required this.produtorFazenda,
    required this.produtoUtilizado,
    this.dataCase,
    this.produtividadeValor,
    this.produtividadeUnidade,
    this.nomeVendedor,
    this.telefoneVendedor,
    this.descricao,
    this.fotoPrincipalUrl,
    this.quantidadeProduzida,
    this.prodSemProduto,
    this.prodComProduto,
    this.unidadeProdutividade,
    this.custoProdutoPorHa,
    this.valorGrao,
    this.clientId,
    this.ownerUserId,
    this.fotoAntesUrl,
    this.fotoDepoisUrl,
    this.ganhoProdutividade,
    this.economiaGerada,
    this.parametrosJson,
    this.nomeTalhao,
    this.tamanhoHa,
    this.avaliacoes = const [],
    this.avaliacoesJson,
    this.roi,
    this.conclusao,
    this.conclusaoTecnica,
    this.ativo = true,
    this.status = MarketingCaseStatus.published,
    required this.criadoEm,
    required this.atualizadoEm,
    this.syncStatus = 'local_only',
    this.deletadoEm,
  });

  factory MarketingCase.fromJson(Map<String, dynamic> json) {
    return MarketingCase(
      id: json['id'] as String,
      tipo: CaseTipo.fromString(json['tipo'] as String),
      visibilidade: PlanoMarketing.fromString(json['visibilidade'] as String),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      localizacaoTexto: json['localizacao_texto'] as String,
      produtorFazenda: json['produtor_fazenda'] as String,
      produtoUtilizado: json['produto_utilizado'] as String,
      dataCase: json['data_case'] != null
          ? DateTime.parse(json['data_case'] as String)
          : null,
      produtividadeValor: (json['produtividade_valor'] as num?)?.toDouble(),
      produtividadeUnidade: json['produtividade_unidade'] != null
          ? ProdutividadeUnidade.fromString(
              json['produtividade_unidade'] as String,
            )
          : null,
      nomeVendedor: json['nome_vendedor'] as String?,
      telefoneVendedor: json['telefone_vendedor'] as String?,
      descricao: json['descricao'] as String?,
      fotoPrincipalUrl: json['foto_principal_url'] as String?,
      quantidadeProduzida: (json['quantidade_produzida'] as num?)?.toDouble(),
      prodSemProduto: (json['prod_sem_produto'] as num?)?.toDouble(),
      prodComProduto: (json['prod_com_produto'] as num?)?.toDouble(),
      unidadeProdutividade: json['unidade_produtividade'] as String?,
      custoProdutoPorHa: (json['custo_produto_por_ha'] as num?)?.toDouble(),
      valorGrao: (json['valor_grao'] as num?)?.toDouble(),
      clientId: json['client_id'] as String?,
      ownerUserId: json['user_id'] as String?,
      fotoAntesUrl: json['foto_antes_url'] as String?,
      fotoDepoisUrl: json['foto_depois_url'] as String?,
      ganhoProdutividade: json['ganho_produtividade'] as String?,
      economiaGerada: json['economia_gerada'] as String?,
      parametrosJson: json['parametros_json'] as String?,
      nomeTalhao: json['nome_talhao'] as String?,
      tamanhoHa: (json['tamanho_ha'] as num?)?.toDouble(),
      avaliacoes: json['avaliacoes'] != null
          ? (json['avaliacoes'] as List<dynamic>)
                .map((e) => AvaliacaoBloco.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      avaliacoesJson: json['avaliacoes_json'] as String?,
      roi: (json['roi_investimento'] != null) ? RoiBloco.fromJson(json) : null,
      conclusao: json['conclusao'] as String?,
      conclusaoTecnica: json['conclusao_tecnica'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      status: json['status'] != null
          ? MarketingCaseStatus.fromString(json['status'] as String)
          : MarketingCaseStatus.published,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: DateTime.parse(json['atualizado_em'] as String),
      syncStatus: json['sync_status'] as String? ?? 'local_only',
      deletadoEm: json['deletado_em'] != null
          ? DateTime.parse(json['deletado_em'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo.toValue(),
      'visibilidade': visibilidade.toValue(),
      'lat': lat,
      'lng': lng,
      'localizacao_texto': localizacaoTexto,
      'produtor_fazenda': produtorFazenda,
      'produto_utilizado': produtoUtilizado,
      'data_case': dataCase?.toIso8601String(),
      'produtividade_valor': produtividadeValor,
      'produtividade_unidade': produtividadeUnidade?.toValue(),
      'nome_vendedor': nomeVendedor,
      'telefone_vendedor': telefoneVendedor,
      'descricao': descricao,
      'foto_principal_url': fotoPrincipalUrl,
      'quantidade_produzida': quantidadeProduzida,
      'prod_sem_produto': prodSemProduto,
      'prod_com_produto': prodComProduto,
      'unidade_produtividade': unidadeProdutividade,
      'custo_produto_por_ha': custoProdutoPorHa,
      'valor_grao': valorGrao,
      'client_id': clientId,
      if (ownerUserId != null) 'user_id': ownerUserId,
      'foto_antes_url': fotoAntesUrl,
      'foto_depois_url': fotoDepoisUrl,
      'ganho_produtividade': ganhoProdutividade,
      'economia_gerada': economiaGerada,
      'parametros_json': parametrosJson,
      'nome_talhao': nomeTalhao,
      'tamanho_ha': tamanhoHa,
      // avaliacoes sao filhas em tabela a parte, mas ficam no objeto na memoria
      'avaliacoes_json': avaliacoesJson,
      if (roi != null) ...roi!.toJson(),
      'conclusao': conclusao,
      'conclusao_tecnica': conclusaoTecnica,
      'ativo': ativo,
      'status': status.toValue(),
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'sync_status': syncStatus,
      'deletado_em': deletadoEm?.toIso8601String(),
    };
  }

  MarketingRoiCalculation? computeRoi({double? areaTotal}) {
    final semProduto = prodSemProduto;
    final comProduto = prodComProduto;
    final custo = custoProdutoPorHa;
    final valor = valorGrao;
    final unidade = unidadeProdutividade;
    if (semProduto == null ||
        comProduto == null ||
        custo == null ||
        valor == null ||
        unidade == null) {
      return null;
    }

    final input = MarketingRoiInput(
      prodSemProduto: semProduto,
      prodComProduto: comProduto,
      unidadeProdutividade: unidade,
      custoProdutoPorHa: custo,
      valorGrao: valor,
      tamanhoHa: tamanhoHa,
      areaTotal: areaTotal,
    );
    if (!input.isComplete) return null;
    return MarketingRoiCalculation(input);
  }

  List<ParametroComparativo> get parametros {
    final raw = parametrosJson;
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                ParametroComparativo.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  double get mediaGanhoPercent {
    final lista = parametros;
    if (lista.isEmpty) return 0.0;
    final total = lista.fold<double>(0, (sum, item) => sum + item.deltaPercent);
    return total / lista.length;
  }

  List<AvaliacaoItem> get avaliacoesLivres {
    final raw = avaliacoesJson;
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => AvaliacaoItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
