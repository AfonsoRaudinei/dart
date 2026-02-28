# PROMPT — PASSO 3: Telas de Relatórios
# Executar em: GitHub Copilot / Antigravity / Cursor
# Módulo alvo: consultoria
# Tipo: feature
# Pré-requisito: PASSO 1 (providers) e PASSO 2 (rotas) concluídos

---

## CONTEXTO DO PROJETO

Projeto Flutter com arquitetura Map-First + Clean + Riverpod.
Regras absolutas:
- PROIBIDO: AppBar, Navigator.pop(), FAB adicional, dados fictícios
- OBRIGATÓRIO: context.go(), Scaffold sem appBar, SafeArea no topo
- SmartButton global já existe — não criar outro FAB
- Offline-first: UI nunca bloqueia aguardando API
- Padrão de provider: @riverpod (ADR-008)
- Estado de loading: CircularProgressIndicator(color: Color(0xFF1A56DB))
- Background padrão das telas: Color(0xFFF2F4F7)
- Cards: branco, borderRadius 12, boxShadow(black 4%, blurRadius 8)
- Cor primária: Color(0xFF1A56DB)

---

## ARQUIVO 1

**Criar em:**
`lib/modules/consultoria/relatorios/presentation/relatorios_list_screen.dart`

**O que fazer:**
Criar tela de lista de relatórios (ConsumerStatefulWidget) com TabBar de 2 abas.

**Aba "Meus":**
- Assiste relatoriosListProvider(clientId: clientId)
- clientId vem do auth provider existente no projeto (não inventar — buscar o provider de usuário autenticado já existente)
- Exibe lista de RelatorioCard
- Empty state: texto "Nenhum relatório encontrado."

**Aba "Compartilhados":**
- Empty state: texto "Nenhum relatório compartilhado."
- Sem lógica ainda — apenas estrutura

**Header da tela:**
- Texto "Relatórios" (fontSize 28, bold, cor #111827)
- IconButton(Icons.add) no canto direito → context.go(AppRoutes.publicacaoNova)
- SEM AppBar — header é widget manual com Padding(fromLTRB(24, 20, 24, 0))

**RelatorioCard:**
- GestureDetector com onLongPress → abre showModalBottomSheet
- Exibe: título (title ?? farmName), StatusBadge, farmName, período formatado (dd/mm/yyyy → dd/mm/yyyy)
- Container branco, borderRadius 12, boxShadow sutil

**StatusBadge:**
- pendenteRevisao → bg #FFF3CD, fg #92400E, label "Pendente"
- publicado → bg #D1FAE5, fg #065F46, label "Publicado"
- arquivado → bg #F3F4F6, fg #6B7280, label "Arquivado"

**BottomSheet de ações (tap longo no card):**
- Handle visual no topo (Container 36x4, cor #D1D5DB, borderRadius 2)
- Título do relatório como cabeçalho
- Divider
- Ações baseadas no status:

  Sempre visível:
    "Ver relatório" → context.go(AppRoutes.relatorioDetailPath(relatorio.id))

  Se pendenteRevisao:
    "Editar" → context.go(AppRoutes.relatorioDetailPath(relatorio.id))
    "Publicar" (cor #059669) → AlertDialog de confirmação
      Texto: "O relatório será enviado ao produtor e ao agrônomo. Esta ação não pode ser desfeita."
      Ao confirmar: ref.read(relatorioRepositoryProvider).publish(id) + ref.invalidate(relatoriosListProvider)

  Se publicado:
    "Arquivar" (cor #6B7280) → AlertDialog de confirmação
      Ao confirmar: ref.read(relatorioRepositoryProvider).archive(id) + ref.invalidate(relatoriosListProvider)

---

## ARQUIVO 2

**Criar em:**
`lib/modules/consultoria/relatorios/presentation/relatorio_detail_screen.dart`

**O que fazer:**
Criar tela de detalhe e edição (ConsumerStatefulWidget).
Recebe String relatorioId no construtor.
Assiste relatorioDetailProvider(id: relatorioId).

**Layout — CustomScrollView com slivers:**

Sliver 1 — Header:
  Padding(fromLTRB(24, 20, 24, 0))
  Row: título (title ?? farmName, fontSize 22, bold) + StatusChip (mesmas cores do badge)

Sliver 2 — InfoCard:
  Campos em formato label/valor (label fixo em 100px, valor expandido):
  - "Fazenda" → relatorio.farmName
  - "Período" → dd/mm/yyyy → dd/mm/yyyy
  - "Talhões" → "${relatorio.talhoes.length} visitados"
  - "Ocorrências" → "${relatorio.ocorrencias.length} registradas"

Sliver 3 — EditCard (SOMENTE se status == pendenteRevisao):
  - Título "Editar relatório"
  - TextField controlado para título (label "Título")
  - TextField controlado para notas (label "Notas adicionais", maxLines 4)
  - _isDirty começa false, muda para true ao digitar
  - OutlinedButton "Salvar alterações" visível SOMENTE se _isDirty == true
  - Ao salvar: repository.update(relatorio.copyWith(title: ..., customNotes: ...)) + ref.invalidate(relatorioDetailProvider) + _isDirty = false

Sliver 4 — OcorrenciasCard (SOMENTE se relatorio.ocorrencias.isNotEmpty):
  Título "Ocorrências" + lista simples com "• " prefixando cada item

Sliver 5 — TalhoesCard (SOMENTE se relatorio.talhoes.isNotEmpty):
  Título "Talhões visitados" + lista simples com "• " prefixando cada item

Sliver 6 — BotãoPublicar (SOMENTE se status == pendenteRevisao):
  FilledButton "PUBLICAR RELATÓRIO", largura total, cor #1A56DB, borderRadius 12
  Ao tocar: AlertDialog de confirmação (mesmo texto do ARQUIVO 1)
  Ao confirmar: repository.publish(id) + ref.invalidate(relatorioDetailProvider) + context.go(AppRoutes.relatorios)

Sliver 7 — SizedBox(height: 100) — espaço para SmartButton global

---

## VALIDAÇÃO QUE O AGENTE DEVE FAZER ANTES DE FINALIZAR

- [ ] Nenhum AppBar criado
- [ ] Nenhum Navigator.pop() — apenas context.go()
- [ ] Nenhum FAB criado
- [ ] _isDirty começa false, só ativa ao digitar
- [ ] Botão "Salvar alterações" só aparece se _isDirty == true
- [ ] BotãoPublicar e EditCard só aparecem se pendenteRevisao
- [ ] flutter analyze lib/modules/consultoria/relatorios/presentation/ → 0 erros
- [ ] Nenhum outro módulo alterado
