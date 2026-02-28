# PROMPT — DÍVIDA: Resolver authorId TODO
# Executar em: GitHub Copilot / Antigravity / Cursor
# Módulo alvo: consultoria
# Tipo: bugfix / dívida técnica
# Impacto: 2 arquivos, sem alteração de contrato, sem nova fronteira

---

## CONTEXTO

Dois arquivos possuem o seguinte TODO pendente:

```dart
// TODO: substituir por ID real do usuário autenticado
```

O projeto usa Supabase para autenticação.
O auth service está em: `lib/modules/auth/services/auth_service.dart`
Padrão confirmado no projeto: `Supabase.instance.client.auth.currentUser?.id`

---

## OBJETIVO

Substituir o `TODO` nos dois arquivos abaixo pelo ID real do usuário autenticado,
usando o padrão já existente no projeto — sem criar novo provider, sem inventar nada.

---

## ARQUIVO 1

**Caminho:** `lib/modules/consultoria/relatorios/presentation/relatorios_list_screen.dart`

**Localizar:**
```dart
// TODO: substituir por ID real do usuário autenticado via auth provider
const clientId = 'current_user_id';
```

**Substituir por:**
```dart
final clientId = Supabase.instance.client.auth.currentUser?.id ?? '';
```

**Observação:**
- Se `clientId` for vazio (usuário não autenticado), o provider
  `relatoriosListProvider` vai retornar lista vazia — comportamento correto.
- NÃO alterar mais nada neste arquivo.

---

## ARQUIVO 2

**Caminho:** `lib/modules/consultoria/publicacoes/presentation/publicacao_form_screen.dart`

**Localizar:**
```dart
// TODO: substituir por ID real do usuário autenticado
authorId: 'current_user_id',
```

**Substituir por:**
```dart
authorId: Supabase.instance.client.auth.currentUser?.id ?? '',
```

**Observação:**
- O `CreatePublicacaoUseCase` valida se `authorId` não é vazio antes de persistir.
- Se estiver vazio, o use case vai lançar exceção — a tela já trata o erro
  com `errorMessage`.
- NÃO alterar mais nada neste arquivo.

---

## IMPORT A VERIFICAR

Em ambos os arquivos, confirmar que o import do Supabase está presente.
Se não estiver, adicionar:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

---

## VALIDAÇÃO FINAL

- [x] Nenhum TODO de authorId restante nos dois arquivos
- [x] Nenhuma outra linha alterada além das identificadas
- [x] `flutter analyze` nos dois arquivos → 0 erros
- [x] arch_check.sh → continua aprovado (nenhuma fronteira alterada)
