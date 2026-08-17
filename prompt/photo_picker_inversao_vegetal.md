# PROMPT — `SoloFortePhotoPickerSheet` com Inversão Vegetal
**Agente:** Engenheiro Sênior Flutter/Dart
**Arquivo destino:** `prompt/photo_picker_inversao_vegetal.md`
**Data:** 16/08/2026
**Módulo afetado:** `core/widgets/` (widget compartilhado) + pontos de uso existentes
**Risco:** BAIXO — novo widget isolado, sem alterar contratos existentes
**arch_check.sh:** OBRIGATÓRIO exit 0 ao final

---

## OBJETIVO

Criar um widget picker de foto compartilhado (`SoloFortePhotoPickerSheet`) que,
ao ser chamado em qualquer slot de foto do app, apresenta três origens:
Câmera, Galeria e Inversão vegetal.

A lógica de processamento de inversão vegetal já existe no app.
O agente deve localizá-la antes de qualquer implementação e reutilizá-la —
nunca reimplementar.

---

## PASSO 0 — DESCOBERTA OBRIGATÓRIA (executar antes de qualquer ação)

O agente deve executar todos os comandos abaixo e reportar os resultados
antes de avançar para o PASSO 1. Nenhuma implementação antes desta etapa.

```bash
# 1. Localizar a lógica de inversão vegetal já existente
find lib/ -type f -name "*.dart" | xargs grep -l "invers" --include="*.dart" -r lib/

# 2. Localizar onde ImagePicker é chamado hoje (todos os pontos de uso)
grep -rn "ImagePicker\|image_picker\|pickImage\|pickMultiImage" lib/ --include="*.dart"

# 3. Localizar o widget ou sheet que exibe slots de foto nos sheets de marketing
find lib/modules/marketing -name "*.dart" | xargs grep -l "foto\|photo\|image\|Foto" 2>/dev/null

# 4. Verificar se já existe algum widget de picker compartilhado
find lib/core -name "*photo*" -o -name "*picker*" -o -name "*image*" | grep "\.dart"

# 5. Localizar o service ou use case de inversão vegetal
grep -rn "inversao\|inversão\|vegetal\|VegetalInvers\|InversaoVegetal" lib/ --include="*.dart"

# 6. Verificar onde o processamento de imagem (canal verde/preto-branco) ocorre
grep -rn "img\.\|image\.fromFile\|decodeImage\|encodeJpg\|encodePNG\|ColorFilter\|colorMatrix" lib/ --include="*.dart"
```

**Reportar obrigatoriamente:**
- Arquivo exato onde a lógica de inversão vegetal está implementada
- Assinatura do método/função que processa a inversão
- Todos os arquivos que chamam `ImagePicker` atualmente
- Se já existe algum widget picker compartilhado

---

## GATE 1 — Aprovação do mapeamento
> O agente para aqui, reporta os resultados do PASSO 0 e aguarda aprovação
> explícita antes de continuar. Não avança sem confirmação.

---

## PASSO 1 — Criar `SoloFortePhotoPickerSheet`

**Localização:** `lib/core/widgets/photo/soloforte_photo_picker_sheet.dart`

O widget é um bottom sheet leve (não uma tela) que apresenta três opções.
O agente deve criar o widget com as seguintes características:

**Contrato de entrada/saída:**
- Recebe: `onPhotoSelected: Future<void> Function(String path)`
- Recebe: `label: String` — título do slot (ex: "Foto Antes", "Foto Depois")
- Retorna: chama `onPhotoSelected` com o `path` da foto processada
- Retorna: `null` se o usuário cancelar (fechar o sheet sem selecionar)

**As três opções apresentadas:**
1. **Câmera** — abre `ImagePicker().pickImage(source: ImageSource.camera)`
2. **Galeria** — abre `ImagePicker().pickImage(source: ImageSource.gallery)`
3. **Inversão vegetal** — abre câmera, captura a foto, aplica o processamento
   de inversão vegetal já existente (localizado no PASSO 0), salva o resultado
   e retorna o path da imagem processada

**Regras de implementação:**
- O sheet usa `showModalBottomSheet` com `shape` arredondado (padrão SoloForte)
- Cada opção é um `ListTile` com ícone à esquerda e texto
- Ícones sugeridos: câmera → `Icons.camera_alt`, galeria → `Icons.photo_library`,
  inversão vegetal → ícone de folha já usado no app (localizar no PASSO 0)
- Não criar novo ícone — reutilizar o que já existe no módulo de inversão vegetal
- O widget é stateless — não carrega state próprio
- Toda chamada assíncrona (câmera, galeria, processamento) é tratada com
  `try/catch` — erro não propaga, retorna null silenciosamente com log via
  `debugPrint` ou logger existente

