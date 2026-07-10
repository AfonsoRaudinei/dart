import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

/// Payload de compartilhamento WhatsApp para o módulo clima.
sealed class ClimaSharePayload {
  const ClimaSharePayload();

  String get cidade;
  String get previewTitle;
  String get previewSubtitle;
  String get previewEmoji;
  List<String> get previewChips;

  String buildWhatsAppMessage();
}

final class ClimaSharePayloadAtual extends ClimaSharePayload {
  const ClimaSharePayloadAtual(this.clima);

  final ClimaAtual clima;

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
  String buildWhatsAppMessage() {
    return '🌤 Previsão do tempo — ${clima.cidade}\n\n'
        '🌡 ${clima.temperatura.toStringAsFixed(0)}°C — ${clima.condicao}\n'
        '💧 Umidade: ${clima.umidade}%\n'
        '🌧 Chuva: ${clima.precipitacao.toStringAsFixed(1)} mm\n'
        '💨 Vento: ${clima.ventoVelocidade.toStringAsFixed(0)} km/h ${clima.ventoDirecao}\n'
        '☀️ Índice UV: ${clima.indiceUV}\n\n'
        'Enviado pelo SoloForte App';
  }
}

final class ClimaSharePayloadHoraria extends ClimaSharePayload {
  const ClimaSharePayloadHoraria({
    required this.cidadeLabel,
    required this.previsoes,
  });

  final String cidadeLabel;
  final List<PrevisaoHoraria> previsoes;

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
  String buildWhatsAppMessage() {
    final buffer = StringBuffer('🌤 Próximas 24h — $cidadeLabel\n\n');
    for (final h in previsoes.take(24)) {
      final hora = '${h.hora.hour.toString().padLeft(2, '0')}h';
      buffer.writeln(
        '$hora: ${h.temperatura.toStringAsFixed(0)}° — ${h.condicao}, '
        '${h.precipitacao.toStringAsFixed(1)} mm',
      );
    }
    buffer.writeln('\nEnviado pelo SoloForte App');
    return buffer.toString().trim();
  }
}

final class ClimaSharePayloadSemanal extends ClimaSharePayload {
  const ClimaSharePayloadSemanal({
    required this.cidadeLabel,
    required this.previsoes,
  });

  final String cidadeLabel;
  final List<PrevisaoDiaria> previsoes;

  static const _diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _meses = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

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

  String _formatDay(PrevisaoDiaria d) {
    final diaNome = _diasSemana[d.data.weekday % 7];
    final mesNome = _meses[d.data.month - 1];
    return '$diaNome ${d.data.day}/$mesNome';
  }

  @override
  String buildWhatsAppMessage() {
    final buffer = StringBuffer('🌤 Previsão semanal — $cidadeLabel\n\n');
    for (final d in previsoes) {
      buffer.writeln(
        '${_formatDay(d)}: ${d.tempMax.toStringAsFixed(0)}°/'
        '${d.tempMin.toStringAsFixed(0)}° — ${d.condicao}, '
        '${d.precipitacao.toStringAsFixed(1)} mm',
      );
    }
    buffer.writeln('\nEnviado pelo SoloForte App');
    return buffer.toString().trim();
  }
}

/// Telefone válido para WhatsApp (≥ 10 dígitos).
bool climaPhoneIsValid(String? phone) {
  if (phone == null || phone.trim().isEmpty) return false;
  return phone.replaceAll(RegExp(r'[^0-9]'), '').length >= 10;
}
