import 'package:soloforte_app/modules/clima/domain/clima_dicas_agronomicas.dart';
import 'package:soloforte_app/modules/clima/domain/clima_fonte.dart';
import 'package:soloforte_app/modules/clima/domain/clima_weather_emoji.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';

/// Payload de compartilhamento para o módulo clima.
sealed class ClimaSharePayload {
  const ClimaSharePayload();

  ClimaFonte get fonte;

  String get cidade;
  String get previewTitle;
  String get previewSubtitle;
  String get previewEmoji;
  List<String> get previewChips;

  String? get previewCampoLinha;

  String buildWhatsAppMessage();
}

String climaShareRodape(ClimaFonte fonte) {
  final empresa = climaFonteEmpresa(fonte);
  if (empresa.isEmpty) return 'SoloForte';
  return 'SoloForte · Fonte: $empresa';
}

String climaChuvaFrase(double mm, {required bool inicioMaiusculo}) {
  if (mm <= 0) return inicioMaiusculo ? 'Sem chuva' : 'sem chuva';
  final valor = '${mm.toStringAsFixed(1)} mm';
  return inicioMaiusculo ? 'Chuva $valor' : valor;
}

String climaUvFrase(int uv) => uv <= 2 ? 'UV baixo' : 'UV $uv';

final class ClimaSharePayloadAtual extends ClimaSharePayload {
  const ClimaSharePayloadAtual(
    this.clima, {
    this.contextoSemanal = const [],
  });

  final ClimaAtual clima;
  final List<PrevisaoDiaria> contextoSemanal;

  @override
  ClimaFonte get fonte => clima.fonte;

  @override
  String get cidade => clima.cidade;

  @override
  String get previewTitle =>
      '${clima.temperatura.toStringAsFixed(0)}°C · ${clima.cidade}';

  @override
  String get previewSubtitle => clima.condicao;

  @override
  String get previewEmoji => climaWeatherEmoji(clima.condicaoCodigo);

  @override
  List<String> get previewChips => [
        'Umidade ${clima.umidade}%',
        'Vento ${clima.ventoVelocidade.toStringAsFixed(0)} km/h',
        'Chuva ${clima.precipitacao.toStringAsFixed(1)} mm',
        'UV ${clima.indiceUV}',
      ];

  @override
  String? get previewCampoLinha =>
      primeiraLinhaCampoCompartilhamento(contextoSemanal);

  @override
  String buildWhatsAppMessage() {
    final buffer = StringBuffer()
      ..writeln(clima.cidade)
      ..writeln(
        '${clima.temperatura.toStringAsFixed(0)}° agora. ${clima.condicao}.',
      )
      ..writeln(
        'Umidade ${clima.umidade}%. '
        '${climaChuvaFrase(clima.precipitacao, inicioMaiusculo: true)}. '
        'Vento ${clima.ventoVelocidade.toStringAsFixed(0)} km/h '
        '${clima.ventoDirecao}. ${climaUvFrase(clima.indiceUV)}.',
      )
      ..writeln()
      ..write(climaShareRodape(fonte));
    return buffer.toString();
  }
}

final class ClimaSharePayloadHoraria extends ClimaSharePayload {
  const ClimaSharePayloadHoraria({
    required this.cidadeLabel,
    required this.previsoes,
    required this.fonte,
    this.contextoSemanal = const [],
  });

  final String cidadeLabel;
  final List<PrevisaoHoraria> previsoes;
  @override
  final ClimaFonte fonte;
  final List<PrevisaoDiaria> contextoSemanal;

  @override
  String get cidade => cidadeLabel;

  @override
  String get previewTitle => 'Próximas 24h · $cidadeLabel';

  @override
  String get previewSubtitle {
    if (previsoes.isEmpty) return 'Sem dados horários';
    final first = previsoes.first;
    return '${first.hora.hour.toString().padLeft(2, '0')}h: '
        '${first.temperatura.toStringAsFixed(0)}° — ${first.condicao}';
  }

