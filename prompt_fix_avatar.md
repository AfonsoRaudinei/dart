# Correção do Upload de Avatar no Cadastro (Módulo: Auth)

## Diagnóstico
Atualmente o projeto tenta fazer o upload da foto de perfil para o bucket `users` (`storage.from('users')`) no Supabase, no arquivo `lib/modules/auth/services/auth_service.dart`. Como este bucket ainda não foi criado na infraestrutura do Supabase, o cadastro retorna um erro fatal de `Bucket not found` (404).

## Objetivo
Tornar o upload de avatar tolerante a falhas — caso o Storage retorne um erro (como bucket inexistente), o usuário ainda pode continuar o fluxo de cadastro e criar a sua conta sem foto.

## Regras de Implementação
1. **Onde modificar**: `lib/modules/auth/services/auth_service.dart` no método `register`.
2. **Nova lógica**:
   - Envolva toda a etapa de upload da imagem e atribuição de `photoUrl` em um bloco `try/catch`.
   - Se ocorrer erro, faça o log da falha (ex: `debugPrint('Erro no upload de foto: $e');`) para não perder essa informação de diagnóstico.
   - Force o valor de `photoUrl` para `null`.
   - Avance normalmente para o Passo 3 (salvar na tabela `public.users`).
3. **Integridade**: Não toque no Passo 1 (criação no Supabase Auth) nem no formato do payload enviado para o Passo 3, apenas trate a tolerância do Storage.

## Aviso sobre a Infraestrutura
Para que as fotos funcionem futuramente, será preciso ir no [Painel do Supabase > Storage] e criar um novo **Bucket** chamado exatamente de `users`, deixando-o configurado como **Public** caso as avatares precisem ser lidos sem token de sessão em algumas partes do app.
