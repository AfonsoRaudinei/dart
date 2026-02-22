# design_soloforte.md

## 0) Status do documento (contrato)
Este arquivo é a **fonte única da verdade** do visual do SoloForte.

- ✅ Objetivo: padronizar a UI para ser **premium do agro**, **confiável**, **organizada** e **operacional**.
- 🚫 Proibido: criar estilos paralelos fora deste documento.
- 🧱 Regra de ouro: **qualquer melhoria visual não pode alterar lógica, estado, contratos, regras de negócio ou navegação**.

---

## 1) Identidade & narrativa (o “porquê”)

### 1.1 Posicionamento
**SoloForte é tecnologia premium do agro orientada à decisão (inteligência operacional).**

- Não é fintech.
- Não é ERP poluído.
- Não é app “startup neon”.
- Não é “bonitinho” acima de útil.

### 1.2 Conceito central
> **Clareza técnica com elegância silenciosa.**

**Elegância** vem de:
- hierarquia
- alinhamento
- consistência
- restrição (dizer “não”)

### 1.3 O que o usuário deve sentir
Ao abrir o SoloForte:
- **Controle** (sei onde estou e o que fazer)
- **Confiabilidade** (parece estável e maduro)
- **Velocidade operacional** (decido rápido)
- **Precisão** (dados e mapas parecem instrumentação)

### 1.4 Antiprincípios (o que mataríamos sem dó)
- Efeitos por efeito (glow, neon, blur exagerado)
- 10 estilos de card
- 8 pesos tipográficos
- Gradientes dramáticos
- “Festa de cores”
- UI que muda estrutura entre light/dark

---

## 2) Princípios de interface (como se decide)

### 2.1 Informação progressiva (camadas)
Nunca mostrar tudo de uma vez.

- **Nível 1**: essencial (1 ação principal + 1 indicador)
- **Nível 2**: detalhamento (breakdown, filtros simples)
- **Nível 3**: técnico/avançado (filtros completos, parâmetros, export)

Regra:
- Se o usuário precisa de “muita coisa”, isso vai para N2/N3 via **bottom sheet** ou tela dedicada, mas mantendo clareza.

### 2.2 Consistência é lei
- Mesmo espaçamento
- Mesmo raio
- Mesmo padrão de sombra
- Mesmo padrão de lista
- Mesma hierarquia tipográfica

O usuário deve sentir que o app é um sistema, não um conjunto de telas.

### 2.3 Previsibilidade de layout
- Componentes no mesmo lugar
- Ações em locais previsíveis
- Ícones consistentes
- Estados visuais consistentes

### 2.4 Segurança (visual)
O visual deve passar “não vai dar erro”.

Isso se consegue com:
- bordas discretas
- separadores finos
- contrastes corretos
- tipografia legível
- densidade controlada

---

## 3) Tokens e regras globais (o “sistema”)

### 3.1 Grid / espaçamento (único sistema permitido)
Use apenas:
- **8**
- **16**
- **24**
- **32**

Aplicação típica:
- Padding de tela: **16**
- Espaço entre elementos relacionados: **8**
- Espaço entre seções: **16** ou **24**
- Separação de blocos principais: **24** ou **32**

🚫 Proibido: 10, 12, 14, 18, 20 “porque ficou bom”.

### 3.2 Radius (únicos valores permitidos)
- **16**: cards, botões, inputs, tiles
- **24**: bottom sheets, painéis flutuantes
- **99**: pills/badges

🚫 Proibido: radius aleatório por componente.

### 3.3 Dividers (separadores)
Separador padrão:
- 1px
- cor discreta
- usado para organizar listas e blocos densos

### 3.4 Sombras (profundidade mínima)
Regra:
- Sombra é **só para separar camadas** (ex: sheet sobre mapa).
- Cards em listas densas preferem **divider** e background, não sombra.

Sombras (conceito):
- Card: sombra leve e baixa
- Bottom sheet: sombra um pouco mais evidente (ainda discreta)
- Floating controls: sombra mínima

🚫 Proibido: sombras pesadas ou “cartoon”.

### 3.5 Estados interativos (sem show)
- Press: leve mudança de opacidade / surface
- Focus: borda/acento discreto
- Selected: acento claro e consistente
- Disabled: redução de contraste, sem “cinza morto” exagerado

---

## 4) Paletas oficiais

### 4.1 Light mode (padrão)
Base:
- **Background**: `#FFFFFF`
- **Surface**: `#F3F4F6`
- **Primary Text**: `#1A1A1A`
- **Secondary Text**: `#6B7280`
- **Divider / Border**: `#E5E7EB`

Marca:
- **Green Accent (técnico)**: `#4ADE80` (usar com disciplina)
- **Mint (feedback suave)**: `#D1FAE5`
- **Danger**: `#DC2626`

Regras:
- Verde **não** é fundo dominante de tela.
- Verde é **sinal**, não “papel de parede”.
- Cores extras só entram por motivos técnicos (ex: NDVI), nunca por “estética”.

