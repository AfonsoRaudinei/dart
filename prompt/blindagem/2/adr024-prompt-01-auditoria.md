# PROMPT 01 — AUDITORIA: ADR-024 — `IOccurrenceRepository` + `IReportRepository`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Auditoria (READ-ONLY)
**Tipo:** AUDITORIA ESTRUTURAL — ZERO EDIÇÃO
**Contexto:** Desbloquear DT-023-3 e DT-023-4 do ADR-023
**Risco:** Nenhum — apenas leitura e reporte

---

## OBJETIVO

Mapear o estado real dos repositórios de ocorrências e relatórios
antes de criar qualquer contrato neutro em `core/contracts/`.
Determinar exatamente o que `visit_controller.dart` e
`geofence_controller.dart` precisam desses repositórios.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não editar nenhum arquivo
❌ Não criar nenhum arquivo
❌ Não sugerir implementação durante esta etapa

---

## PASSO 0 — EXISTÊNCIA DOS ARQUIVOS PROBLEMÁTICOS

```bash
find lib/modules/visitas/presentation/controllers/ -name "*.dart" | sort

find lib/modules/consultoria/occurrences/ -type f -name "*.dart" | sort
find lib/modules/consultoria/reports/ -type f -name "*.dart" | sort
```

Confirmar que os arquivos do ADR-023 DT-023-3/4 ainda existem.

---

## PASSO 1 — LER OS IMPORTS PROIBIDOS EM DETALHE

```bash
cat lib/modules/visitas/presentation/controllers/visit_controller.dart
```

Para cada import de `consultoria/`:
- Qual tipo exato está sendo usado?
- Em qual método de `visit_controller.dart`?
- Qual é a assinatura do método chamado?
- O dado retornado é salvo, transformado ou apenas passado adiante?

```bash
cat lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

Mesma análise para `geofence_controller.dart`.

---

## PASSO 2 — LER O REPOSITÓRIO DE OCORRÊNCIAS

```bash
find lib/modules/consultoria/occurrences/ -name "*.dart" | sort

# Ler a interface se existir
find lib/modules/consultoria/occurrences/ -name "i_occurrence*.dart" | \
  xargs cat 2>/dev/null

# Ler a implementação concreta que visit_controller importa
cat lib/modules/consultoria/occurrences/data/occurrence_repository.dart
```

Reportar:
- Existe interface `IOccurrenceRepository` dentro de `consultoria/`?
- Quais métodos o repositório expõe?
- Quais métodos `visit_controller.dart` usa especificamente?
- A entidade `Occurrence` tem campos que dependem de `consultoria/` ou é agnóstica?

---

## PASSO 3 — LER O REPOSITÓRIO DE RELATÓRIOS

```bash
find lib/modules/consultoria/reports/ -name "*.dart" | sort

# Interface
find lib/modules/consultoria/reports/ -name "i_report*.dart" | \
  xargs cat 2>/dev/null

# Implementação concreta
cat lib/modules/consultoria/reports/data/sqlite_report_repository.dart

# Entidade
cat lib/modules/consultoria/reports/domain/report_model.dart
```

Reportar:
- Existe interface `IReportRepository` dentro de `consultoria/`?
- Quais métodos o repositório expõe?
- Quais métodos `visit_controller.dart` usa especificamente?
- `Report` / `ReportType` têm dependências de `consultoria/` ou são agnósticos?

---

## PASSO 4 — VERIFICAR `IAgendaRepository` E `EventStatus`

```bash
cat lib/modules/agenda/domain/repositories/i_agenda_repository.dart
cat lib/modules/agenda/domain/enums/event_status.dart

