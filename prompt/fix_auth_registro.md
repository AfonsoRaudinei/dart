# PROMPT: Fix — Criar Conta (Registro)

## Módulo: auth
## Arquivo alvo: lib/modules/auth/register_screen.dart (ou equivalente)
## Objetivo: Corrigir erro PostgrestException 404 ao criar conta

## Problema
O método de registro está chamando PostgREST (.from()) 
em vez de usar supabase.auth.signUp().

## Regras
- Usar APENAS supabase.auth.signUp(email, password, data: {...})
- Campos extras (nome, telefone, tipo) vão em `data:` do signUp
- NÃO chamar supabase.from('users').insert() no fluxo de registro
- Após signUp bem-sucedido, dados extras são salvos via trigger 
  no Supabase (handle_new_user) ou separadamente com o UID retornado
- Tratar erro AuthException separadamente de PostgrestException
- Zero improviso — seguir contrato Supabase Auth

## Contrato esperado
```dart
supabase.auth.signUp(
  email: emailController.text.trim(),
  password: passwordController.text,
  data: {
    'full_name': nomeController.text.trim(),
    'phone': telefoneController.text.trim(),
    'user_type': tipoUsuario, // 'consultor' etc
  },
);
```

## Validação final
- Nenhum outro módulo alterado
- Nenhuma rota criada
- Apenas o fluxo de registro corrigido

## Verificação adicional no Supabase Dashboard
Antes de aplicar o fix, confirme:

1. **Authentication > Settings** — Email Auth está habilitado?
2. **Database > Functions** — existe `handle_new_user` trigger?
3. A URL do Supabase no `run_dev.sh` está correta?
