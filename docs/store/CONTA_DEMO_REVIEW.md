# Conta Demo para Review — Apple e Google

Fornecer estas credenciais nos campos "App Review Information" / "Instruções para o revisor".

---

## Credenciais de teste

| Campo | Valor |
|-------|-------|
| **E-mail** | `review@soloforte.app` *(criar no Supabase Auth)* |
| **Senha** | `ReviewSolo2026!` *(alterar antes de submeter)* |

---

## Pré-requisitos no Supabase

1. Criar usuário `review@soloforte.app` com e-mail confirmado
2. Popular dados demo:
   - 1 cliente "Fazenda Demo"
   - 1 fazenda com 1 talhão (geometria simples)
   - 1 visita finalizada (opcional)
3. Executar schemas: `supabase_schema.sql`, `auth_delete_account.sql`, `feedback_table.sql`

---

## Instruções para o revisor

```
1. Faça login com as credenciais acima.
2. O mapa principal (dashboard) abre após login.
3. Toque no SmartButton (canto inferior direito) → Menu → explore Clientes, Agenda, Configurações.
4. Para testar ocorrência: no mapa, arme o modo ocorrências (ícone) → toque no mapa → salve.
5. GPS: permitir localização quando solicitado.
6. Exclusão de conta: Configurações → Excluir minha conta (não use em demo permanente).
7. Modo offline: Configurações → Modo Offline (pausa sync).
```

---

## Contato durante review

```
privacidade@soloforte.app
```

---

## Notas

- Não usar conta pessoal real para review.
- Rotacionar senha após aprovação ou rejeição.
- Se e-mail confirmation estiver ativo, confirmar manualmente no Supabase Dashboard.
