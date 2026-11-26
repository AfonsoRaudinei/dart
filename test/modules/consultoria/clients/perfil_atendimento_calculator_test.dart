import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/enums/perfil_atendimento_tipo.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/perfil_atendimento_calculator.dart';

void main() {
  group('calcularPerfilAtendimento', () {
    test('rejeita menos de 7 respostas', () {
      expect(
        () => calcularPerfilAtendimento([
          PerfilAtendimentoTipo.pragmatico,
        ]),
        throwsA(isA<PerfilAtendimentoValidationException>()),
      );
    });

    test('7 pontos no mesmo perfil: sem secundário', () {
      final r = calcularPerfilAtendimento(
        List.filled(7, PerfilAtendimentoTipo.analitico),
      );
      expect(r.dominante, PerfilAtendimentoTipo.analitico);
      expect(r.secundario, isNull);
      expect(r.pontos.sum(), 7);
    });

    test('4/2/1/0 — dominante e secundário claros', () {
      final respostas = [
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.analitico,
        PerfilAtendimentoTipo.analitico,
        PerfilAtendimentoTipo.afavel,
      ];
      final r = calcularPerfilAtendimento(respostas);
      expect(r.dominante, PerfilAtendimentoTipo.pragmatico);
      expect(r.secundario, PerfilAtendimentoTipo.analitico);
      expect(r.pontos.pragmatico, 4);
    });

    test('empate 2/2/2/1 — ordem P,A,F nas três primeiras', () {
      final respostas = [
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.analitico,
        PerfilAtendimentoTipo.afavel,
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.analitico,
        PerfilAtendimentoTipo.afavel,
        PerfilAtendimentoTipo.expressivo,
      ];
      final r = calcularPerfilAtendimento(respostas);
      expect(r.dominante, PerfilAtendimentoTipo.pragmatico);
      expect(r.secundario, PerfilAtendimentoTipo.analitico);
    });

    test('empate 3/3/1/0 — ordem define par no topo', () {
      final respostasAfavelPrimeiro = [
        PerfilAtendimentoTipo.afavel,
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.afavel,
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.afavel,
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.expressivo,
      ];
      final r = calcularPerfilAtendimento(respostasAfavelPrimeiro);
      expect(r.dominante, PerfilAtendimentoTipo.afavel);
      expect(r.secundario, PerfilAtendimentoTipo.pragmatico);

      final respostasPragPrimeiro = [
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.afavel,
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.afavel,
        PerfilAtendimentoTipo.pragmatico,
        PerfilAtendimentoTipo.afavel,
        PerfilAtendimentoTipo.expressivo,
      ];
      final r2 = calcularPerfilAtendimento(respostasPragPrimeiro);
      expect(r2.dominante, PerfilAtendimentoTipo.pragmatico);
      expect(r2.secundario, PerfilAtendimentoTipo.afavel);
    });
  });
}