import '../enums/plano_marketing.dart';

class MarketingPin {
  final String id;
  final String nomeProduto;
  final String imagemUrl;
  final double roiPercent;
  final PlanoMarketing plano;
  final double lat;
  final double lng;
  final bool ativo;
  final DateTime criadoEm;
  final DateTime? expiraEm;

  const MarketingPin({
    required this.id,
    required this.nomeProduto,
    required this.imagemUrl,
    required this.roiPercent,
    required this.plano,
    required this.lat,
    required this.lng,
    required this.ativo,
    required this.criadoEm,
    this.expiraEm,
  });

  factory MarketingPin.fromJson(Map<String, dynamic> json) {
    return MarketingPin(
      id: json['id'] as String,
      nomeProduto: json['nome_produto'] as String,
      imagemUrl: json['imagem_url'] as String,
      roiPercent: (json['roi_percent'] as num).toDouble(),
      plano: PlanoMarketing.fromString(json['plano'] as String),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      ativo: json['ativo'] as bool,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      expiraEm: json['expira_em'] != null
          ? DateTime.parse(json['expira_em'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_produto': nomeProduto,
      'imagem_url': imagemUrl,
      'roi_percent': roiPercent,
      'plano': plano.toValue(),
      'lat': lat,
      'lng': lng,
      'ativo': ativo,
      'criado_em': criadoEm.toIso8601String(),
      'expira_em': expiraEm?.toIso8601String(),
    };
  }
}
