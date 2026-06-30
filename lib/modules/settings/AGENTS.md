# AGENTS.md — settings

## Bounded context

`settings/` gerencia perfil, preferencias e configuracoes do usuario.

## Contratos e dependencias

- Pode usar servicos neutros de `core/`.
- Nao deve depender de modulos de dominio.

## Proibido

- Alterar tema/Design System global sem aprovacao explicita.
- Criar dependencia direta com agenda, consultoria, drawing, visitas, carteira ou planos.
- Usar settings como canal para mudar estado interno de modulo sem contrato.

## Qualidade obrigatoria

- Preferencias devem ter persistencia clara e rollback seguro em falha.
- Mudancas de perfil/sessao precisam respeitar autenticacao.
- Rodar `flutter analyze lib/modules/settings/` e `./tool/arch_check.sh`.