### 4.2 Dark mode técnico (estrutura idêntica ao light)
Base:
- **Background**: `#0F1113`
- **Surface**: `#161A1D`
- **Surface Elevated**: `#1E2428`
- **Primary Text**: `#E6E6E6`
- **Secondary Text**: `#9CA3AF`
- **Divider / Border**: `#2A3136`

Marca:
- **Green Accent (dessaturado)**: manter verde, mas evitar “neon”
- **Danger**: `#DC2626` (sem brilho)

Regras:
- 🚫 preto puro `#000000` (parece vazio e agressivo)
- 🚫 glow / neon
- ✅ contraste limpo e legível
- ✅ “sala de controle”, não “modo hacker”

---

## 5) Tipografia (hierarquia e disciplina)

### 5.1 Pesos permitidos
Apenas:
- **700** (títulos)
- **600** (subtítulos / labels fortes)
- **400** (texto e descrições)

🚫 Proibido: inventar 500/800/900 em toda tela.

### 5.2 Tamanhos recomendados (não extrapolar)
- Page Title: **22–24**
- Section Title: **16–18**
- Body: **14–16**
- Caption/Meta: **12–13**
- Numbers/Key Value: **24–32** (casos específicos)

Regras:
- Nunca ter mais de **4 tamanhos** numa mesma tela.
- Números importantes: **maiores**, com unidade menor.
- Labels sempre menores que o dado.

### 5.3 Números e alinhamento (operacional)
- Valores e métricas em listas: **alinhados à direita**.
- Unidades: menores e em secundário.
- Variação (+/−): menor e ao lado, nunca dominando.

### 5.4 Texto (microcopy)
Tom:
- curto
- objetivo
- operacional

Exemplos de estilo (sem inventar dados):
- “Ocorrência registrada”
- “Camada ativada”
- “Sem resultados”
- “Ajuste o filtro”

---

## 6) Ícones (linguagem visual)
Estilo:
- outline / line-art
- traço fino consistente
- sem ícones “gordos” e sem mistura de famílias diferentes

Tamanhos padrão:
- 16: inline
- 20: em linhas/tables
- 24: ações e navegação
- 32: botões flutuantes maiores (quando necessário)
- 48: tiles de função (casos raros)

Regras:
- Um único set de ícones por app (SF-style).
- Ícone colorido só quando representar dados (ex: camadas/NDVI), não por decoração.

---

## 7) Componentes base (contratos visuais)

> **Regra:** componentes são a “gramática” do app. Não crie variações paralelas.

### 7.1 Botão primário (CTA)
Uso:
- única ação principal da tela

Visual:
- background: verde (accent)
- texto: branco
- radius: 16
- altura mínima: 48
- padding horizontal: 16

Estados:
- normal: sólido
- pressed: leve redução de opacidade
- disabled: baixa saturação/contraste (sem sumir)

### 7.2 Botão secundário
Uso:
- ações de menor prioridade (ex: “Ver detalhes”, “Filtrar”)

Visual:
- background: surface
- texto: primário
- borda: opcional, bem sutil (divider)
- radius: 16
- altura: 48

### 7.3 Botão “ghost”
Uso:
- ação menos importante ainda, contextual

Visual:
- background: transparente
- texto: secundário/primário
- sem borda pesada
- apenas quando realmente necessário (evitar proliferar)

### 7.4 Inputs (texto)
Regras:
- radius: 16
- padding interno: 16
- label: 12–13 (secundário)
- texto: 14–16
- focus: acento sutil, nunca “neon”

### 7.5 Inputs numéricos (regra dos 7 dígitos)
Regra do produto:
- caixas de edição numérica devem comportar **no máximo 7 dígitos** visíveis com conforto.

Visual:
- largura fixa adequada a 7 dígitos
- alinhamento do número: direita
- unidade fora do campo (ou como suffix discreto)
- máscara/validação não deve quebrar layout

🚫 Proibido: campo gigante para número pequeno (parece amador).
🚫 Proibido: campo minúsculo que corta número (parece bug).

### 7.6 Cards
Existem só dois “sabores”:

**Card informativo (padrão)**
- fundo: branco/surface
- borda: 1px divider
- radius: 16
- padding: 16
- sem sombra pesada

**Card destaque (raro)**
- usado com parcimônia (1 por tela, quando necessário)
- background: surface elevated (no dark) ou branco (no light)
- borda sutil + leve sombra, se realmente precisar separar camada

🚫 Proibido: 6 estilos de card.

### 7.7 List item técnico (padrão em telas densas)
Estrutura:
- esquerda: título + subtexto
- direita: valor principal + meta (opcional)
- separador: 1px

Isso é o “Microsoft interno” com roupa Apple.

### 7.8 Badges / Pills
- radius: 99
- padding: 4x12 (ou 6x12)
- texto: 12
- cores: mint para “novo/ativo leve”, vermelho para alerta