grep -n "IAgendaRepository\|EventStatus\|agendaRepositoryProvider\|agenda_provider" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart
```

Reportar:
- `IAgendaRepository` já é uma interface — está em `agenda/domain/` ou em `core/contracts/`?
- `visit_controller.dart` usa qual método de `IAgendaRepository`?
- `EventStatus` é enum simples ou tem dependências de `consultoria/`?
- `agendaRepositoryProvider` está em `agenda/presentation/providers/` — por que `visitas/` precisa dele?

---

## PASSO 5 — VERIFICAR CONTRATOS JÁ EXISTENTES EM `core/contracts/`

```bash
find lib/core/contracts/ -type f -name "*.dart" | sort
cat lib/core/contracts/*.dart 2>/dev/null | grep -E "^abstract|^class|^interface"
```

Listar todas as interfaces e DTOs já declarados em `core/contracts/`.
Identificar se algum já cobre parcialmente o que precisamos.

---

## PASSO 6 — VERIFICAR IMPACTO EM TESTES

```bash
find test/ -path "*occurrence*" -name "*.dart" | sort
find test/ -path "*report*" -name "*.dart" | sort
find test/ -path "*visit_controller*" -name "*.dart" | sort
```

Para cada arquivo de teste encontrado:
- Usa mock/fake de `OccurrenceRepository`?
- Usa mock/fake de `ReportRepository`?
- Se movermos para contratos neutros, quantos fakes precisarão ser atualizados?

---

## PASSO 7 — VERIFICAR OUTROS CONSUMIDORES DOS REPOSITÓRIOS

```bash
grep -rn "import.*occurrence_repository\|OccurrenceRepository" \
  lib/ --include="*.dart" | grep -v "consultoria/occurrences/" | sort

grep -rn "import.*sqlite_report_repository\|SQLiteReportRepository\|report_model" \
  lib/ --include="*.dart" | grep -v "consultoria/reports/" | sort
```

Além de `visit_controller.dart`, quem mais importa esses repositórios diretamente?
Isso determina o escopo real do ADR-024.

---

## PASSO 8 — VERIFICAR `IFieldLookup` PARA `geofence_controller`

```bash
cat lib/core/contracts/i_field_lookup.dart

grep -n "IFieldLookup\|FieldSummary\|listAll\|geometry" \
  lib/core/contracts/i_field_lookup.dart

grep -n "geometry\|toPolygon\|isPointInside\|Talhao\b" \
  lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

Reportar:
- `FieldSummary` tem campo `geometry`? Se não, que campos tem?
- `IFieldLookup` tem método `listAll()`? Se não, quais métodos tem?
- `geofence_controller.dart` usa `geometry` de `Talhao` para o quê exatamente?
- `TalhaoMapAdapter.toPolygon()` — qual é a assinatura? Pode ser inlinado?

---

## ENTREGA ESPERADA

```
══════════════════════════════════════════════════════════
AUDITORIA ADR-024 — IOccurrenceRepository + IReportRepository
══════════════════════════════════════════════════════════

CONTRATOS NECESSÁRIOS (lista completa):
  1. <nome do contrato> → para desbloquear <arquivo>
     Métodos mínimos necessários: <lista>
     Entidade/DTO necessário: <nome + campos>
     Já existe em core/contracts/? SIM/NÃO
  2. ...

CONTRATOS JÁ EXISTENTES UTILIZÁVEIS:
  <lista ou NENHUM>

EXPANSÕES NECESSÁRIAS EM CONTRATOS EXISTENTES:
  <ex: IFieldLookup precisa de geometry + listAll()>
  <ou: NENHUMA>

CONSUMIDORES ALÉM DE visitas/:
  <lista de arquivos que também importam os repositórios>
  <ou: APENAS visitas/>

IMPACTO EM TESTES:
  <N fakes precisarão ser atualizados>
  <lista dos arquivos de teste afetados>

COMPLEXIDADE ESTIMADA DO ADR-024:
  [Baixa — 1-2 contratos novos simples]
  [Média — 3-4 contratos, alguns com expansão]
  [Alta — 5+ contratos ou entidades complexas]

ORDEM RECOMENDADA DE CRIAÇÃO:
  1. <contrato mais simples / menos dependências>
  2. ...

DIAGNÓSTICO FINAL:
  <uma frase sobre o que o ADR-024 precisa fazer>
══════════════════════════════════════════════════════════
```

---

## ENCERRAMENTO

Este prompt é somente de leitura.
O relatório determina o escopo exato do ADR-024 e dos prompts seguintes.
Sem esse mapeamento, qualquer contrato criado pode ser incompleto
ou criar novas dependências não intencionais.
