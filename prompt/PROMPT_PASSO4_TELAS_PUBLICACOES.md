# PROMPT — PASSO 4: Telas de Publicações
# Executar em: GitHub Copilot / Antigravity / Cursor
# Módulo alvo: consultoria
# Tipo: feature
# Pré-requisito: PASSO 1, 2 e 3 concluídos

---

## CONTEXTO DO PROJETO

Mesmas regras absolutas do PASSO 3:
- PROIBIDO: AppBar, Navigator.pop(), FAB adicional, dados fictícios
- OBRIGATÓRIO: context.go(), Scaffold sem appBar, SafeArea no topo
- Background: Color(0xFFF2F4F7)
- Cards: branco, borderRadius 12, boxShadow(black 4%, blurRadius 8)
- Cor primária: Color(0xFF1A56DB)

**Enums disponíveis (já existem no projeto):**
```
PublicacaoTema: praga | doenca | solo | fenologia | recomendacao | outro
PublicacaoVisibility: publica | restrita
```

**Cores por tema:**
- praga → Color(0xFFDC2626)
- doenca → Color(0xFF7C3AED)
- solo → Color(0xFF92400E)
- fenologia → Color(0xFF059669)
- recomendacao → Color(0xFF1A56DB)
- outro → Color(0xFF6B7280)

Badge do tema: background cor.withOpacity(0.1), texto cor cheia, borderRadius 6-8

---

## ARQUIVO 1

**Criar em:**
`lib/modules/consultoria/publicacoes/presentation/publicacoes_list_screen.dart`

**O que fazer:**
Criar tela de lista de publicações públicas (ConsumerStatefulWidget).

**Header:**
- Texto "Publicações" (fontSize 28, bold, cor #111827)
- IconButton(Icons.add) → context.go(AppRoutes.publicacaoNova)
- SEM AppBar

**Filtro por tema (abaixo do header):**
- ListView horizontal de chips (ScrollDirection.horizontal)
- Chips: "Todos" (tema null), "Pragas", "Doenças", "Solo", "Fenologia", "Recomendação"
- Chip selecionado: bg #1A56DB, texto branco, border #1A56DB
- Chip não selecionado: bg branco, texto #374151, border #D1D5DB
- Ao selecionar: setState(_selectedTema = tema) → rebuilda a lista

**Lista:**
- Assiste publicacoesListProvider(tema: _selectedTema)
- Exibe lista de PublicacaoCard
- Empty state: "Nenhuma publicação encontrada." (cor #9CA3AF)
- Padding: fromLTRB(24, 16, 24, 100)

**PublicacaoCard:**
- onTap → context.go(AppRoutes.publicacaoDetailPath(publicacao.id))
- Linha superior: TemaBadge + data (dd/mm/yyyy, cor #9CA3AF)
- Título (fontSize 15, bold, maxLines 2, overflow ellipsis)
- Conteúdo (fontSize 13, cor #6B7280, maxLines 2, overflow ellipsis)
- Se safra != null: "Safra ${safra}" (fontSize 11, cor #9CA3AF)

---

## ARQUIVO 2

**Criar em:**
`lib/modules/consultoria/publicacoes/presentation/publicacao_form_screen.dart`

**O que fazer:**
Criar tela de criação de publicação (ConsumerStatefulWidget).

**Header:**
- Texto "Nova Publicação" (fontSize 24, bold)
- SEM AppBar

**Formulário (CustomScrollView):**

Campo 1 — Seletor de Tema:
  - Label "Tema" acima
  - Wrap de chips clicáveis para cada PublicacaoTema
  - Chip selecionado: bg #1A56DB, texto branco
  - Chip não selecionado: bg branco, border #D1D5DB
  - Labels: "Praga", "Doença", "Solo", "Fenologia", "Recomendação", "Outro"

Campo 2 — Título:
  - Label "Título"
  - TextField controlado (_tituloController)
  - Hint: "Ex: Alerta de percevejo-marrom na safra 24/25"
  - Border: OutlineInputBorder, borderRadius 10
  - Focused border: color #1A56DB, width 2

Campo 3 — Conteúdo:
  - Label "Conteúdo técnico"
  - TextField controlado (_conteudoController), maxLines 6
  - Hint: "Descreva as observações, recomendações ou alertas técnicos..."

Campo 4 — Safra (opcional):
  - Label "Safra (opcional)"
  - TextField controlado (_safraController)
  - Hint: "Ex: 2024-2025"

**Validação:**
  bool isValid = titulo.trim().isNotEmpty && conteudo.trim().isNotEmpty && tema != null

**Botão "PUBLICAR":**
  - FilledButton largura total, altura 50, borderRadius 12
  - Se isValid && !isSubmitting: bg #1A56DB
  - Se !isValid ou isSubmitting: bg #D1D5DB (desabilitado)
  - Durante submit: CircularProgressIndicator branco (20x20, strokeWidth 2)
  - Ao tocar:
    1. setState(isSubmitting = true)
    2. Chamar CreatePublicacaoUseCase.execute(authorId: authProvider.userId, tema, titulo, conteudo, safra, visibility: publica)
    3. ref.invalidate(publicacoesListProvider)
    4. context.go(AppRoutes.publicacoes)
    5. Em caso de erro: setState(isSubmitting = false, errorMessage = "Erro ao publicar. Tente novamente.")

**authorId:**
  Buscar no auth provider existente do projeto. NÃO inventar — comentar com TODO se não encontrar:
  // TODO: substituir por ID real do usuário autenticado

**Mensagem de erro:**
  Se errorMessage != null: Text abaixo dos campos, cor #DC2626, fontSize 13

---

## ARQUIVO 3

**Criar em:**
`lib/modules/consultoria/publicacoes/presentation/publicacao_detail_screen.dart`

**O que fazer:**
Criar tela de leitura de publicação (ConsumerWidget). Somente leitura — sem edição.
Recebe String publicacaoId no construtor.
Assiste publicacaoDetailProvider(id: publicacaoId).

**Layout (SafeArea + CustomScrollView):**

Linha superior: TemaBadge + data formatada (canto direito)
Título (fontSize 22, bold, cor #111827)
Se safra != null: "Safra ${safra}" (fontSize 13, cor #9CA3AF)
Separação de 20px
Card de conteúdo:
  - Container branco, padding 16, borderRadius 12, boxShadow
  - Text do conteúdo (fontSize 15, cor #374151, height 1.6)

Se fazendaRef != null OU talhaoRef != null:
  Container azul claro (bg #F0F9FF, border #BAE6FD, borderRadius 10, padding 12)
  Row: Icon(Icons.link, cor #0369A1) + Texto "Referência de campo vinculada" (cor #0369A1)

SizedBox(height: 100) no final

---

## VALIDAÇÃO QUE O AGENTE DEVE FAZER ANTES DE FINALIZAR

- [ ] Nenhum AppBar criado nos 3 arquivos
- [ ] Nenhum Navigator.pop() — apenas context.go()
- [ ] Nenhum FAB criado
- [ ] authorId tem TODO se auth provider não encontrado
- [ ] Botão desabilitado visualmente quando !isValid
- [ ] flutter analyze lib/modules/consultoria/publicacoes/presentation/ → 0 erros
- [ ] Nenhum outro módulo alterado
