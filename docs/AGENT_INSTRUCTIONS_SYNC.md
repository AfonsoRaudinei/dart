# Checklist — Sincronização de Instruções para Agentes

**Última validação:** Jun/2026  
**Fonte da verdade:** `AGENTS.md` (raiz)

## Arquivos sincronizados

| Arquivo | Ferramenta | DB schema | ADRs | Aponta AGENTS.md |
|---|---|---|---|---|
| `AGENTS.md` | Codex | v38 | 008–041 | — (fonte) |
| `.cursorrules` | Cursor legado | v38 | — | ✅ |
| `.cursor/rules/soloforte-engineer.mdc` | Cursor Rules | v38 | — | ✅ |
| `.cursor/skills/soloforte-task/SKILL.md` | Cursor Skill | v38 | 008–041 | ✅ |
| `.github/copilot-instructions.md` | Copilot | v38 | 008–041 | ✅ |
| `.claude/CLAUDE.md` | Claude Code | v38 | 008–041 | ✅ |
| `soloforte-agent.md` | Skill legado | v38 | — | ✅ |
| `lib/**/AGENTS.md` (18 módulos) | Contexto por módulo | — | por módulo | implícito |

## Valores canônicos

| Atributo | Valor |
|---|---|
| DB schema SQLite | **v38** (`lib/core/database/database_helper.dart`) |
| Baseline documental | v1.1 (`ARCH_BASELINE_v1.1_SCORE_90.md`) |
| Release estabilização | v1.2 |
| Coverage CI mínimo | 36.46% |
| Relatórios | `lib/modules/consultoria/relatorios/` (não top-level) |

## Como revalidar após mudança de schema ou ADR

```bash
# 1. Versão real do DB
rg "version:" lib/core/database/database_helper.dart

# 2. Instruções desatualizadas (não deve retornar hits nos arquivos ativos)
rg "schema v(12|29|32)|DB Schema v(12|29|32)" AGENTS.md .cursorrules .github/copilot-instructions.md .cursor/ .claude/ soloforte-agent.md

# 3. Arquitetura
./tool/arch_check.sh
```

## Manutenção

1. Alterar **somente** `AGENTS.md` (seção VERDADE DO PROJETO) quando schema/ADR mudar
2. Rodar os comandos acima
3. Atualizar este checklist se novos arquivos de instrução forem criados
