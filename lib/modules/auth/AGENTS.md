# AGENTS.md — auth

## Bounded context

`auth/` cuida de autenticacao, cadastro, recuperacao de senha e apoio ao controle de sessao.

## Contratos e dependencias

- Pode usar servicos de sessao e Supabase via `core/`.
- Nao deve depender de modulos de dominio.

## Proibido

- Misturar regra de negocio agricola em fluxo de login/cadastro.
- Criar navegacao fora de `app_router.dart`.
- Expor dados sensiveis em logs, mensagens de erro ou testes.

## Qualidade obrigatoria

- Mensagens de erro devem ser sanitizadas.
- Mudancas em redirect/sessao exigem testes de rota/autenticacao.
- Rodar `flutter analyze lib/modules/auth/` e `./tool/arch_check.sh`.

