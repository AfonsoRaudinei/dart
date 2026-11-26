import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

import '../../domain/enums/perfil_atendimento_tipo.dart';
import '../../domain/perfil_atendimento_calculator.dart';
import '../providers/clients_providers.dart';
import 'client_sheet_widgets.dart';

const List<_PerguntaPerfil> _kPerguntasPerfilAtendimento = [
  _PerguntaPerfil(
    titulo: 'Na primeira reunião, o cliente tende a…',
    opcoes: [
      _OpcaoPerfil(
        'Ir direto ao custo-benefício',
        PerfilAtendimentoTipo.pragmatico,
      ),
      _OpcaoPerfil(
        'Pedir dados e referências',
        PerfilAtendimentoTipo.analitico,
      ),
      _OpcaoPerfil(
        'Priorizar confiança e rapport',
        PerfilAtendimentoTipo.afavel,
      ),
      _OpcaoPerfil(
        'Falar da visão e oportunidades',
        PerfilAtendimentoTipo.expressivo,
      ),
    ],
  ),
  _PerguntaPerfil(
    titulo: 'Ao decidir um investimento, ele prefere…',
    opcoes: [
      _OpcaoPerfil('Resultado rápido', PerfilAtendimentoTipo.pragmatico),
      _OpcaoPerfil('Projeções detalhadas', PerfilAtendimentoTipo.analitico),
      _OpcaoPerfil('Consenso com a família', PerfilAtendimentoTipo.afavel),
      _OpcaoPerfil(
        'Destaque e reconhecimento',
        PerfilAtendimentoTipo.expressivo,
      ),
    ],
  ),
  _PerguntaPerfil(
    titulo: 'Diante de um problema no campo, reage…',
    opcoes: [
      _OpcaoPerfil('Ação imediata', PerfilAtendimentoTipo.pragmatico),
      _OpcaoPerfil('Análise de causa', PerfilAtendimentoTipo.analitico),
      _OpcaoPerfil('Busca apoio próximo', PerfilAtendimentoTipo.afavel),
      _OpcaoPerfil('Comunica com ênfase', PerfilAtendimentoTipo.expressivo),
    ],
  ),
  _PerguntaPerfil(
    titulo: 'Na negociação de produtos, valoriza mais…',
    opcoes: [
      _OpcaoPerfil('Economia e prazo', PerfilAtendimentoTipo.pragmatico),
      _OpcaoPerfil('Evidências técnicas', PerfilAtendimentoTipo.analitico),
      _OpcaoPerfil(
        'Relacionamento de longo prazo',
        PerfilAtendimentoTipo.afavel,
      ),
      _OpcaoPerfil('Novidade e status', PerfilAtendimentoTipo.expressivo),
    ],
  ),
  _PerguntaPerfil(
    titulo: 'Em reuniões em grupo, costuma…',
    opcoes: [
      _OpcaoPerfil(
        'Cortar excessos e decidir',
        PerfilAtendimentoTipo.pragmatico,
      ),
      _OpcaoPerfil('Questionar números', PerfilAtendimentoTipo.analitico),
      _OpcaoPerfil('Ouvir todos', PerfilAtendimentoTipo.afavel),
      _OpcaoPerfil('Animar e persuadir', PerfilAtendimentoTipo.expressivo),
    ],
  ),
  _PerguntaPerfil(
    titulo: 'Ao receber uma recomendação técnica…',
    opcoes: [
      _OpcaoPerfil('Quer aplicar logo', PerfilAtendimentoTipo.pragmatico),
      _OpcaoPerfil('Quer comparar estudos', PerfilAtendimentoTipo.analitico),
      _OpcaoPerfil('Quer alinhar com o time', PerfilAtendimentoTipo.afavel),
      _OpcaoPerfil('Quer contar a história', PerfilAtendimentoTipo.expressivo),
    ],
  ),
  _PerguntaPerfil(
    titulo: 'O estilo de comunicação preferido é…',
    opcoes: [
      _OpcaoPerfil('Objetivo e curto', PerfilAtendimentoTipo.pragmatico),
      _OpcaoPerfil('Preciso e documentado', PerfilAtendimentoTipo.analitico),
      _OpcaoPerfil('Cordial e paciente', PerfilAtendimentoTipo.afavel),
      _OpcaoPerfil('Entusiasmado', PerfilAtendimentoTipo.expressivo),
    ],
  ),
];

