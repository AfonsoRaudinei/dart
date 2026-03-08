# PROMPT 02 — drawing_sheet: Remover espaço em branco excessivo

**Agente:** Engenheiro Sênior Flutter/Dart  
**Especialização:** Layout Flutter, padding compacto  
**Risco:** 🟢 Baixo  
**Atualizado:** 08/03/2026 — caminho corrigido pós-auditoria

---

## ESCOPO

**Módulo:** `drawing/`  
**Arquivo-alvo confirmado pela auditoria:**
```
lib/modules/drawing/presentation/widgets/drawing_sheet.dart
```

> ⚠️ `drawing_tools_sheet.dart` **NÃO EXISTE**. O componente real é `drawing_sheet.dart` (1217 linhas).  
> **Não criar arquivo novo.** Editar exclusivamente o arquivo acima.

🚫 **Proibido alterar:** lógica dos itens, callbacks, providers, outros arquivos

---

## OBJETIVO

Remover o grande espaço em branco entre o handle do sheet e o título "Ferramentas de Desenho". O sheet deve ser compacto — handle → título → Divider → itens, sem gaps.

---

## PASSO A PASSO

**Passo 1 — Confirmar o arquivo e localizar a região do header**

```bash
# Confirmar existência
wc -l lib/modules/drawing/presentation/widgets/drawing_sheet.dart

# Localizar o handle e o título no arquivo
grep -n "Ferramentas de Desenho\|handle\|SizedBox\|Spacer\|EdgeInsets" \
  lib/modules/drawing/presentation/widgets/drawing_sheet.dart | head -30
```

**Passo 2 — Identificar o causador do espaço em branco**

Dentro do arquivo, procurar por qualquer um destes causadores na região do header (primeiros ~100 widgets da Column):
- `SizedBox(height: XX)` com valor alto no topo
- `Padding(padding: EdgeInsets.only(top: XX))` excessivo
- `Spacer()` no início da Column
- `Column` sem `mainAxisSize: MainAxisSize.min`
- `ListView` ou `SingleChildScrollView` com `padding` top alto

**Passo 3 — Aplicar estrutura compacta no header**

Substituir apenas a seção do header (handle + título), **preservando todos os itens e callbacks existentes**:

```dart
// Header compacto correto — sem gaps
Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    // Handle
    Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
    // Título — SEM espaço extra acima do Divider
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: const Text(
        'Ferramentas de Desenho',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    const Divider(height: 1),
    // ... itens existentes preservados abaixo ...
    // Safe area bottom
    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
  ],
)
```

> **Regra:** Não adicionar `SizedBox` com altura > 0 entre o Divider e o primeiro item.  
> Não adicionar `Expanded` desnecessário.

**Passo 4 — Verificar cada item da lista**

Certificar que o padrão de padding de cada item está uniforme:
```dart
ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  leading: Icon(icone),
  title: Text('Nome'),
  onTap: () { ... },  // manter callback existente intocado
)
```

---

## VALIDAÇÃO

- [ ] Nenhum espaço em branco visível entre handle e título?
- [ ] Todos os itens existentes continuam funcionando?
- [ ] Safe area bottom preservada?
- [ ] `flutter analyze` sem novos erros?
- [ ] `arch_check.sh` Exit 0?

---

## ENCERRAMENTO

Apenas o layout do header interno do `DrawingSheet` foi alterado.  
Callbacks, lógica de seleção de ferramenta e todos os outros arquivos permanecem intactos.
