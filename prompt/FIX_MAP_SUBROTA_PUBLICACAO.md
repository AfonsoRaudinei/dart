# FIX — SUB-ROTA PROIBIDA /map/publicacao/edit
## Sessão 5 — Remover violação Map-First do app_router

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em Navegação Map-First  
**Destino:** `prompt/FIX_MAP_SUBROTA_PUBLICACAO.md`  
**Execução imediata:** NÃO — PASSO 0 obrigatório. O agente lê tudo,
apresenta o plano completo e aguarda aprovação antes de qualquer edição.

---

## CONTEXTO

A auditoria de 23/03/2026 confirmou uma violação arquitetural no `app_router.dart`:

```
F.1 Encontrada em app_router: [ SIM linha 102 ]
F.2 É GoRoute real:           [ SIM — violação arquitetural ]
Veredito: [ VIOLAÇÃO REAL ]
```

O contrato `arquitetura-navegacao.md` é explícito:

> `/map` é singleton — sem sub-rotas válidas.  
> Contextos do mapa são estado interno, NÃO rotas.  
> Sub-rotas de `/map` são violação arquitetural grave.

**Objetivo:** Remover a rota `/map/publicacao/edit` do `app_router.dart`
e garantir que a funcionalidade de edição de publicação continue acessível
via rota correta fora do namespace `/map`.

---

## ESCOPO

**Arquivo obrigatório:** `lib/core/router/app_router.dart`  
**Arquivo provável de destino:** confirmar no PASSO 0  

🚫 Proibido criar nova sub-rota de `/map`  
🚫 Proibido usar `Navigator.pop()` ou `context.pop()` como retorno  
🚫 Proibido converter para overlay do mapa se a tela requer navegação própria  
🚫 Proibido remover a funcionalidade sem prover rota alternativa funcional  
🚫 Proibido alterar o contrato `arquitetura-navegacao.md`  

---

## PASSO 0 — LEITURA OBRIGATÓRIA (executar antes de qualquer edição)

```bash
# 0.1 — Ver o contexto completo da rota proibida no app_router
grep -n -B 5 -A 15 "map/publicacao\|publicacao.*edit\|edit.*publicacao" \
  lib/core/router/app_router.dart

# 0.2 — Ler todas as rotas do app_router para entender a estrutura
grep -n "path:\|GoRoute\|name:\|redirect" \
  lib/core/router/app_router.dart | head -60

# 0.3 — Localizar a tela que a rota carrega
grep -n "publicacao_form\|publicacao_edit\|PublicacaoForm\|PublicacaoEdit" \
  lib/core/router/app_router.dart

# 0.4 — Confirmar que a tela de destino existe
find lib/ -name "publicacao_form_screen.dart" -o -name "publicacao_edit*" \
  | grep -v test

# 0.5 — Ver como a tela é aberta (quem navega para ela)
grep -rn "context.go.*publicacao\|context.push.*publicacao\|/map/publicacao" \
  lib/ --include="*.dart" | grep -v test | grep -v app_router

# 0.6 — Verificar se há outras telas que chamam essa rota
grep -rn "map/publicacao\|publicacao/edit" \
  lib/ --include="*.dart" | grep -v test | grep -v app_router

# 0.7 — Verificar namespace correto para publicações
grep -n "consultoria\|publicacao\|'/pub" \
  lib/core/router/app_router.dart | grep "path:" | head -10

# 0.8 — Verificar se já existe rota de publicações fora do /map
grep -n "publicacao" lib/core/router/app_router.dart | grep "path:"

# 0.9 — Baseline de testes antes da mudança
flutter test --reporter compact 2>&1 | tail -5

# 0.10 — arch_check atual
./tool/arch_check.sh 2>&1 | tail -8
```

---

## ANÁLISE OBRIGATÓRIA ANTES DO PLANO

Com base no PASSO 0, o agente determina:

**Pergunta 1:** A rota `/map/publicacao/edit` é a ÚNICA rota para editar
publicações, ou existe outra rota fora do `/map` que faz o mesmo?

**Pergunta 2:** Quem navega para essa rota? É chamada a partir do mapa
(`private_map_screen`) ou de outras telas?

