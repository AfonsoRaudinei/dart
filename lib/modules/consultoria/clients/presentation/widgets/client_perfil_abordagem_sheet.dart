import 'package:flutter/material.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

import '../../domain/enums/perfil_atendimento_tipo.dart';
import '../../domain/perfil_atendimento_abordagem.dart';
import 'client_sheet_widgets.dart';

Future<void> showClientPerfilAbordagemSheet({
  required BuildContext context,
  required String clientName,
  required PerfilAtendimentoTipo dominante,
  required PerfilAtendimentoTipo? secundario,
}) {
  return showSoloForteSheet<void>(
    context: context,
    showDragHandle: false,
    builder: (_) => _ClientPerfilAbordagemSheetBody(
      clientName: clientName,
      dominante: dominante,
      secundario: secundario,
    ),
  );
}

class _ClientPerfilAbordagemSheetBody extends StatelessWidget {
  const _ClientPerfilAbordagemSheetBody({
    required this.clientName,
    required this.dominante,
    required this.secundario,
  });

  final String clientName;
  final PerfilAtendimentoTipo dominante;
  final PerfilAtendimentoTipo? secundario;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final abordagem = abordagemDe(dominante);
    final frase = fraseCombinacao(dominante, secundario);
    final passos = passosCombinacao(dominante, secundario);
    final mostrarCombinacao = frase != null || passos != null;
    final traco = secundario;

    return ClientSheetScaffold(
      title: 'Como vender',
      subtitle: clientName,
      contextLine: traco == null
          ? dominante.labelDisplay
          : '${dominante.labelDisplay} · traço ${traco.labelDisplay}',
      child: Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: kFabSafeArea),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                kPrincipioAbordagem,
                softWrap: true,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: visuals.muted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                abordagem.essencia,
                softWrap: true,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: visuals.titleColor,
                ),
              ),
              const SizedBox(height: 22),
              const _Rotulo('Como vender'),
              const SizedBox(height: 8),
              _Bullets(abordagem.comoVender),
              const SizedBox(height: 18),
              const _Rotulo('Script de abertura'),
              const SizedBox(height: 8),
              _Citacao(abordagem.scriptAbertura),
              const SizedBox(height: 18),
              const _Rotulo('Evite'),
              const SizedBox(height: 8),
              _Bullets(abordagem.evite),
              const SizedBox(height: 18),
              const _Rotulo('Tabela prática'),
              const SizedBox(height: 8),
              _TabelaPratica(abordagem: abordagem),
              if (abordagem.estruturaProposta != null) ...[
                const SizedBox(height: 18),
                const _Rotulo('Estrutura da proposta'),
                const SizedBox(height: 8),
                _Numerados(abordagem.estruturaProposta!),
              ],
              if (abordagem.fechamentoAdequado != null) ...[
                const SizedBox(height: 18),
                const _Rotulo('Fechamento'),
                const SizedBox(height: 8),
                _Citacao(abordagem.fechamentoAdequado!),
              ],
              if (mostrarCombinacao) ...[
                const SizedBox(height: 18),
                const _Rotulo('Como combinar'),
                const SizedBox(height: 8),
                if (frase != null) _Citacao(frase),
                if (passos != null) ...[
                  if (frase != null) const SizedBox(height: 12),
                  _Numerados(passos),
                ],
              ],
              if (traco != null && !mostrarCombinacao) ...[
                const SizedBox(height: 18),
                _Rotulo('Traço ${traco.labelDisplay}'),
                const SizedBox(height: 8),
                Text(
                  '“${abordagemDe(traco).fechamento}”',
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: visuals.titleColor,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const _Rotulo('Dicas para aumentar a conversão'),
              const SizedBox(height: 8),
              const _Bullets(kDicasConversao),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloco curto do dominante, reutilizado na etapa de resultado do diagnóstico.
class ClientPerfilAbordagemResumo extends StatelessWidget {
  const ClientPerfilAbordagemResumo({super.key, required this.tipo});

  final PerfilAtendimentoTipo tipo;

  @override
  Widget build(BuildContext context) {
    final abordagem = abordagemDe(tipo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          abordagem.resumo,
          softWrap: true,
          style: TextStyle(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: ClientSheetVisuals.of(context).titleColor,
          ),
        ),
        const SizedBox(height: 12),
        _ResumoLinha(rotulo: 'Abordagem', valor: abordagem.abordagemIdeal),
        _ResumoLinha(rotulo: 'Prova', valor: abordagem.prova),
        _ResumoLinha(rotulo: 'Fechamento', valor: abordagem.fechamento),
      ],
    );
  }
}

class _ResumoLinha extends StatelessWidget {
  const _ResumoLinha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              rotulo,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: visuals.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              softWrap: true,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: visuals.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      softWrap: true,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ClientSheetVisuals.of(context).muted,
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets(this.itens);

  final List<String> itens;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final estilo = TextStyle(
      fontSize: 15,
      height: 1.4,
      color: visuals.titleColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in itens)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•', style: estilo.copyWith(color: visuals.accent)),
                const SizedBox(width: 8),
                Expanded(child: Text(item, softWrap: true, style: estilo)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Numerados extends StatelessWidget {
  const _Numerados(this.itens);

  final List<String> itens;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final estilo = TextStyle(
      fontSize: 15,
      height: 1.4,
      color: visuals.titleColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < itens.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}.',
                    style: estilo.copyWith(
                      fontWeight: FontWeight.w600,
                      color: visuals.muted,
                    ),
                  ),
                ),
                Expanded(child: Text(itens[i], softWrap: true, style: estilo)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Citacao extends StatelessWidget {
  const _Citacao(this.texto);

  final String texto;

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
        padding: const EdgeInsets.all(14),
        child: Text(
          texto,
          softWrap: true,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: visuals.titleColor,
          ),
        ),
      ),
    );
  }
}

class _TabelaPratica extends StatelessWidget {
  const _TabelaPratica({required this.abordagem});

  final PerfilAtendimentoAbordagem abordagem;

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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TabelaLinha(
              rotulo: 'Abordagem ideal',
              valor: abordagem.abordagemIdeal,
            ),
            _TabelaLinha(rotulo: 'Prova mais eficaz', valor: abordagem.prova),
            _TabelaLinha(
              rotulo: 'Fechamento',
              valor: '“${abordagem.fechamento}”',
            ),
          ],
        ),
      ),
    );
  }
}

class _TabelaLinha extends StatelessWidget {
  const _TabelaLinha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            rotulo,
            softWrap: true,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: visuals.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            softWrap: true,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: visuals.titleColor,
            ),
          ),
        ],
      ),
    );
  }
}