const Duration _kPausaConfirmacao = Duration(milliseconds: 350);
const Duration _kTransicaoEtapa = Duration(milliseconds: 220);

class _PerguntaPerfil {
  const _PerguntaPerfil({required this.titulo, required this.opcoes});

  final String titulo;
  final List<_OpcaoPerfil> opcoes;
}

class _OpcaoPerfil {
  const _OpcaoPerfil(this.label, this.perfil);

  final String label;
  final PerfilAtendimentoTipo perfil;
}

Future<void> showClientPerfilDiagnosticoSheet({
  required BuildContext context,
  required String clientId,
  required String clientName,
}) {
  return showSoloForteSheet<void>(
    context: context,
    showDragHandle: false,
    builder: (_) => _ClientPerfilDiagnosticoSheetBody(
      clientId: clientId,
      clientName: clientName,
    ),
  );
}

class _ClientPerfilDiagnosticoSheetBody extends ConsumerStatefulWidget {
  const _ClientPerfilDiagnosticoSheetBody({
    required this.clientId,
    required this.clientName,
  });

  final String clientId;
  final String clientName;

  @override
  ConsumerState<_ClientPerfilDiagnosticoSheetBody> createState() =>
      _ClientPerfilDiagnosticoSheetBodyState();
}

class _ClientPerfilDiagnosticoSheetBodyState
    extends ConsumerState<_ClientPerfilDiagnosticoSheetBody> {
  static final int _total = _kPerguntasPerfilAtendimento.length;

  final List<PerfilAtendimentoTipo?> _respostas =
      List<PerfilAtendimentoTipo?>.filled(
        _kPerguntasPerfilAtendimento.length,
        null,
      );

  /// `0.._total - 1` são perguntas; `_total` é a etapa de resultado.
  int _etapa = 0;
  bool _avancando = false;
  bool _salvando = false;

  bool get _noResultado => _etapa >= _total;

  bool get _completo => _respostas.every((r) => r != null);

  Future<void> _selecionar(PerfilAtendimentoTipo perfil) async {
    if (_avancando || _salvando || _noResultado) return;
    HapticFeedback.selectionClick();
    setState(() {
      _respostas[_etapa] = perfil;
      _avancando = true;
    });
    await Future<void>.delayed(_kPausaConfirmacao);
    if (!mounted) return;
    setState(() {
      _avancando = false;
      _etapa++;
    });
  }

  void _irPara(int etapa) {
    if (_avancando || _salvando) return;
    setState(() => _etapa = etapa);
  }

  void _refazer() {
    if (_avancando || _salvando) return;
    setState(() {
      _respostas.fillRange(0, _respostas.length, null);
      _etapa = 0;
    });
  }

  Future<void> _confirmar() async {
    if (!_completo || _salvando) return;
    setState(() => _salvando = true);
    try {
      final lista = _respostas.map((r) => r!).toList(growable: false);
      await ref
          .read(clientsControllerProvider)
          .savePerfilDiagnostico(clientId: widget.clientId, respostas: lista);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil de atendimento salvo.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClientSheetScaffold(
      title: 'Diagnóstico de perfil',
      subtitle: widget.clientName,
      child: Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: kFabSafeArea),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProgressoSegmentos(
                total: _total,
                preenchidos: _noResultado ? _total : _etapa + 1,
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: _kTransicaoEtapa,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, if (current != null) current],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey<int>(_etapa),
                  child: _noResultado
                      ? _buildResultado(context)
                      : _buildPergunta(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPergunta(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final pergunta = _kPerguntasPerfilAtendimento[_etapa];
    final selecionada = _respostas[_etapa];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pergunta ${_etapa + 1} de $_total',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: visuals.muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          pergunta.titulo,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: visuals.titleColor,
          ),
        ),
        const SizedBox(height: 20),
        for (final opcao in pergunta.opcoes) ...[
          _OpcaoCard(
            label: opcao.label,
            selecionada: selecionada == opcao.perfil,
            onTap: () => _selecionar(opcao.perfil),
          ),
          const SizedBox(height: 10),
        ],
        if (_etapa > 0 || _completo) ...[
          const SizedBox(height: 4),
          Wrap(
            alignment: _etapa > 0
                ? WrapAlignment.spaceBetween
                : WrapAlignment.end,
            children: [
              if (_etapa > 0)
                _AcaoSecundaria(
                  icon: Icons.chevron_left,
                  label: 'Voltar',
                  onPressed: () => _irPara(_etapa - 1),
                ),
              if (_completo)
                _AcaoSecundaria(
                  label: 'Ver resultado',
                  onPressed: () => _irPara(_total),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildResultado(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final resultado = calcularPerfilAtendimento(
      _respostas.map((r) => r!).toList(growable: false),
    );
    final secundario = resultado.secundario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Perfil de atendimento',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: visuals.muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          resultado.dominante.labelDisplay,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.15,
            color: visuals.accent,
          ),
        ),
        if (secundario != null) ...[
          const SizedBox(height: 4),
          Text(
            'Traço ${secundario.labelDisplay}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: visuals.titleColor,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _DistribuicaoPontos(pontos: resultado.pontos, total: _total),
        const SizedBox(height: 24),
        ClientSheetPrimaryButton(
          label: 'Confirmar diagnóstico',
          isSaving: _salvando,
          onPressed: _salvando ? null : _confirmar,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            _AcaoSecundaria(
              label: 'Revisar respostas',
              onPressed: () => _irPara(_total - 1),
            ),
            _AcaoSecundaria(label: 'Refazer', onPressed: _refazer),
          ],
        ),
      ],
    );
  }
}

class _ProgressoSegmentos extends StatelessWidget {
  const _ProgressoSegmentos({required this.total, required this.preenchidos});

  final int total;
  final int preenchidos;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: _kTransicaoEtapa,
              curve: Curves.easeOut,
              height: 4,
              decoration: BoxDecoration(
                color: i < preenchidos
                    ? visuals.accent
                    : visuals.muted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OpcaoCard extends StatelessWidget {
  const _OpcaoCard({
    required this.label,
    required this.selecionada,
    required this.onTap,
  });

  final String label;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final radius = BorderRadius.circular(visuals.cardRadius);

    return Semantics(
      button: true,
      selected: selecionada,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selecionada
              ? visuals.accent.withValues(alpha: 0.10)
              : visuals.cardBg,
          borderRadius: radius,
          border: Border.all(
            color: selecionada ? visuals.accent : visuals.cardBorder,
            width: selecionada ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  ClientSheetIosRadio(
                    selected: selecionada,
                    accentColor: visuals.accent,
                    mutedColor: visuals.muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selecionada
                            ? FontWeight.w600
                            : FontWeight.w500,
                        height: 1.3,
                        color: visuals.titleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DistribuicaoPontos extends StatelessWidget {
  const _DistribuicaoPontos({required this.pontos, required this.total});

  final PerfilAtendimentoPontos pontos;
  final int total;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.cardBg,
        borderRadius: BorderRadius.circular(visuals.cardRadius),
        border: Border.all(color: visuals.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          children: [
            for (final tipo in PerfilAtendimentoTipo.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        tipo.labelDisplay,
                        style: TextStyle(fontSize: 13, color: visuals.muted),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pontos.countFor(tipo) / total,
                          minHeight: 6,
                          color: visuals.accent,
                          backgroundColor: visuals.muted.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${pontos.countFor(tipo)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: visuals.titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AcaoSecundaria extends StatelessWidget {
  const _AcaoSecundaria({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final style = TextButton.styleFrom(
      foregroundColor: visuals.ghostText,
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );
    if (icon == null) {
      return TextButton(style: style, onPressed: onPressed, child: Text(label));
    }
    return TextButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
