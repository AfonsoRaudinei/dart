# AGENTS.md — public

## Bounded context

`public/` cobre fluxos publicos e onboarding sem autenticacao.

## Contratos e dependencias

- Pode usar utilitarios neutros de `core/`.
- Nao deve depender de modulos privados de dominio.

## Proibido

- Expor dados privados antes de autenticacao.
- Criar atalhos para rotas privadas fora do router.
- Colocar regra de negocio agricola em tela publica.

## Qualidade obrigatoria

- Estados publicos devem degradar com seguranca quando nao houver sessao.
- Validar redirect e acesso anonimo quando mexer no fluxo.
- Rodar `flutter analyze lib/modules/public/` e `./tool/arch_check.sh`.

