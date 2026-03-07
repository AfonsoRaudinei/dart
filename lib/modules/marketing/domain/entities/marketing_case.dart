import '../enums/case_tipo.dart';
import '../enums/plano_marketing.dart';
import '../enums/produtividade_unidade.dart';
import '../enums/marketing_case_status.dart';
import 'avaliacao_bloco.dart';
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

  // Opcionais
  final double? produtividadeValor;
  final ProdutividadeUnidade? produtividadeUnidade;
  final String? nomeVendedor;
  final String? telefoneVendedor;
  final String? descricao;

  // Campos de Resultado
  final String? fotoPrincipalUrl;
  final double? quantidadeProduzida;

  // Campos de Antes/Depois
  final String? fotoAntesUrl;
  final String? fotoDepoisUrl;
  final String? ganhoProdutividade;
  final String? economiaGerada;

  // Campos de Avaliacao
  final String? nomeTalhao;
  final double? tamanhoHa;
  final List<AvaliacaoBloco> avaliacoes;
  final RoiBloco? roi;
  final String? conclusao;

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
    this.produtividadeValor,
    this.produtividadeUnidade,
    this.nomeVendedor,
    this.telefoneVendedor,
    this.descricao,
    this.fotoPrincipalUrl,
    this.quantidadeProduzida,
    this.fotoAntesUrl,
    this.fotoDepoisUrl,
    this.ganhoProdutividade,
    this.economiaGerada,
    this.nomeTalhao,
    this.tamanhoHa,
    this.avaliacoes = const [],
    this.roi,
    this.conclusao,
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
      fotoAntesUrl: json['foto_antes_url'] as String?,
      fotoDepoisUrl: json['foto_depois_url'] as String?,
      ganhoProdutividade: json['ganho_produtividade'] as String?,
      economiaGerada: json['economia_gerada'] as String?,
      nomeTalhao: json['nome_talhao'] as String?,
      tamanhoHa: (json['tamanho_ha'] as num?)?.toDouble(),
      avaliacoes: json['avaliacoes'] != null
          ? (json['avaliacoes'] as List<dynamic>)
                .map((e) => AvaliacaoBloco.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      roi: (json['roi_investimento'] != null) ? RoiBloco.fromJson(json) : null,
      conclusao: json['conclusao'] as String?,
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
      'produtividade_valor': produtividadeValor,
      'produtividade_unidade': produtividadeUnidade?.toValue(),
      'nome_vendedor': nomeVendedor,
      'telefone_vendedor': telefoneVendedor,
      'descricao': descricao,
      'foto_principal_url': fotoPrincipalUrl,
      'quantidade_produzida': quantidadeProduzida,
      'foto_antes_url': fotoAntesUrl,
      'foto_depois_url': fotoDepoisUrl,
      'ganho_produtividade': ganhoProdutividade,
      'economia_gerada': economiaGerada,
      'nome_talhao': nomeTalhao,
      'tamanho_ha': tamanhoHa,
      // avaliacoes sao filhas em tabela a parte, mas ficam no objeto na memoria
      if (roi != null) ...roi!.toJson(),
      'conclusao': conclusao,
      'ativo': ativo,
      'status': status.toValue(),
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'sync_status': syncStatus,
      'deletado_em': deletadoEm?.toIso8601String(),
    };
  }
}
