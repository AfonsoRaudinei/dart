# PROMPT — Decompor `novo_case_sheet.dart` (933 linhas → abaixo de 900)

**Tipo:** Refatoração interna — sem alterar comportamento
**Risco:** BAIXO — sem alteração de contrato ou fronteira
**Arquivo alvo:** `lib/modules/marketing/presentation/screens/novo_case_sheet.dart`
**Linhas atuais:** 933
**Limite:** 900
**Excesso:** 33 linhas

---

## OBJETIVO

Reduzir `novo_case_sheet.dart` para abaixo de 900 linhas extraindo
widgets privados para arquivos separados dentro do mesmo módulo,
sem alterar comportamento, estado ou contrato público.

---

## REGRAS

- NÃO alterar a assinatura pública de NovoCaseSheet
- NÃO alterar providers ou estado
- NÃO alterar navegação
- NÃO mover para outro módulo
- NÃO alterar testes existentes
- Apenas extrair widgets internos para arquivos no mesmo diretório

---

## ESTRATEGIA

O arquivo tem 933 linhas — excesso mínimo de 33 linhas.
Identificar o maior widget privado interno (provavelmente um formulário,
seção de fotos ou seção de ROI) e extrair para arquivo separado no mesmo
diretório:

```
lib/modules/marketing/presentation/screens/
  novo_case_sheet.dart                     (arquivo principal — abaixo de 900)
  widgets/
    case_photo_section.dart                (se existir seção de fotos)
    case_roi_section.dart                  (se existir seção de ROI)
    case_form_fields.dart                  (campos do formulário)
```

---

## PASSO A PASSO

1. Ler `novo_case_sheet.dart` completo
2. Identificar os widgets privados (classe com `_` ou métodos que retornam Widget)
3. Selecionar o(s) que somam pelo menos 40 linhas para extração
4. Criar arquivo(s) em `widgets/` dentro do mesmo diretório
5. Substituir o bloco extraído por import + referência ao novo widget
6. Confirmar que `novo_case_sheet.dart` ficou abaixo de 900 linhas
7. Confirmar que o app compila sem erros

---

## VALIDACAO FINAL

- [ ] `novo_case_sheet.dart` abaixo de 900 linhas
- [ ] Comportamento visual inalterado
- [ ] Nenhum provider ou estado alterado
- [ ] App compila sem erros
- [ ] `bash tool/arch_check.sh` Regra 3: sem novo violador para este arquivo
