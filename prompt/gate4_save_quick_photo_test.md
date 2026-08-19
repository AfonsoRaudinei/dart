# PROMPT — GATE 4: Testes de `SaveQuickPhoto` (visit_session_id)
**Agente:** Engenheiro Sênior Flutter/Dart
**Arquivo salvo em:** `prompt/gate4_save_quick_photo_test.md`
**Data:** 17/08/2026
**Risco:** BAIXO — cria apenas arquivo de teste, zero código de produção alterado
**Bloqueador:** este prompt é o único impedimento para o commit do Prompt 3/3 e geração do IPA
**PROMPT BASE ATIVO:** SOLOFORTE_PROMPT_BASE_v2.1
**Módulo afetado:** consultoria/quick_photo/ (somente testes)
**Bounded context:** consultoria/
**Tipo:** criação de testes — GATE 4 do Prompt 3/3
**Objetivo:** Criar save_quick_photo_test.dart com dois cenários de injeção de visit_session_id
**Altera contrato de interface?** NÃO
**Altera fronteira entre módulos?** NÃO
**Altera código de produção?** NÃO — somente test/
**arch_check.sh:** OBRIGATÓRIO exit 0

---

## CONTEXTO

O Prompt 3/3 implementou a injeção de `visit_session_id` no use case
`SaveQuickPhoto` via `resolveVisitSessionIdForPhoto`. O código existe no
working tree e está correto, mas o GATE 4 (testes dos dois cenários) não
foi entregue.

O revisor bloqueou o commit até estes testes existirem.

O arquivo de teste a criar é:
`test/modules/consultoria/quick_photo/save_quick_photo_test.dart`

Este arquivo **não existe hoje**. O `quick_photo_list_test.dart` existente
testa filtragem de órfãs — não cobre save. Não tocá-lo.

---

## PASSO 0 — DESCOBERTA OBRIGATÓRIA

(comandos do prompt original)

**Reportar obrigatoriamente antes do GATE 1:**
- [ ] Assinatura completa do use case `SaveQuickPhoto` (construtor + método principal)
- [ ] Como `resolveVisitSessionIdForPhoto` recebe a sessão (parâmetro, abstração, função)
- [ ] Padrão de mock/fake usado nos testes existentes do projeto (mockito/mocktail/fake)
- [ ] Interface do repositório de foto (o que o mock precisa implementar)
- [ ] Se existe `FakeQuickPhotoRepository` ou similar já criado em outro teste

---

## GATE 1 — Aprovação do mapeamento
> PARE. Reporte os resultados do PASSO 0 e aguarde aprovação explícita.
> O agente não escreve nenhum teste antes desta aprovação.

---

## PASSO 1 — Sugerir estrutura do arquivo de teste

Antes de criar o arquivo, o agente apresenta a estrutura proposta.

**Os dois cenários obrigatórios:** Cenário A (sessão ativa) e Cenário B (sem sessão).

---

## GATE 2 — Aprovação da estrutura proposta
> PARE. Aguarde confirmação antes de criar qualquer arquivo.

---

## PASSO 2 — Criar o arquivo de teste

**Caminho:** `test/modules/consultoria/quick_photo/save_quick_photo_test.dart`

Após criar:

```bash
flutter test test/modules/consultoria/quick_photo/save_quick_photo_test.dart --no-pub
```

---

## GATE 3 — Confirmação dos dois testes passando

---

## PASSO 3 — Rodar suite completa

Os 13 fails pré-existentes (ocorrência/drawing/MapBottomSheet) são
conhecidos e **fora do escopo** — não tentar corrigir.

---

## GATE 4 — Validação final

Se qualquer item divergir → reportar e aguardar instrução. Não commitar.

---

## PASSO 4 — Sequência de commit após aprovação do GATE 4

O agente **apresenta** a sequência — não executa sem aprovação explícita.

---

## FORA DO ESCOPO

- Corrigir os 13 testes falhando (drawing/ocorrência/MapBottomSheet)
- Corrigir os 22 warnings de analyze
- Alterar `quick_photo_list_test.dart`
- Alterar qualquer código de produção
- Criar testes para `PhotoEditorScreen`
- Definir número do IPA (decisão humana)
