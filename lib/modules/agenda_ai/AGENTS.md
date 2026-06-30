# AGENTS.md — agenda_ai

## Bounded context

`agenda_ai/` gera sugestoes inteligentes de agenda. Ele nao e dono do calendario nem da carteira; apenas consome informacoes por contratos.

## Contratos e dependencias

- Pode consumir `core/contracts/IAgendaSessionBridge`.
- Pode consumir `core/contracts/IClientLookup`.
- Deve evitar imports diretos de `modules/agenda` e `modules/carteira`.

## Proibido

- Persistir eventos reais sem passar pelo dominio `agenda/`.
- Criar dependencia lateral nova com carteira, consultoria ou visitas.
- Inventar dados de sugestao quando a fonte real estiver vazia.

## Qualidade obrigatoria

- Sugestoes devem ser deterministicas e rastreaveis a dados reais.
- Estados assincronos via Riverpod moderno.
- Testes esperados: `test/modules/agenda_ai/`.
- Rodar `./tool/arch_check.sh`.

