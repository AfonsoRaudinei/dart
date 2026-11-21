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

  /// Publicação original quando este registro é republicação (`source_case_id`).
  final String? sourceCaseId;

  /// Polígono `drawings` (`tipo = teste`) que é a área deste case (ADR-064).
  final String? drawingId;

  /// Execução de teste selecionada na avaliação (referência; snapshot no case).
  final String? testeExecucaoId;

  /// Início da janela pública (`liberado_em`). Nulo = pin só do autor.
  final DateTime? liberadoEm;

  /// Fim da janela pública (`publico_ate`).
  final DateTime? publicoAte;

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
    this.sourceCaseId,
    this.drawingId,
    this.testeExecucaoId,
    this.liberadoEm,
    this.publicoAte,
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
      sourceCaseId: json['source_case_id'] as String?,
      drawingId: json['drawing_id'] as String?,
      testeExecucaoId: json['teste_execucao_id'] as String?,
      liberadoEm: json['liberado_em'] != null
          ? DateTime.parse(json['liberado_em'] as String)
          : null,
      publicoAte: json['publico_ate'] != null
          ? DateTime.parse(json['publico_ate'] as String)
          : null,
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
      if (sourceCaseId != null) 'source_case_id': sourceCaseId,
      if (drawingId != null) 'drawing_id': drawingId,
      if (testeExecucaoId != null) 'teste_execucao_id': testeExecucaoId,
      if (liberadoEm != null) 'liberado_em': liberadoEm!.toIso8601String(),
      if (publicoAte != null) 'publico_ate': publicoAte!.toIso8601String(),
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

  MarketingCase copyWith({
    String? id,
    CaseTipo? tipo,
    PlanoMarketing? visibilidade,
    double? lat,
    double? lng,
    String? localizacaoTexto,
    String? produtorFazenda,
    String? produtoUtilizado,
    DateTime? dataCase,
    double? produtividadeValor,
    ProdutividadeUnidade? produtividadeUnidade,
    String? nomeVendedor,
    String? telefoneVendedor,
    String? descricao,
    String? fotoPrincipalUrl,
    double? quantidadeProduzida,
    double? prodSemProduto,
    double? prodComProduto,
    String? unidadeProdutividade,
    double? custoProdutoPorHa,
    double? valorGrao,
    String? clientId,
    String? ownerUserId,
    String? sourceCaseId,
    bool clearSourceCaseId = false,
    String? drawingId,
    bool clearDrawingId = false,
    String? testeExecucaoId,
    bool clearTesteExecucaoId = false,
    DateTime? liberadoEm,
    bool clearLiberadoEm = false,
    DateTime? publicoAte,
    bool clearPublicoAte = false,
    String? fotoAntesUrl,
    String? fotoDepoisUrl,
    String? ganhoProdutividade,
    String? economiaGerada,
    String? parametrosJson,
    String? nomeTalhao,
    double? tamanhoHa,
    List<AvaliacaoBloco>? avaliacoes,
    String? avaliacoesJson,
    RoiBloco? roi,
    String? conclusao,
    String? conclusaoTecnica,
    bool? ativo,
    MarketingCaseStatus? status,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? syncStatus,
    DateTime? deletadoEm,
    bool clearDeletadoEm = false,
  }) {
    return MarketingCase(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      visibilidade: visibilidade ?? this.visibilidade,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      localizacaoTexto: localizacaoTexto ?? this.localizacaoTexto,
      produtorFazenda: produtorFazenda ?? this.produtorFazenda,
      produtoUtilizado: produtoUtilizado ?? this.produtoUtilizado,
      dataCase: dataCase ?? this.dataCase,
      produtividadeValor: produtividadeValor ?? this.produtividadeValor,
      produtividadeUnidade:
          produtividadeUnidade ?? this.produtividadeUnidade,
      nomeVendedor: nomeVendedor ?? this.nomeVendedor,
      telefoneVendedor: telefoneVendedor ?? this.telefoneVendedor,
      descricao: descricao ?? this.descricao,
      fotoPrincipalUrl: fotoPrincipalUrl ?? this.fotoPrincipalUrl,
      quantidadeProduzida: quantidadeProduzida ?? this.quantidadeProduzida,
      prodSemProduto: prodSemProduto ?? this.prodSemProduto,
      prodComProduto: prodComProduto ?? this.prodComProduto,
      unidadeProdutividade:
          unidadeProdutividade ?? this.unidadeProdutividade,
      custoProdutoPorHa: custoProdutoPorHa ?? this.custoProdutoPorHa,
      valorGrao: valorGrao ?? this.valorGrao,
      clientId: clientId ?? this.clientId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      sourceCaseId:
          clearSourceCaseId ? null : (sourceCaseId ?? this.sourceCaseId),
      drawingId: clearDrawingId ? null : (drawingId ?? this.drawingId),
      testeExecucaoId: clearTesteExecucaoId
          ? null
          : (testeExecucaoId ?? this.testeExecucaoId),
      liberadoEm: clearLiberadoEm ? null : (liberadoEm ?? this.liberadoEm),
      publicoAte: clearPublicoAte ? null : (publicoAte ?? this.publicoAte),
      fotoAntesUrl: fotoAntesUrl ?? this.fotoAntesUrl,
      fotoDepoisUrl: fotoDepoisUrl ?? this.fotoDepoisUrl,
      ganhoProdutividade: ganhoProdutividade ?? this.ganhoProdutividade,
      economiaGerada: economiaGerada ?? this.economiaGerada,
      parametrosJson: parametrosJson ?? this.parametrosJson,
      nomeTalhao: nomeTalhao ?? this.nomeTalhao,
      tamanhoHa: tamanhoHa ?? this.tamanhoHa,
      avaliacoes: avaliacoes ?? this.avaliacoes,
      avaliacoesJson: avaliacoesJson ?? this.avaliacoesJson,
      roi: roi ?? this.roi,
      conclusao: conclusao ?? this.conclusao,
      conclusaoTecnica: conclusaoTecnica ?? this.conclusaoTecnica,
      ativo: ativo ?? this.ativo,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      syncStatus: syncStatus ?? this.syncStatus,
      deletadoEm: clearDeletadoEm ? null : (deletadoEm ?? this.deletadoEm),
    );
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
