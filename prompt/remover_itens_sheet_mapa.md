# PROMPT 1/3 — Remover "Foto rápida" e "Inversão vegetal" do sheet do mapa
**Agente:** Engenheiro Sênior Flutter/Dart
**Arquivo salvo em:** `prompt/remover_itens_sheet_mapa.md`
**Data:** 17/08/2026
**Risco:** BAIXO — remoção de itens de lista, sem alterar contratos
**PROMPT BASE ATIVO:** SOLOFORTE_PROMPT_BASE_v2.1
**Módulo afetado (prompt):** `operacao/` — **descoberta:** host real é `lib/ui/` (política 4A)
**Bounded context:** `ui/` (sheet de ações do mapa)
**Tipo:** remoção cirúrgica de itens de UI
**Objetivo:** Remover "Foto rápida" e "Inversão vegetal" do sheet de contexto da visita
**Altera contrato de interface?** NÃO
**Altera fronteira entre módulos?** NÃO
**arch_check.sh:** OBRIGATÓRIO exit 0

---

## CONTEXTO

O sheet de contexto da visita exibe um menu de ações disponíveis no campo:
Resultado, Antes/Depois, Avaliação, Ocorrência, Foto rápida, Inversão vegetal.

Decisão de produto: Foto rápida e Inversão vegetal devem ser **removidos**
desse menu. A captura de foto com inversão vegetal agora é feita **dentro**
dos slots de foto dos cases (Antes/Depois, Resultado, Avaliação) — não como
ação avulsa no sheet do mapa.

Manter esses dois itens no menu é confuso: cria fotos sem contexto de case,
que ficam órfãs no sistema.

---

## OBJETIVO

Remover os itens "Foto rápida" e "Inversão vegetal" da lista de ações
do sheet de contexto da visita no mapa. Nenhuma outra alteração.

---

## PASSO 0 — DESCOBERTA OBRIGATÓRIA

Execute todos os comandos abaixo e reporte antes de qualquer alteração.

```bash
# 1. Localizar o sheet de contexto da visita (onde o menu de ações está)
grep -rn "Foto rápida\|foto_rapida\|FotoRapida\|fotoRapida" lib/ --include="*.dart"

# 2. Localizar onde "Inversão vegetal" aparece no menu do sheet
grep -rn "Inversão vegetal\|inversao_vegetal\|InversaoVegetal\|inversaoVegetal" lib/ --include="*.dart" | grep -v "test/"

# 3. Localizar o arquivo do sheet de contexto da visita
grep -rn "Resultado\|Antes/Depois\|Avaliação\|Ocorrência" lib/modules/operacao --include="*.dart" -l

# 4. Verificar se Foto rápida e Inversão vegetal têm handlers/use cases próprios
grep -rn "FotoRapidaUseCase\|InversaoVegetalUseCase\|onFotoRapida\|onInversao" lib/ --include="*.dart"

# 5. Confirmar estrutura da lista de itens do sheet
grep -rn "SheetMenuItem\|menuItem\|_buildItem\|_buildMenuItem\|ListTile" lib/modules/operacao --include="*.dart" | head -30
```

**Reportar obrigatoriamente antes do GATE 1:**
- [ ] Arquivo exato onde os dois itens estão declarados
- [ ] Linha exata de cada item (Foto rápida e Inversão vegetal)
- [ ] Se cada item tem handler/callback próprio ou é inline
- [ ] Se há testes que referenciam esses dois itens

---

## GATE 1 — Aprovação do mapeamento
> PARE. Reporte os resultados e aguarde aprovação explícita.

---

## PASSO 1 — Remover os dois itens

Com base no mapeamento do PASSO 0, remover:
- O item "Foto rápida" da lista de ações do sheet
- O item "Inversão vegetal" da lista de ações do sheet
- Os callbacks/handlers associados a esses dois itens, **se e somente se**
  forem exclusivos deste sheet (não compartilhados com outros lugares)

**Regras absolutas:**
- Remover apenas o que foi mapeado no PASSO 0
- NÃO remover o widget/serviço de Foto rápida — apenas a entrada no menu
- NÃO remover a lógica de Inversão vegetal — apenas a entrada no menu
- NÃO alterar os demais itens (Resultado, Antes/Depois, Avaliação, Ocorrência)
- NÃO alterar a ordem dos itens restantes além do necessário
- NÃO alterar o estilo ou layout do sheet

O agente lista as linhas exatas que serão removidas e aguarda aprovação.

---

## GATE 2 — Aprovação das linhas a remover
> PARE. Mostre exatamente o que será removido (diff) e aguarde confirmação.

---

## PASSO 2 — Executar remoção e validar

Após aprovação, executar a remoção e rodar:

```bash
bash tool/arch_check.sh
flutter analyze
flutter test --no-pub
```

---

## GATE 3 — Checklist de encerramento

| Verificação | Resposta |
|---|---|
| `arch_check.sh` exit 0? | |
| `flutter analyze` zero issues? | |
| Testes passando? | |
| Itens restantes do sheet inalterados? | |
| Lógica de Foto rápida/Inversão vegetal preservada? | |
| Outros módulos tocados? | (deve ser NÃO) |

---

## RELATÓRIO FINAL

| Item | Detalhe |
|---|---|
| Arquivo alterado | (preencher) |
| Linhas removidas | (preencher) |
| Handlers removidos | (preencher — se exclusivos) |
| arch_check.sh | exit 0 |
| Próximo prompt | 2/3 — Ocultar aba Mídia no Relatório |