---

## 8) Padrões de layout por tipo de tela

### 8.1 Telas densas (Relatórios, Clientes, Listas)
Objetivo:
- escaneabilidade
- decisão rápida

Regras:
- topo simples (título + filtro compacto)
- conteúdo organizado por seções
- listas com divisores, não sombras
- números alinhados à direita

Estrutura recomendada:
1. Cabeçalho (título + período/filtro)
2. Métrica principal (uma por tela quando possível)
3. Seção breakdown (lista técnica)
4. Ação final (CTA ou export) quando aplicável

### 8.2 Telas “ação” (Cadastro, Formulários)
Regras:
- 1 CTA principal
- inputs com labels consistentes
- validação clara e curta
- mensagens sem drama

### 8.3 Telas “configuração”
Regras:
- lista vertical
- seções com títulos discretos
- alternadores/switches padronizados
- nada de layout experimental

---

## 9) Módulos (aplicação real no SoloForte)

### 9.1 Mapa (Map-first)
O mapa é **a tela raiz funcional**.

Regras:
- fullscreen de verdade
- sem header pesado
- controles flutuantes discretos
- bottom sheets como interação principal
- camadas e ferramentas por sheet (informação progressiva)

Controles flutuantes:
- botões circulares
- ícones 24
- sombra mínima
- distância das bordas: 16

Bottom sheets no mapa:
- fundo sólido (não transparente demais)
- radius 24
- handle discreto
- divisores internos em listas

Dark mode do mapa:
- mesma estrutura
- apenas troca de paleta

### 9.2 Relatórios
Objetivo: “decidir rápido”.

Regras:
- começar por 1 métrica principal
- não empilhar 10 cards
- breakdown por lista técnica
- filtros avançados dentro de sheet/modal leve

### 9.3 Clientes
Objetivo: “agir rápido”.

Regras:
- lista limpa
- avatar pequeno
- nome forte
- subinfo discreta
- status como pill discreta
- ações secundárias (ligar, abrir mapa, etc.) devem ser contextuais e não poluir

### 9.4 Outros módulos (padrão)
O mesmo padrão se aplica:
- clareza
- consistência
- densidade controlada
- informação progressiva

---

## 10) Mapas, camadas e dados técnicos (sem carnaval)

### 10.1 Cores técnicas (NDVI, etc.)
Cores de dados (ex: NDVI) são permitidas porque são **semânticas**.
Mas:
- devem ser discretas
- sem saturação absurda
- com legenda clara
- sem competir com UI

### 10.2 Legendas e escalas
- legenda compacta
- texto pequeno e legível
- valores e unidades claros

### 10.3 Marcadores e overlays
- reduzir poluição
- usar clustering quando aplicável
- estados claros (selected/hover)
- não usar 5 tipos de marker ao mesmo tempo

---

## 11) Acessibilidade (mínimo aceitável)
- Touch targets: mínimo 44x44
- Contraste:
  - light: texto primário bem escuro sobre branco
  - dark: texto primário claro sobre fundo profundo
- Não usar texto abaixo de 12

---

## 12) Regras imutáveis (guard rails)

### 12.1 Proibições absolutas
- ❌ Alterar lógica, estado, contratos ou regras por causa de UI
- ❌ Criar novo sistema de cores fora da paleta
- ❌ Criar novos radius
- ❌ Criar novos espaçamentos fora do sistema 8/16/24/32
- ❌ Trocar estrutura entre light/dark (apenas paleta)
- ❌ Gradientes dramáticos, glow, neon
- ❌ Sombra pesada em lista densa

### 12.2 “Se não está no documento, não existe”
Qualquer novo componente/padrão:
- deve entrar aqui primeiro
- e só depois ser usado

---

## 13) Checklist de revisão (antes de aprovar qualquer tela)

### 13.1 Consistência
- [ ] Espaçamento só 8/16/24/32
- [ ] Radius só 16/24/99
- [ ] Tipografia: no máximo 3 pesos
- [ ] No máximo 4 tamanhos de fonte na tela

### 13.2 Hierarquia
- [ ] Existe 1 ação principal clara?
- [ ] O foco da tela está evidente em 3 segundos?
- [ ] Números críticos estão destacados corretamente?

### 13.3 Poluição
- [ ] Tem sombra demais?
- [ ] Tem cor demais?
- [ ] Tem card demais?

### 13.4 Dark mode
- [ ] Estrutura idêntica ao light?
- [ ] Contraste ok?
- [ ] Sem neon/glow?

### 13.5 Regra do produto
- [ ] Inputs numéricos respeitam 7 dígitos?

---

## 14) Encerramento (o “norte”)
SoloForte é um **instrumento**.  
O design deve ser **silencioso e impecável**.

Se a interface virar decoração, perdeu.

O usuário não abre o SoloForte para ver UI bonita.  
Ele abre para **decidir e operar melhor**.

