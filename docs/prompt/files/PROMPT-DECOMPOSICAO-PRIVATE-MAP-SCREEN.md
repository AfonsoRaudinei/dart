# PROMPT — Decompor `private_map_screen.dart` (981 linhas → abaixo de 900)

**Tipo:** Refatoração interna — sem alterar comportamento
**Risco:** MÉDIO — arquivo central do mapa, cuidado redobrado
**Arquivo alvo:** `lib/ui/screens/private_map_screen.dart`
**Linhas atuais:** 981
**Limite:** 900
**Excesso:** 81 linhas

---

## OBJETIVO

Reduzir `private_map_screen.dart` para abaixo de 900 linhas extraindo
widgets ou métodos auxiliares para arquivos separados no mesmo diretório,
sem alterar comportamento do mapa, estado, navegação Map-First ou SmartButton.

---

## REGRAS CRITICAS

- NÃO alterar o SmartButton (comportamento, ícone, ação)
- NÃO alterar rotas ou navegação
- NÃO alterar MapContext ou estado do mapa
- NÃO criar sub-rotas de /map
- NÃO mover para outro módulo
- NÃO alterar providers globais
- Apenas extrair widgets/métodos auxiliares para arquivos no mesmo diretório

---

## ESTRATEGIA

`private_map_screen.dart` é o arquivo central do mapa — máxima cautela.
Extrair apenas partes seguras: overlays, sheets, widgets informativos.
NÃO extrair a lógica central do mapa ou o Scaffold principal.

Estrutura sugerida:
```
lib/ui/screens/
  private_map_screen.dart          (arquivo principal — abaixo de 900)
  widgets/
    map_overlay_controls.dart      (controles flutuantes sobre o mapa)
    map_context_indicator.dart     (indicador de contexto ativo)
```

---

## PASSO A PASSO

1. Ler `private_map_screen.dart` completo
2. Identificar APENAS widgets auxiliares seguros para extração:
   - Overlays visuais sem lógica de estado
   - Indicadores informativos
   - Botões secundários que não sejam o SmartButton
3. NÃO extrair: Scaffold, MapWidget, SmartButton, providers, initState
4. Extrair o suficiente para chegar abaixo de 900 linhas
5. Criar arquivo(s) em `widgets/` no mesmo diretório
6. Confirmar que `private_map_screen.dart` ficou abaixo de 900 linhas
7. Confirmar que o mapa funciona identicamente

---

## MAP-FIRST CHECK

- Move raiz funcional? NAO
- Altera SmartButton? NAO
- Altera navegacao? NAO
- Cria sub-rota de /map? NAO

Se qualquer resposta for SIM → PARAR IMEDIATAMENTE.

---

## VALIDACAO FINAL

- [ ] `private_map_screen.dart` abaixo de 900 linhas
- [ ] SmartButton inalterado (icone, acao, posicao)
- [ ] Navegacao Map-First inalterada
- [ ] MapContext inalterado
- [ ] App compila sem erros
- [ ] Mapa renderiza corretamente
- [ ] `bash tool/arch_check.sh` Regra 3: sem novo violador para este arquivo
