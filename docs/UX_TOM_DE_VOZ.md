# Tom de voz do SoloForte

Texto do app fala como um colega de campo: claro, curto e respeitoso.

## 5 regras
1. **Trate por "você"** — nunca "o usuário".
2. **Frases curtas, sem jargão** — "Não conseguimos carregar a carteira", não "Erro ao carregar carteira".
3. **Verbo de ação nos botões** — "Agendar visita", "Salvar talhão", "Tentar de novo".
4. **Nunca culpe o usuário** — "Digite uma quantidade válida", não "Quantidade inválida".
5. **Todo erro diz o próximo passo** — "Tente de novo", "Confira o GPS", "Fale com o suporte".

## Exemplos
| Evitar | Preferir |
|---|---|
| Usuário não autenticado. | Entre na sua conta para continuar. |
| Erro ao salvar safra: $e | Não deu para salvar a safra. Tente novamente. |
| Informe um percentual de 0 a 100. | Digite um percentual de 0 a 100. |
| Nenhum evento agendado | Dia livre. Que tal agendar uma visita? |

## Sucesso
Reservado a marcos reais (visita concluída, talhão salvo): `showFieldSuccess` em
`lib/core/ui/field_feedback.dart` ("Visita registrada. Bom trabalho no campo!").

Nunca exiba exceções cruas (`$e`) ao usuário: use `userFacingError`.