**Pergunta 3:** A tela carregada por essa rota precisa do contexto do mapa
(coordenadas, estado do mapa) ou é uma tela independente?

Com base nas respostas, o agente escolhe a solução correta:

---

## SOLUÇÕES POSSÍVEIS

### Solução A — Mover para namespace consultoria (mais provável)

Se a tela de edição de publicação é independente do mapa:

```dart
// ANTES (violação):
GoRoute(path: '/map/publicacao/edit', ...)

// DEPOIS (correto):
GoRoute(path: '/consultoria/publicacoes/edit', ...)
// ou
GoRoute(path: '/publicacoes/edit', ...)
```

Atualizar todos os pontos que navegam para a rota antiga.

### Solução B — Converter para showModalBottomSheet

Se a edição é leve e não requer tela própria, pode ser um
`showModalBottomSheet` chamado a partir de onde o usuário está,
sem criar rota nova. Neste caso remover a rota e substituir a
navegação por chamada de sheet.

### Solução C — Mover para rota já existente de publicações

Se já existe `/consultoria/publicacoes` no router, adicionar
o edit como parâmetro: `/consultoria/publicacoes/edit/:id`

**Hard stop:** Se nenhuma solução for viável sem alterar contratos
de interface ou criar dependências cruzadas → PARAR e reportar.
Não implementar solução que viole outros contratos para corrigir este.

---

## SEQUÊNCIA DE EXECUÇÃO

```
1. PASSO 0 completo → reportar todos os outputs
2. Responder as 3 perguntas da análise
3. Apresentar solução escolhida (A, B ou C) com justificativa
4. Mostrar exatamente:
   - Linha(s) a remover do app_router
   - Linha(s) a adicionar (nova rota ou sheet)
   - Todos os pontos de navegação a atualizar
5. Aguardar aprovação explícita
6. Aplicar correção
7. Gate checks
8. Commit
```

---

## GATE CHECKS

```bash
# Gate 1 — Sub-rota proibida não existe mais
grep -n "map/publicacao\|/map/pub" lib/core/router/app_router.dart && \
  echo "FALHA: sub-rota ainda presente" || \
  echo "OK: sub-rota removida"

# Gate 2 — Sem erros no app_router
flutter analyze lib/core/router/app_router.dart 2>&1 | tail -5

# Gate 3 — Suite completa sem regressão
flutter test --reporter compact 2>&1 | tail -5

# Gate 4 — arch_check mantido
./tool/arch_check.sh 2>&1 | tail -8

# Gate 5 — Nenhuma referência à rota antiga sobrou
grep -rn "map/publicacao" lib/ --include="*.dart" | grep -v test && \
  echo "FALHA: referência antiga ainda existe" || \
  echo "OK: nenhuma referência antiga"
```

**Critério de aprovação:**
- Gate 1: mensagem "OK: sub-rota removida"
- Gate 2: 0 erros
- Gate 3: todos os testes verdes
- Gate 4: EXIT 0
- Gate 5: mensagem "OK: nenhuma referência antiga"

---

## COMMIT

```bash
git add lib/core/router/app_router.dart
# + qualquer arquivo com navegação atualizada
git commit -m "fix(router): remove sub-rota proibida /map/publicacao/edit — restaura contrato Map-First"
```

Nunca usar `git add .` ou `git add -A`.

---

## VALIDAÇÃO FINAL

| Verificação | Esperado |
|---|---|
| Sub-rota `/map/publicacao/*` removida? | SIM |
| Funcionalidade de edição ainda acessível? | SIM — via rota correta |
| Nova rota está fora do namespace `/map`? | SIM |
| Todos os pontos de navegação atualizados? | SIM |
| Sem referências antigas no código? | SIM |
| arch_check EXIT 0? | SIM |
| Testes verdes? | SIM |

---

## ENCERRAMENTO PADRÃO

```
Resultado final:
Sub-rota /map/publicacao/edit removida do app_router.
Funcionalidade de edição de publicação acessível via rota correta
fora do namespace /map.
Contrato Map-First restaurado.
```

---

*Prompt gerado para: SoloForte App — Sessão 5 pós-auditoria*  
*Origem: Violação Map-First confirmada em auditoria 23/03/2026*  
*Arquivo alvo: lib/core/router/app_router.dart*
