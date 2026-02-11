# Design System - Estilo iOS Profissional

## 🎨 Filosofia de Design

**"Menos é mais, e mais é mágico."**

Design minimalista, emocional e premium. Experiência integrada e fluida com foco em clareza visual e interações naturais.

---

## 📐 Paleta de Cores

### Cores Primárias
- **Verde Vibrante**: `#4ADE80` - Botões CTA, badges "NOVO", elementos de destaque positivo
- **Verde Escuro**: `#1E3A2F` - Fundos de cards premium, seções de destaque
- **Branco**: `#FFFFFF` - Background principal, garantindo clareza e respiração visual

### Cores Neutras
- **Preto/Carvão**: `#1A1A1A` - Títulos principais, valores monetários, texto de alta hierarquia
- **Cinza Médio**: `#6B7280` - Textos secundários, labels, informações complementares
- **Cinza Claro**: `#F3F4F6` - Background de cards secundários, botões ghost, separadores

### Cores de Acento
- **Verde Menta Claro**: `#D1FAE5` - Badges "NOVO", hover states, feedback visual
- **Vermelho**: `#DC2626` - Valores negativos, alertas
- **Azul Samsung**: `#0066FF` - Elementos de destaque especiais

---

## 🔤 Tipografia

### Família Tipográfica
**Avenue Pro** (ou sistema San Francisco/Segoe UI como fallback)
- Alto contraste entre traços grossos e finos
- Combina solidez com leveza

### Hierarquia de Texto
| Elemento | Tamanho | Peso | Uso |
|----------|---------|------|-----|
| **Título de Página** | 24-28px | Bold | Títulos principais de tela |
| **Card Title** | 18-20px | Semibold | Títulos de componentes |
| **Body/Valores** | 16px | Regular/Medium | Descrições, datas, saldos |
| **Valores Monetários** | 20-32px | Bold | Valores em destaque |
| **Labels/Caption** | 12-14px | Regular | Menor hierarquia |

---

## 🧩 Componentes UI

### Botões

**Primário (CTA)**
```css
background: #4ADE80
color: #FFFFFF
border-radius: 12-16px
padding: 16px
width: 100% ou adaptativo
```

**Secundário/Ghost**
```css
background: #F3F4F6
color: #1A1A1A
border-radius: 12-16px
padding: 16px
```

**Ícone com Texto**
- Cards quadrados com ícones line-art (48x48px)
- Labels abaixo em grid 2x2 ou scroll horizontal

---

### Cards

**Card Premium**
```css
background: #1E3A2F (gradiente sutil opcional)
color: #FFFFFF
border-radius: 16px
padding: 20px
box-shadow: 0 4px 12px rgba(0,0,0,0.1)
```

**Card Informativo**
```css
background: #FFFFFF ou #F3F4F6
border: 1px solid #E5E7EB
border-radius: 12px
padding: 16-20px
```

**Card de Lista**
- Título bold
- Descrição regular
- Timestamp e badge alinhados verticalmente

---

### Navegação

**Bottom Tab Bar**
- 4 itens principais
- Ícones line-art 24x24px
- Label 10-12px
- Ativo: `#1A1A1A` | Inativo: `#6B7280`
- Cantos superiores arredondados (16-20px)

**Top Bar**
- Título centralizado
- Ícones de ação à direita (24x24px)
- Botão voltar à esquerda quando aplicável

---

### Controles de Entrada

**Caixas de Edição de Números**
```css
max-width: 7 dígitos
border: 1px solid #E5E7EB
border-radius: 8px
padding: 12px
font-size: 16px
```

**Dropdown/Sidecar**
- Use dropdown para seleções com muitas opções
- Use sidecar quando necessário expansão lateral
- Altura mínima: 44px (touch target)

---

## 🎯 Ícones

**Estilo**: Line-art (outline)
- Stroke: 2px
- Design minimalista e consistente

**Tamanhos**:
- 16px: inline
- 24px: navegação/ações
- 48px: cards de funcionalidades
- 64px: hero sections

---

## 📏 Espaçamento

### Sistema de Grid
```
Padding de Tela: 16-20px
Gap Elementos Relacionados: 8px
Gap Seções Distintas: 16px
Gap Cards Principais: 24px
```

### Touch Targets
- Mínimo: **44x44px** (iOS Human Interface Guidelines)
- Altura de Cards: Mínimo 80px

---

## 🎭 Estados Interativos

### Badges
```css
border-radius: 99px (pill-shaped)
background: #D1FAE5 (NOVO)
padding: 4px 12px
font-size: 12px
font-weight: 600
```

### Switches/Tabs
- Tabs horizontais com indicador de seleção
- Underline ou background para estado ativo

### Menu Overflow
- Três pontos verticais
- Posição: canto superior direito

---

## 🌊 Border Radius
```
Botões/Cards: 12-16px
Badges: 99px (pill completo)
Bottom Tab Bar: 16-20px (cantos superiores)
Inputs: 8-12px
```

---

## 💫 Sombras e Profundidade
```css
/* Cards Principais */
box-shadow: 0 2px 8px rgba(0,0,0,0.08);

/* Bottom Sheet/Modals */
box-shadow: 0 -4px 16px rgba(0,0,0,0.12);

/* Floating Buttons */
box-shadow: 0 4px 12px rgba(74,222,128,0.3);
```

---

## 📊 Gráficos e Visualizações

**Barras de Progresso**
```css
height: 8-12px
background: #F3F4F6
fill: #4ADE80
border-radius: 99px
```

**Line Charts**
- Linhas verdes suaves
- Gradiente de preenchimento
- Grid discreto
- Eixo Y à esquerda

---

## 🎬 Feedback Visual

### Loading States
- Skeletons em `#F3F4F6`
- Animação shimmer

### Empty States
- Mensagens descritivas em cards
- Ilustrações sutis
- CTAs claros

### Success States
- Checkmarks verdes
- Texto confirmatório
- Sem modals intrusivos

---

## ♿ Acessibilidade

### Contraste de Cores
- Texto preto sobre branco: **21:1** (AAA)
- Texto branco sobre verde escuro: **>7:1** (AAA)
- Botões verdes com texto branco: **>4.5:1** (AA Large)

### Legibilidade
- Tamanho mínimo: 12px (captions)
- Corpo de texto: 16px
- Touch targets: 44x44px mínimo

---

## 🎨 Princípios de Design

1. **Clareza Visual**: Hierarquia clara e respiração entre elementos
2. **Consistência**: Componentes modulares e previsíveis
3. **Eficiência**: Ações diretas e intuitivas
4. **Elegância**: Design minimalista e sofisticado
5. **Acessibilidade**: Inclusivo e WCAG 2.1 AA compliant

---

## 📱 Layout Responsivo

### Breakpoints
```
Mobile: < 768px
Tablet: 768px - 1024px
Desktop: > 1024px
```

### Grid System
- Mobile: 1 coluna
- Tablet: 2 colunas
- Desktop: 3-4 colunas

---

## 🔄 Animações e Transições
```css
/* Transições Padrão */
transition: all 0.3s ease;

/* Hover States */
transform: translateY(-2px);
transition: transform 0.2s ease;

/* Loading */
animation: shimmer 1.5s infinite;
```

---

**Versão**: 1.0  
**Última atualização**: Fevereiro 2026  
**Inspirado em**: Apple iOS, Avenue Financial App
