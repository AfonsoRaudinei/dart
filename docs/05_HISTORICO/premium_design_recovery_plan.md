# Vistoria e Plano de Recuperação Visual Premium iOS

## 1. Análise da Regressão (Vistoria)
Ao aplicarmos as substituições em lote para o sistema `PremiumTokens`, as **primeiras telas (Login, Registro, etc.) sofreram uma drástica perda de identidade**. O diagnóstico revela os seguintes pontos críticos:

- **⚠️ Perda da Tipografia:** O antigo `soloforte_theme.dart` injetava a fonte **Inter** (`GoogleFonts.inter`) de forma global. O novo `PremiumAppTheme` omitiu essa configuração, o que forçou o Flutter a usar o *Roboto* padrão. Isso destruiu imediatamente a sensação "premium" no texto.
- **⚠️ Perda de Componentes Core (Inputs e Botões):** O tema antigo possuía configurações super customizadas para campos de texto (`InputDecorationTheme`). O `PremiumAppTheme` atual "esqueceu" isso, logo os campos do Login assumiram a forma feia e bruta do Material 3 nativo (com sublinhado ou contornos não polidos).
- **⚠️ Remoção Inadequada do Botão com Gradiente:** Os botões de Login utilizavam um aspecto vibrante através de um degradê. A substituição enxuta para fundos sólidos `brandGreen` tornou a primeira impressão monótona.

## 2. O Novo Visual Definitivo (Visão Correta)
A meta não é ser um "app feio verde". O visual **AGORA** deve ter as medidas perfeitas do iOS, mas com o estilo agronômico polido da marca, centralizado em apenas DOIS arquivos: `premium_app_theme.dart` e `design_tokens.dart`.

**Isto é o visual Premium definitivo:**
- **Tipografia:** Fonte `GoogleFonts.inter` nativamente injetada no textTheme com espaçamentos negativos (`letterSpacing`) estilo Apple.
- **Componentes:** Campos de texto (inputs) lisos, com cor de fundo super suave (`surfaceLight` e borda `hairlineLiquid`), removendo o estilo grosseiro do Android/Material.
- **Ações e Botões:** A volta dos brilhos nos botões vitais, com o `brandGreen` servindo de base para um destaque vibrante e as `tightShadow` e `premiumShadow` para elevação flutuante (iOS style).

## 3. Lixo a Eliminar (Causa do Conflito)
O arquivo `lib/ui/theme/soloforte_theme.dart` e qualquer uso das classes **SoloForteColors**, **SoloTextStyles**, **SoloSpacing**, **SoloShadows**, **SoloRadius** ou **SoloForteGradients** transformaram-se em **LIXO**.

Tentar manter compatibilidade com essas velhas estruturas e referenciar "Solo" causa conflito e código espaguete visualmente.
**Estratégia de Limpeza:** Deletar o arquivo `soloforte_theme.dart` inteiramente pelas raízes. Quaisquer resquícios perdidos no projeto sem importar quebrarão (e vamos arrumar na veia para o token limpo novo). 

## 4. Próxima Etapa: Ação e Limpeza
1. **Upgradear `PremiumAppTheme`**: Injetar TextTheme (Inter), ButtonTheme e InputDecorationTheme com base nos parâmetros premium.
2. **Restaurar `login_screen` e `GradientButton`**: Aplicar as cores brandGradient baseadas no `PremiumTokens`, recriar os botões do onboarding com visual superior e vibrante.
3. **Deletar `soloforte_theme.dart`**: Apagar o lixo velho e varrer o código para tirar imports residuais.
