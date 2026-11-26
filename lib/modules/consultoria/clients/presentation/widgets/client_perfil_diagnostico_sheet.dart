import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

import '../../domain/enums/perfil_atendimento_tipo.dart';
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
      _OpcaoPerfil('Destaque e reconhecimento', PerfilAtendimentoTipo.expressivo),
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
      _OpcaoPerfil('Relacionamento de longo prazo', PerfilAtendimentoTipo.afavel),
      _OpcaoPerfil('Novidade e status', PerfilAtendimentoTipo.expressivo),
    ],
  ),
  _PerguntaPerfil(
    titulo: 'Em reuniões em grupo, costuma…',
    opcoes: [
      _OpcaoPerfil('Cortar excessos e decidir', PerfilAtendimentoTipo.pragmatico),
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
  final List<PerfilAtendimentoTipo?> _respostas =
      List<PerfilAtendimentoTipo?>.filled(7, null);
  int _indice = 0;
  bool _salvando = false;

  void _selecionar(PerfilAtendimentoTipo perfil) {
    setState(() {
      _respostas[_indice] = perfil;
      if (_indice < 6) {
        _indice++;
      }
    });
  }

  bool get _completo => _respostas.every((r) => r != null);

  Future<void> _confirmar() async {
    if (!_completo || _salvando) return;
    setState(() => _salvando = true);
    try {
      final lista = _respostas.map((r) => r!).toList(growable: false);
      await ref.read(clientsControllerProvider).savePerfilDiagnostico(
            clientId: widget.clientId,
            respostas: lista,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil de atendimento salvo.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final pergunta = _kPerguntasPerfilAtendimento[_indice];

    return ClientSheetScaffold(
      title: 'Diagnóstico de perfil',
      subtitle: widget.clientName,
      contextLine: 'Pergunta ${_indice + 1} de 7',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            pergunta.titulo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: visuals.titleColor,
            ),
          ),
          const SizedBox(height: 16),
          ClientSheetActionCard(
            children: [
              for (var i = 0; i < pergunta.opcoes.length; i++)
                ClientSheetActionRow(
                  icon: Icons.radio_button_unchecked,
                  label: pergunta.opcoes[i].label,
                  description: pergunta.opcoes[i].perfil.labelDisplay,
                  showDivider: i < pergunta.opcoes.length - 1,
                  onTap: () => _selecionar(pergunta.opcoes[i].perfil),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_indice > 0)
            ClientSheetPrimaryButton(
              label: 'Voltar',
              onPressed: _salvando
                  ? null
                  : () => setState(() {
                        _indice--;
                      }),
            ),
          if (_completo) ...[
            const SizedBox(height: 12),
            ClientSheetPrimaryButton(
              label: 'Confirmar diagnóstico',
              isSaving: _salvando,
              onPressed: _salvando ? null : _confirmar,
            ),
          ],
        ],
      ),
    );
  }
}