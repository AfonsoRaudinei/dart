# PROMPT 04 — `DrawingRemoteStore`: Implementação do Stub

**Especialização do agente:** Engenheiro Sênior Flutter/Dart — Arquitetura de Repositórios Offline-First  
**Tipo:** FEATURE — Implementação de stub existente (sem criar nova estrutura)  
**Módulo:** `drawing/`  
**Rota afetada:** Nenhuma nova rota

---

## CONTEXTO

`DrawingRemoteStore` existe como **stub não implementado**. O módulo `drawing/` persiste dados localmente (SQLite) mas ainda não sincroniza com Supabase. Este prompt implementa a sincronização remota seguindo o padrão offline-first já estabelecido no projeto (idêntico ao padrão de `marketing/` e `consultoria/`).

**Padrão de referência:** `MarketingCaseRepositoryImpl` (offline-first com `pending_sync` + retry).

---

## PASSO 0 — LOCALIZAÇÃO OBRIGATÓRIA

```bash
find lib/ -name "*drawing*remote*" -o -name "*remote*drawing*" | sort
find lib/ -name "drawing_repository*.dart" | sort
find lib/ -name "i_drawing_repository.dart" | sort
grep -rn "DrawingRemoteStore\|drawingRemoteStore" lib/ | sort
grep -rn "pending_sync\|sync_status" lib/modules/drawing/ | sort
wc -l lib/modules/drawing/data/repositories/*.dart 2>/dev/null
```

Reporte caminhos reais e estado atual do stub antes de qualquer ação.

---

## PASSO 1 — LEITURA (sem tocar nada)

### 1.1 Estado atual do stub
- O stub existe em qual arquivo exatamente?
- Quais métodos estão declarados mas não implementados? (listar com assinatura)
- Existe interface `IDrawingRemoteStore` ou similar?

### 1.2 Entidade `Drawing` (ou equivalente)
- Qual é a entidade persistida? Campos reais (não assumir)?
- Existe `toJson()` / `fromJson()`?
- Existe campo `sync_status`? Campo `user_id`?

### 1.3 Repositório local existente
- Como o repositório local persiste os dados?
- Nome da tabela SQLite?
- `pending_sync` já está sendo usado localmente?

### 1.4 Supabase
- Existe tabela no Supabase para drawings? Qual nome?
- Se não existir → **PARAR e reportar. Não criar tabela sem decisão explícita.**

---

## PASSO 2 — PLANEJAMENTO (propor antes de executar)

O agente deve propor:

```
Método                  | Comportamento
------------------------|------------------------------------------
push(Drawing drawing)   | INSERT/UPSERT na tabela Supabase
pull(String userId)     | SELECT WHERE user_id = userId
delete(String id)       | Soft delete (deleted_at) ou hard delete?
retryPending()          | Busca pending_sync local → tenta push
```

**Reportar proposta e aguardar confirmação antes de executar.**

---

## PASSO 3 — EXECUÇÃO

Implementar apenas o que está declarado na interface/stub.  
**Não adicionar métodos novos** sem aprovação explícita.

Ordem:
1. Implementar corpo dos métodos no `DrawingRemoteStore`
2. Conectar no repositório principal (se já existir ponto de injeção)
3. Adicionar `debugPrint` nos catch para diagnóstico futuro

**Gate por método:** `flutter analyze lib/modules/drawing/` após cada método implementado.

---

## PASSO 4 — RESTRIÇÕES ABSOLUTAS

❌ Não criar tabela Supabase no código — apenas referenciá-la pelo nome  
❌ Não alterar schema SQLite local (não é migration sprint)  
❌ Não alterar `DrawingController` nem `drawing_sheet.dart`  
❌ Não alterar contratos de `IClientLookup` / `IFarmLookup`  
❌ Não criar provider novo — usar injeção existente  
✅ Seguir exatamente o padrão de `MarketingCaseRepositoryImpl` como referência  

---

## PASSO 5 — VALIDAÇÃO FINAL

```bash
flutter analyze lib/modules/drawing/
bash tool/arch_check.sh
```

Esperado:
- 0 novos erros
- `arch_check.sh`: Exit 0
- Stub não mais marcado como `// TODO` ou `throw UnimplementedError()`

**Responder:**

| Verificação | Resultado |
|---|---|
| DrawingRemoteStore implementado? | SIM |
| UnimplementedError removido? | SIM |
| Schema SQLite alterado? | NÃO |
| DrawingController alterado? | NÃO |
| arch_check.sh Exit 0? | SIM |

---

## ENCERRAMENTO

`DrawingRemoteStore` implementado seguindo padrão offline-first do projeto.  
Nenhum contrato externo, schema ou rota alterado.
