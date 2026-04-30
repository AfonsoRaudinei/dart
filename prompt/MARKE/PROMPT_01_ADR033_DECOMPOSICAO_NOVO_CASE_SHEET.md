# PROMPT 01 — ADR-033: Decomposição Preventiva do `NovoCaseSheet`

**Especialização do agente:** Especialista em Clean Architecture Flutter/Dart — Decomposição de Widgets  
**Tipo:** ALTERAÇÃO ESTRUTURAL — Refatoração interna sem alteração de contrato externo  
**Módulo:** `marketing/`  
**Rota afetada:** Nenhuma (sheet não tem rota própria)

---

## CONTEXTO

`NovoCaseSheet` está em **845 linhas**. O limite do projeto é 900 linhas (Regra 3 do `arch_check.sh`). Qualquer toque futuro nesse arquivo pode acionar decomposição forçada em momento inoportuno. Este prompt executa a decomposição **preventiva e planejada**, antes de atingir o limite.

**Contrato externo IMUTÁVEL:**
```dart
NovoCaseSheet({
  required double lat,
  required double lng,
  required VoidCallback onClose,
  required void Function(MarketingCase) onPublicar,
})
```
Nenhum chamador (incluindo `NovoCaseModalLauncher`) pode ser afetado.

---

## PASSO 0 — LOCALIZAÇÃO OBRIGATÓRIA

```bash
find lib/ -name "novo_case_sheet.dart"
find lib/ -name "novo_case_modal_launcher.dart"
wc -l lib/modules/marketing/presentation/screens/novo_case_sheet.dart
```

Reporte caminhos exatos e contagem de linhas antes de qualquer ação.

---

## PASSO 1 — LEITURA E MAPEAMENTO (sem tocar nada)

Ler `novo_case_sheet.dart` completo e produzir mapa de seções:

```
Linhas X–Y   : _IdentificacaoSection (campos: Produtor, Produto, Localização)
Linhas X–Y   : _ProdutividadeSection (Valor + unidade)
Linhas X–Y   : _ComparacaoAnteDepoisSection (Ganho, Economia, fotos)
Linhas X–Y   : _DadosTalhaoSection (Nome, Tamanho)
Linhas X–Y   : _AvaliacoesList (lista de AvaliacaoBlocoWidget)
Linhas X–Y   : _VendedorSection (Nome, Telefone)
Linhas X–Y   : _FotoPrincipalSection
Linhas X–Y   : _ConfirmacaoBar (botão publicar / salvar rascunho)
```

**Reportar antes de prosseguir. Não assumir — ler o código real.**

---

## PASSO 2 — PLANEJAMENTO DE DECOMPOSIÇÃO

Critérios para extração em widget privado separado (`part of` ou arquivo próprio em `widgets/`):

- Seção com >50 linhas de build
- Seção com estado local próprio (controllers, focus nodes)
- Seção reutilizável em outros contexts futuros

**Regra de extração:**
- Widgets extraídos ficam em `lib/modules/marketing/presentation/widgets/`
- Nomeação: `novo_case_<secao>_section.dart`
- Parâmetros: apenas o que a seção precisa (controllers já existentes passados via parâmetro, não criados dentro)
- Nunca usar `InheritedWidget` ou `Provider` dentro das seções extraídas — estado fica no sheet pai
- Estado mutável (`TextEditingController`, `FocusNode`) permanece no `_NovoCaseSheetState`

**Meta:** `novo_case_sheet.dart` ≤ 500 linhas após decomposição.

---

## PASSO 3 — EXECUÇÃO (arquivo por arquivo)

Para cada widget extraído:

**Gate 3.A:** Criar o arquivo do widget extraído com conteúdo correto  
**Gate 3.B:** Substituir o trecho no `novo_case_sheet.dart` pelo widget extraído  
**Gate 3.C:** `flutter analyze lib/modules/marketing/` → 0 novos erros antes de continuar para o próximo

Não criar todos os arquivos de uma vez. Um por vez, com validação.

---

## PASSO 4 — RESTRIÇÕES ABSOLUTAS

❌ Não alterar o construtor público de `NovoCaseSheet`  
❌ Não mover `_formKey` para fora do `_NovoCaseSheetState`  
❌ Não criar providers novos  
❌ Não alterar `NovoCaseModalLauncher`  
❌ Não alterar `marketing_providers.dart`  
❌ Não usar `part of` se o widget tiver mais de 80 linhas (arquivo próprio)  
❌ Não refatorar lógica de negócio — apenas mover UI  

---

## PASSO 5 — VALIDAÇÃO FINAL

```bash
wc -l lib/modules/marketing/presentation/screens/novo_case_sheet.dart
flutter analyze lib/modules/marketing/
bash tool/arch_check.sh
```

Esperado:
- `novo_case_sheet.dart` ≤ 500 linhas
- `flutter analyze`: 0 novos erros
- `arch_check.sh`: Exit 0 (3 violações preexistentes mantidas, nenhuma nova)

**Responder:**

| Verificação | Resultado |
|---|---|
| Contrato NovoCaseSheet alterado? | NÃO |
| NovoCaseModalLauncher alterado? | NÃO |
| Providers alterados? | NÃO |
| arch_check.sh Exit 0? | SIM |
| novo_case_sheet.dart ≤ 500L? | SIM |

---

## ENCERRAMENTO

Decomposição preventiva concluída. `NovoCaseSheet` dentro do limite.  
Nenhum contrato externo, provider ou rota foi alterado.
