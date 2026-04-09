# MICRO-PROMPT — LIMPEZA DOCUMENTAL: Remover referências obsoletas a `consultoria/agenda/`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Documentação
**Tipo:** LIMPEZA DOCUMENTAL — zero alteração de código Dart
**Pré-requisito:** Auditoria confirmou Diagnóstico D — `consultoria/agenda/` já deletado
**Risco:** Nenhum — apenas atualização de documentos `.md`

---

## OBJETIVO

Remover de documentos ativos todas as referências que tratam
`consultoria/agenda/` como dívida pendente ou módulo existente.
O trabalho já foi feito — o ruído documental é o único problema.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não editar nenhum arquivo `.dart`
❌ Não alterar `arch_check.sh`
❌ Não mover nem deletar o arquivo histórico em `docs/05_HISTORICO/`
❌ Não reescrever seções inteiras — apenas atualizar as linhas afetadas

---

## PASSO 0 — LOCALIZAR TODAS AS REFERÊNCIAS

```bash
grep -rn "consultoria/agenda\|consultoria.*agenda" \
  docs/01_BASELINE/ docs/02_ARQUITETURA_ATIVA/ \
  --include="*.md" | sort

grep -rn "consultoria/agenda\|Dois módulos.*agenda\|two agenda" \
  docs/ --include="*.md" | grep -v "05_HISTORICO" | sort
```

Listar cada ocorrência com arquivo e número de linha.
Não editar ainda.

---

## PASSO 1 — ATUALIZAR `ARCH_BASELINE_v1.1_SCORE_90.md`

Localizar a entrada de dívida técnica sobre dois módulos de agenda:

```bash
grep -n "agenda\|Agenda" docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md \
  | grep -i "dupli\|dois\|two\|legado\|warn"
```

Substituir a entrada que diz algo como:
```
| Dois módulos `agenda/` | Médio — risco de lógica duplicada | ... | Consolidar com ADR |
```

Por:
```
| ~~Dois módulos `agenda/`~~ | RESOLVIDO — `consultoria/agenda/` deletado | ADR-018 (histórico) | ✅ Concluído |
```

Ou simplesmente remover a linha se a tabela não tiver coluna de status.

---

## PASSO 2 — ATUALIZAR `SOLOFORTE_BASELINE_REAL.md`

```bash
grep -n "agenda\|DUPLICADO" docs/SOLOFORTE_BASELINE_REAL.md \
  | grep -i "dupli\|dois\|legado\|warn\|⚠️"
```

Localizar o bloco que descreve `consultoria/agenda/` como sub-módulo
legado existente. Deve ser algo como:

```markdown
lib/modules/consultoria/agenda/     ← sub-módulo legado dentro de consultoria
├── data/
├── domain/
└── presentation/
    └── controllers/
        └── agenda_controller.dart
⚠️ Risco: Dois módulos de agenda. Não consolidar sem ADR específico.
```

Substituir por:

```markdown
~~lib/modules/consultoria/agenda/~~ ← DELETADO — ADR-018 (histórico em 05_HISTORICO/)
  Consolidação com modules/agenda/ concluída. Schema pré-v10 incompatível.
  Zero importadores, zero testes. Diretório não existe no disco.
```

---

## PASSO 3 — ATUALIZAR `bounded_contexts.md` SE NECESSÁRIO

```bash
grep -n "consultoria/agenda\|agenda.*legado\|agenda.*duplica" \
  docs/02_ARQUITETURA_ATIVA/bounded_contexts.md
```

Se houver menção a `consultoria/agenda/` como módulo existente →
atualizar para refletir que foi deletado.

Se não houver → pular este passo.

---

## PASSO 4 — ATUALIZAR `00_INDEX_OFICIAL.md` SE NECESSÁRIO

```bash
grep -n "consultoria/agenda\|ADR-018.*agenda\|agenda.*consolidar" \
  docs/00_INDEX_OFICIAL.md
```

Se houver item de ação pendente sobre `consultoria/agenda/` →
marcar como concluído ou remover.

---

## PASSO 5 — VERIFICAR QUE `05_HISTORICO/` NÃO FOI TOCADO

```bash
find docs/05_HISTORICO/ -name "*agenda*" -o -name "*ADR-018*" | sort
```

O arquivo histórico deve permanecer intacto — é o registro da consolidação.
Confirmar que está presente e não foi alterado.

---

## PASSO 6 — VERIFICAR ARCH_CHECK

```bash
bash tool/arch_check.sh
echo "EXIT CODE: $?"
```

Resultado esperado: **Exit 0** — nenhum arquivo Dart foi tocado.

---

## VALIDAÇÃO FINAL

- [ ] `ARCH_BASELINE` sem referência a `consultoria/agenda/` como dívida ativa?
- [ ] `SOLOFORTE_BASELINE_REAL.md` sem bloco descrevendo o diretório como existente?
- [ ] `bounded_contexts.md` atualizado se necessário?
- [ ] `00_INDEX_OFICIAL.md` atualizado se necessário?
- [ ] `docs/05_HISTORICO/` intacto?
- [ ] Nenhum arquivo `.dart` tocado?
- [ ] `arch_check.sh` Exit 0?

---

## MENSAGEM DE COMMIT

```
docs: remove referências obsoletas a consultoria/agenda/ nos docs ativos

- ARCH_BASELINE: marca dívida como resolvida (ADR-018 histórico)
- SOLOFORTE_BASELINE_REAL: remove bloco de módulo deletado
- bounded_contexts.md / 00_INDEX_OFICIAL.md: limpeza pontual se necessário
- 05_HISTORICO/ preservado intacto como registro da consolidação
- Zero alteração de código Dart
- arch_check.sh: Exit 0
```

---

## ENCERRAMENTO

Documentação alinhada com a realidade do disco.
Próximo: PROMPT 01 de auditoria para ADR-024
(IOccurrenceRepository + IReportRepository).
