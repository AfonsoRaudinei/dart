# AGENTS.md — produtor

## Bounded context

`produtor/` apresenta a propriedade própria e vínculos de leitura concedidos
por consultores. Os dados agronômicos continuam pertencendo a `consultoria/`.

## Contratos e dependências

- Deve usar `IProducerPropertyGateway` para propriedade, fazenda e talhão.
- Expõe criação de convite por `IProducerInviteWriter` quando necessário.
- Não deve importar outros módulos de domínio diretamente.

## Proibido

- Importar `consultoria/`, `drawing/`, `agenda/` ou `visitas/` diretamente.
- Duplicar entidades agronômicas para contornar contratos.
- Fazer hard delete de dados sincronizáveis.

## Qualidade obrigatória

- Persistência mantém `user_id`, `sync_status` e soft delete.
- Testes esperados: `test/modules/produtor/`.
- Rodar `./tool/arch_check.sh`.
