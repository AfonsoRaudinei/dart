# SoloForte — Documentação do arch_check.sh

**Script:** `tool/arch_check.sh`  
**CI:** `.github/workflows/architecture.yml`  
**Versão:** v1.1  

---

## Propósito

`arch_check.sh` é o guardião automatizado das fronteiras arquiteturais do SoloForte.  
É executado via CI em cada Pull Request e bloqueia merges com violações estruturais.

---

## Localização

```
tool/
└── arch_check.sh    ← script principal de enforcement
```

```
.github/
└── workflows/
    └── architecture.yml    ← pipeline CI que executa o script
```

---

## Regras Implementadas

| Regra | Descrição | Severidade |
|---|---|---|
| REGRA 1 | `core/` não importa `modules/` (exceto `app_router.dart`) | FAIL |
| REGRA 2 | Acoplamentos laterais proibidos entre módulos | FAIL |
| REGRA 3 | Novos arquivos não ultrapassam 900 linhas | WARN |

Detalhamento completo: `03_ENFORCEMENT/enforcement-rules.md`

---

## Saídas do Script

| Código | Significado |
|---|---|
| `Exit 0` | Arquitetura conforme — PR pode prosseguir |
| `Exit 1` | Violação detectada — PR deve ser bloqueado |

```
✅ PASS  — verificação passou
❌ FAIL  — violação crítica detectada
⚠️  WARN  — aviso não bloqueante (legados monitorados)
ℹ️  INFO  — informação estrutural
```

---

## Como Rodar Localmente

```bash
# Pré-requisito: estar na raiz do projeto
chmod +x tool/arch_check.sh
./tool/arch_check.sh
```

Rodar antes de qualquer PR que envolva:
- Novos arquivos em `lib/core/`
- Novos imports entre módulos
- Novos módulos em `lib/modules/`
- Refatorações que movem código entre módulos

---

## Manutenção do Script

Para adicionar nova regra:

1. Criar ADR: `02_ARQUITETURA_ATIVA/ADR-NNN-DESCRICAO.md`
2. Implementar verificação em `tool/arch_check.sh`
3. Atualizar `03_ENFORCEMENT/enforcement-rules.md`
4. Atualizar `01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md` — Seção 3

**Proibido alterar o script sem ADR correspondente.**

---

## Histórico de Versões

| Versão | Data | Mudança |
|---|---|---|
| v1.0 | 2026-02-08 | Criação inicial — REGRAS 1, 2, 3 |
| v1.1 | 2026-02-22 | Documentação formal neste arquivo |

---

*Referência: `tool/arch_check.sh` · `03_ENFORCEMENT/enforcement-rules.md`*
