# PROMPT 01 — AUDITORIA: Módulo `visitas/`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Auditoria (READ-ONLY)
**Arquivo destino:** `prompt/audit-01-visitas.md`
**Tipo:** AUDITORIA ESTRUTURAL — ZERO EDIÇÃO
**Risco:** Nenhum — apenas leitura e reporte

---

## OBJETIVO

Mapear o estado real do módulo `visitas/` antes de qualquer intervenção:
quem consome `VisitSession`, quais dependências existem, e se as fronteiras
arquiteturais estão respeitadas.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não editar nenhum arquivo  
❌ Não criar nenhum arquivo  
❌ Não mover nenhum arquivo  
❌ Não sugerir refatoração durante esta etapa  
❌ Não executar `flutter analyze` nem `build_runner`  

---

## PASSO 0 — VERIFICAÇÃO DE EXISTÊNCIA

```bash
find lib/modules/visitas/ -type f -name "*.dart" | sort

find lib/ -name "visit_session.dart"
find lib/ -name "visit_controller.dart"
find lib/ -name "visit_stats_controller.dart"
find lib/ -name "geofence_controller.dart"
find lib/ -name "geofence_state.dart"
find lib/ -name "visit_stats.dart"
```

⛔ Se algum arquivo não for encontrado no path esperado →
PARAR e reportar antes de continuar.

---

## PASSO 1 — ESTRUTURA DO MÓDULO

```bash
find lib/modules/visitas/ -type f | sort
```

Reportar a árvore completa. Comparar com a estrutura esperada:

```
lib/modules/visitas/
├── data/
│   └── repositories/
├── domain/
│   └── models/
│       ├── geofence_state.dart
│       ├── visit_session.dart
│       └── visit_stats.dart
└── presentation/
    ├── controllers/
    │   ├── geofence_controller.dart
    │   ├── visit_controller.dart
    │   └── visit_stats_controller.dart
    └── widgets/
```

Reportar: há arquivos fora do esperado? Há pastas ausentes?

---

## PASSO 2 — CONTRATO DE `VisitSession`

```bash
cat lib/modules/visitas/domain/models/visit_session.dart
```

Reportar:
- Campos declarados (nome + tipo)
- Há interface formal `IVisitSession` ou similar?
- A classe é `final`? `@immutable`?
- Há `copyWith`?
- Há `fromMap` / `toMap` para SQLite?

---

## PASSO 3 — QUEM IMPORTA `visitas/`

```bash
grep -rn "import.*modules/visitas" lib/ --include="*.dart" | sort
```

Para cada resultado, reportar:
- Módulo importador
- Arquivo exato
- O que está sendo importado (VisitSession? Controller? Model?)

---

## PASSO 4 — QUEM IMPORTA `visit_session.dart` ESPECIFICAMENTE

```bash
grep -rn "visit_session" lib/ --include="*.dart" | grep "import" | sort
```

---

## PASSO 5 — DEPENDÊNCIAS INTERNAS DO MÓDULO

```bash
grep -rn "import" lib/modules/visitas/ --include="*.dart" | sort
```

Reportar: o módulo `visitas/` importa algo de outros módulos?
Se sim — qual módulo? É uma violação ou dependência autorizada?

---

## PASSO 6 — VERIFICAÇÃO DE INTERFACE FORMAL

```bash
find lib/core/contracts/ -name "*.dart" | xargs grep -l "visit\|Visit" 2>/dev/null
find lib/ -name "i_visit*.dart" | sort
```

Existe alguma interface `IVisitSessionLookup` ou similar em `core/contracts/`?
Reportar: SIM (path) ou NÃO.

---

## PASSO 7 — VERIFICAÇÃO DE ADR

```bash
find . -name "ADR-*" -name "*visita*" -o -name "ADR-*" -name "*visit*" | sort
grep -rn "visitas\|VisitSession" docs/ --include="*.md" 2>/dev/null | grep "ADR" | sort
```

Existe ADR formal para o módulo `visitas/`?
Reportar: SIM (número) ou NÃO.

---

## PASSO 8 — VERIFICAÇÃO ARCH_CHECK

```bash
bash tool/arch_check.sh 2>&1
```

Reportar apenas as linhas relevantes ao módulo `visitas/`.
Anotar o exit code: 0 (OK) ou 1 (violação).

---

## ENTREGA ESPERADA

O agente deve produzir um relatório com exatamente estas seções:

```
MÓDULO: visitas/
STATUS: [ISOLADO | PARCIALMENTE ISOLADO | VIOLAÇÃO DETECTADA]

ARQUIVOS ENCONTRADOS: <lista>
ARQUIVOS AUSENTES: <lista ou NENHUM>

CONSUMIDORES DE VisitSession:
  - <módulo>: <arquivo> — importa <o quê>

DEPENDÊNCIAS DO MÓDULO:
  - visitas/ importa: <lista ou NENHUMA>

INTERFACE FORMAL: [SIM: <path> | NÃO]
ADR FORMAL: [SIM: ADR-NNN | NÃO]
ARCH_CHECK: [EXIT 0 | EXIT 1 — <motivo>]

VIOLAÇÕES DETECTADAS: <lista ou NENHUMA>
RECOMENDAÇÃO: <uma frase objetiva>
```

---

## ENCERRAMENTO

Este prompt é somente de leitura.
Nenhum arquivo foi criado, editado ou movido.
O relatório gerado alimenta o PROMPT 02.
