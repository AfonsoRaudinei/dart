import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/client.dart';
import '../../domain/enums/perfil_atendimento_tipo.dart';
import '../../domain/perfil_atendimento_abordagem.dart';

/// Cartão de destaque do perfil de atendimento no detalhe do cliente.
///
/// Sem diagnóstico, o toque abre o questionário. Com diagnóstico, o toque
/// abre o guia de venda e "Refazer" reabre o questionário.
class ClientPerfilDestaqueCard extends StatelessWidget {
  const ClientPerfilDestaqueCard({
    super.key,
    required this.client,
    required this.onRediagnosticar,
    required this.onAbrirAbordagem,
  });

  final Client client;
  final VoidCallback onRediagnosticar;
  final VoidCallback onAbrirAbordagem;

  static const distribuicaoKey = ValueKey('perfil-distribuicao');

  @override
  Widget build(BuildContext context) {
    final dominante = client.perfilDominante;
    final radius = BorderRadius.circular(20);

    return Semantics(
      button: true,
      label: dominante == null
          ? 'Perfil de atendimento: ainda não diagnosticado. '
                'Toque para iniciar diagnóstico'
          : 'Perfil de atendimento: ${dominante.labelDisplay}. '
                'Toque para ver como vender',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.premiumSurface,
          borderRadius: radius,
          border: Border.all(color: context.premiumCardBorder),
          boxShadow: context.premiumCardShadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: dominante == null ? onRediagnosticar : onAbrirAbordagem,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: dominante == null
                  ? _SemDiagnostico(onIniciar: onRediagnosticar)
                  : _Diagnosticado(
                      client: client,
                      dominante: dominante,
                      onRefazer: onRediagnosticar,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconePerfil(PerfilAtendimentoTipo tipo) {
  switch (tipo) {
    case PerfilAtendimentoTipo.pragmatico:
      return Icons.bolt_rounded;
    case PerfilAtendimentoTipo.analitico:
      return Icons.insights_rounded;
    case PerfilAtendimentoTipo.afavel:
      return Icons.handshake_outlined;
    case PerfilAtendimentoTipo.expressivo:
      return Icons.auto_awesome_rounded;
  }
}

class _Ilustracao extends StatelessWidget {
  const _Ilustracao({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = context.themeAccent;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 30, color: accent),
    );
  }
}

class _Diagnosticado extends StatelessWidget {
  const _Diagnosticado({
    required this.client,
    required this.dominante,
    required this.onRefazer,
  });

  final Client client;
  final PerfilAtendimentoTipo dominante;
  final VoidCallback onRefazer;

  @override
  Widget build(BuildContext context) {
    final accent = context.themeAccent;
    final secundario = client.perfilSecundario;
    final pontos = _pontosValidos(client);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'PERFIL DE ATENDIMENTO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: context.premiumTextSecondary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onRefazer,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refazer'),
              style: TextButton.styleFrom(
                foregroundColor: context.premiumTextSecondary,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Ilustracao(icon: _iconePerfil(dominante)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dominante.labelDisplay,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.premiumTextPrimary,
                    ),
                  ),
                  if (secundario != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Traço ${secundario.labelDisplay}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    abordagemDe(dominante).abordagemIdeal,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: context.premiumTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (pontos != null) ...[
          const SizedBox(height: 16),
          _Distribuicao(pontos: pontos, dominante: dominante),
        ],
        const SizedBox(height: 14),
        Divider(height: 1, thickness: 0.5, color: context.premiumHairline),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ver como vender',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: accent),
          ],
        ),
      ],
    );
  }
}

/// Pontos por perfil só quando os quatro estão gravados e somam algo.
Map<PerfilAtendimentoTipo, int>? _pontosValidos(Client client) {
  final a = client.perfilPontosPragmatico;
  final b = client.perfilPontosAnalitico;
  final c = client.perfilPontosAfavel;
  final d = client.perfilPontosExpressivo;
  if (a == null || b == null || c == null || d == null) return null;
  if (a + b + c + d <= 0) return null;
  return {
    PerfilAtendimentoTipo.pragmatico: a,
    PerfilAtendimentoTipo.analitico: b,
    PerfilAtendimentoTipo.afavel: c,
    PerfilAtendimentoTipo.expressivo: d,
  };
}

class _Distribuicao extends StatelessWidget {
  const _Distribuicao({required this.pontos, required this.dominante});

  final Map<PerfilAtendimentoTipo, int> pontos;
  final PerfilAtendimentoTipo dominante;

  static const _alphas = [1.0, 0.55, 0.30, 0.15];

  @override
  Widget build(BuildContext context) {
    final accent = context.themeAccent;
    final ordenados = pontos.entries.where((e) => e.value > 0).toList()
      ..sort((x, y) {
        if (x.key == dominante) return -1;
        if (y.key == dominante) return 1;
        return y.value.compareTo(x.value);
      });

    final segmentos = <Widget>[];
    for (var i = 0; i < ordenados.length; i++) {
      if (i > 0) segmentos.add(const SizedBox(width: 2));
      segmentos.add(
        Expanded(
          flex: ordenados[i].value,
          child: ColoredBox(
            color: accent.withValues(alpha: _alphas[i.clamp(0, 3)]),
          ),
        ),
      );
    }

    return Column(
      key: ClientPerfilDestaqueCard.distribuicaoKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(height: 6, child: Row(children: segmentos)),
        ),
        const SizedBox(height: 6),
        Text(
          ordenados.map((e) => '${e.key.labelDisplay} ${e.value}').join(' · '),
          softWrap: true,
          style: TextStyle(fontSize: 11, color: context.premiumTextTertiary),
        ),
      ],
    );
  }
}

class _SemDiagnostico extends StatelessWidget {
  const _SemDiagnostico({required this.onIniciar});

  final VoidCallback onIniciar;

  @override
  Widget build(BuildContext context) {
    final accent = context.themeAccent;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Ilustracao(icon: Icons.psychology_alt_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perfil de atendimento',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.premiumTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Descubra como este cliente prefere decidir e receba '
                    'dicas de venda sob medida.',
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: context.premiumTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        for (final tipo in PerfilAtendimentoTipo.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(
                              _iconePerfil(tipo),
                              size: 18,
                              color: accent.withValues(alpha: 0.35),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onIniciar,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Iniciar diagnóstico · 7 perguntas'),
          iconAlignment: IconAlignment.end,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: scheme.onPrimary,
            minimumSize: const Size.fromHeight(46),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