  @override
  String get previewEmoji {
    if (previsoes.isEmpty) return '🕐';
    return climaWeatherEmoji(previsoes.first.condicaoCodigo);
  }

  @override
  List<String> get previewChips {
    if (previsoes.isEmpty) return const ['24 horas'];
    final maxTemp = previsoes
        .map((p) => p.temperatura)
        .reduce((a, b) => a > b ? a : b);
    final minTemp = previsoes
        .map((p) => p.temperatura)
        .reduce((a, b) => a < b ? a : b);
    final chuvaTotal = previsoes.fold<double>(
      0,
      (sum, p) => sum + p.precipitacao,
    );
    return [
      'Máx ${maxTemp.toStringAsFixed(0)}°',
      'Mín ${minTemp.toStringAsFixed(0)}°',
      'Chuva ${chuvaTotal.toStringAsFixed(1)} mm',
    ];
  }

  @override
  String? get previewCampoLinha =>
      primeiraLinhaCampoCompartilhamento(contextoSemanal);

  @override
  String buildWhatsAppMessage() {
    final buffer = StringBuffer('$cidadeLabel\n');
    buffer.writeln('Próximas horas\n');
    for (final h in previsoes.take(8)) {
      final hora = '${h.hora.hour.toString().padLeft(2, '0')}h';
      buffer.writeln(
        '$hora ${h.temperatura.toStringAsFixed(0)}°, ${h.condicao}, '
        '${climaChuvaFrase(h.precipitacao, inicioMaiusculo: false)}',
      );
    }
    buffer.writeln();
    buffer.write(climaShareRodape(fonte));
    return buffer.toString().trim();
  }
}

final class ClimaSharePayloadSemanal extends ClimaSharePayload {
  const ClimaSharePayloadSemanal({
    required this.cidadeLabel,
    required this.previsoes,
    required this.fonte,
  });

  final String cidadeLabel;
  final List<PrevisaoDiaria> previsoes;
  @override
  final ClimaFonte fonte;

  static const _diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  static String diaCurto(DateTime data) => _diasSemana[data.weekday % 7];

  @override
  String get cidade => cidadeLabel;

  @override
  String get previewTitle => 'Previsão semanal · $cidadeLabel';

  @override
  String get previewSubtitle {
    if (previsoes.isEmpty) return 'Sem dados semanais';
    return previsoes.first.condicao;
  }

  @override
  String get previewEmoji {
    if (previsoes.isEmpty) return '📅';
    return climaWeatherEmoji(previsoes.first.condicaoCodigo);
  }

  @override
  List<String> get previewChips {
    if (previsoes.isEmpty) return const ['7 dias'];
    final first = previsoes.first;
    return [
      'Máx ${first.tempMax.toStringAsFixed(0)}°',
      'Mín ${first.tempMin.toStringAsFixed(0)}°',
      'Chuva ${first.precipitacao.toStringAsFixed(1)} mm',
    ];
  }

  @override
  String? get previewCampoLinha =>
      primeiraLinhaCampoCompartilhamento(previsoes);

  @override
  String buildWhatsAppMessage() {
    final buffer = StringBuffer('$cidadeLabel\n\n');
    for (final d in previsoes) {
      final dia = diaCurto(d.data);
      buffer.writeln(
        '$dia ${d.tempMax.toStringAsFixed(0)}°/${d.tempMin.toStringAsFixed(0)}°, '
        '${d.condicao}, '
        '${climaChuvaFrase(d.precipitacao, inicioMaiusculo: false)}',
      );
    }
    buffer.writeln();
    buffer.write(climaShareRodape(fonte));
    return buffer.toString().trim();
  }
}

/// Nome de cidade sem UF, para comparar a previsão com o cliente.
String climaCityMatchKey(String? raw) {
  if (raw == null) return '';
  return raw.split(',').first.trim().toLowerCase();
}

/// Telefone válido para WhatsApp (≥ 10 dígitos).
bool climaPhoneIsValid(String? phone) {
  if (phone == null || phone.trim().isEmpty) return false;
  return phone.replaceAll(RegExp(r'[^0-9]'), '').length >= 10;
}