**O agente deve sugerir a implementação antes de escrever qualquer arquivo.**

---

## GATE 2 — Aprovação da implementação sugerida
> O agente apresenta o design do widget (estrutura de classes, assinatura,
> fluxo interno) e aguarda aprovação antes de criar o arquivo.

---

## PASSO 2 — Criar função auxiliar de chamada

**Localização:** mesmo arquivo ou arquivo companion em `lib/core/widgets/photo/`

Criar função estática ou top-level:

```
showSoloFortePhotoPicker({
  required BuildContext context,
  required String label,
  required Future<void> Function(String path) onPhotoSelected,
}) → Future<void>
```

Essa função encapsula o `showModalBottomSheet` e é o único ponto de entrada
para quem quer abrir o picker. Os widgets de slot de foto chamam apenas essa
função — não instanciam `SoloFortePhotoPickerSheet` diretamente.

---

## GATE 3 — Aprovação da função auxiliar

---

## PASSO 3 — Substituir chamadas diretas de `ImagePicker` nos slots de foto

Com base no mapeamento do PASSO 0, o agente deve identificar os widgets de
slot de foto nos sheets afetados (Antes/Depois — slots "Foto Antes" e
"Foto Depois") e substituir a chamada direta de `ImagePicker` pela chamada
a `showSoloFortePhotoPicker`.

**Regras:**
- Alterar apenas os slots que hoje chamam `ImagePicker` inline
- Não alterar lógica de exibição da foto selecionada (thumbnail, estado)
- Não alterar contrato do sheet (parâmetros de entrada/saída)
- Não criar novo estado — apenas redirecionar a origem da foto
- Slots que hoje NÃO têm `ImagePicker` (ou não existem) → não tocar

O agente deve listar os arquivos que serão alterados e aguardar aprovação
antes de editar qualquer um deles.

---

## GATE 4 — Aprovação da lista de arquivos a alterar

---

## PASSO 4 — Executar arch_check e testes

```bash
# Verificar fronteiras arquiteturais
bash tool/arch_check.sh

# Executar suite de testes
flutter test --no-pub
```

**Critério de aprovação:**
- `arch_check.sh` → exit 0 obrigatório
- Nenhum teste existente quebrado
- Zero erros de análise estática: `flutter analyze`

---

## GATE 5 — Validação final obrigatória

O agente responde explicitamente cada item antes de encerrar:

| Pergunta | Resposta esperada |
|---|---|
| `arch_check.sh` exit 0? | SIM |
| `flutter analyze` zero issues? | SIM |
| Testes existentes passando? | SIM |
| Lógica de inversão vegetal reimplementada? | NÃO — reutilizada |
| Novo widget criado fora de `core/widgets/`? | NÃO |
| Contratos de sheets alterados? | NÃO |
| Novo provider Riverpod criado? | NÃO |
| Navegação ou rotas alteradas? | NÃO |
| Tema ou design tokens alterados? | NÃO |
| Outros módulos além de `core/` e slots afetados tocados? | NÃO |

Se qualquer resposta divergir → rollback e reportar antes de encerrar.

---

## ENCERRAMENTO PADRÃO

O widget `SoloFortePhotoPickerSheet` foi criado em `lib/core/widgets/photo/`.
Os slots de foto afetados agora chamam `showSoloFortePhotoPicker` em vez de
`ImagePicker` diretamente. A lógica de inversão vegetal existente foi reutilizada
sem modificação. Nenhum outro módulo, rota, estado ou contrato do SoloForte
foi alterado.

---

## RELATÓRIO FINAL (preencher pelo agente)

| Item | Detalhe |
|---|---|
| Arquivo criado | `lib/core/widgets/photo/soloforte_photo_picker_sheet.dart` |
| Arquivos alterados | listar aqui |
| Arquivo da lógica de inversão vegetal (reutilizado) | preencher no PASSO 0 |
| Testes novos criados | sim/não + localização |
| arch_check.sh | exit 0 confirmado |
| Próximos passos | integração nos demais slots do app (Foto rápida, Avaliação) |

---

## FORA DO ESCOPO DESTE PROMPT

- Modificar a lógica interna de inversão vegetal
- Integrar nos slots de Foto rápida (prompt separado após QA deste)
- Integrar nos slots de Avaliação (idem)
- Criar preview em tempo real (câmera com filtro ativo)
- Criar galeria de fotos processadas
- Alterar a tela de Relatório > Mídia
