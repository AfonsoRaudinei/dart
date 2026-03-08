# PROMPT — Adicionar Regra Anti-Plataforma ao PROJECT_RULES.md

**Agente:** Engenheiro Sênior Flutter/Dart — Atualização de Governança  
**Risco:** Baixo (adição de texto em arquivo de regras, nenhum código alterado)  
**Arquivo-alvo:** `PROJECT_RULES.md` (raiz do projeto)  

---

## PRÉ-REQUISITO

```bash
# Confirmar que o arquivo existe
ls -la PROJECT_RULES.md

# Confirmar conteúdo atual (para não duplicar regra existente)
cat PROJECT_RULES.md
```

---

## OBJETIVO

Adicionar uma seção permanente ao `PROJECT_RULES.md` que proíba explicitamente o agente de criar ou modificar arquivos fora das pastas autorizadas do projeto mobile.

---

## EXECUÇÃO

### Localizar o ponto de inserção

O agente deve **encontrar** o final do arquivo ou a seção mais apropriada (ex.: seção de regras de estrutura de pastas, se existir) e **inserir o bloco abaixo**.

Não substituir conteúdo existente. Apenas adicionar.

---

## BLOCO A INSERIR

```markdown
---

## REGRA: Plataformas Autorizadas — Mobile Only

**Status:** ATIVO — OBRIGATÓRIO  
**Origem:** Decisão arquitetural Mar/2026  

### SoloForte é um projeto exclusivamente mobile (Android + iOS).

#### ✅ Pastas autorizadas para criação/edição de arquivos:

| Pasta | Finalidade |
|---|---|
| `lib/` | Código Dart do aplicativo |
| `test/` | Testes automatizados |
| `assets/` | Recursos estáticos (imagens, fontes, json) |
| `android/` | Código nativo Android (apenas quando necessário) |
| `ios/` | Código nativo iOS (apenas quando necessário) |
| `macos/` | Apenas se relacionado ao ambiente de build iOS/macOS |
| `docs/` | Documentação arquitetural (ADRs, baselines) |
| `prompt/` | Prompts gerados para execução pelo agente |
| `tool/` | Scripts de CI/enforcement (`arch_check.sh`, etc.) |
| `supabase/` | Edge Functions e migrations de backend |
| `scripts/` | Scripts de build e automação |
| `.github/` | Workflows de CI/CD |

#### ❌ Pastas PROIBIDAS — o agente NUNCA deve criar arquivos aqui:

| Pasta | Motivo |
|---|---|
| `web/` | Plataforma não utilizada — projeto mobile only |
| `linux/` | Plataforma não utilizada — projeto mobile only |
| `windows/` | Plataforma não utilizada — projeto mobile only |

#### ❌ Arquivos PROIBIDOS na raiz do projeto:

| Tipo | Exemplos proibidos |
|---|---|
| Arquivos `.dart` soltos | `test_debug.dart`, `update_*.dart` |
| Arquivos `.log` | `flutter_01.log`, `drawing_tests.log` |
| Scripts não documentados | `run_update.sh` sem ADR referenciado |

#### Regra de ouro:

> Se o arquivo não pertence a nenhuma pasta autorizada acima,  
> **o agente não deve criá-lo sem aprovação explícita.**

#### Consequência de violação:

Qualquer arquivo criado fora das pastas autorizadas deve ser:
1. Deletado imediatamente
2. Registrado como violação no PR
3. Referenciado nesta regra no review

---
```

---

## COMMIT

```bash
git add PROJECT_RULES.md
git commit -m "docs: add mobile-only platform enforcement rule to PROJECT_RULES.md"
```

---

## VALIDAÇÃO

```bash
# Confirmar que o bloco foi adicionado corretamente
grep -A 5 "Plataformas Autorizadas" PROJECT_RULES.md

# Confirmar que nenhum arquivo Dart foi alterado
git diff --name-only HEAD~1 | grep "\.dart"
# Esperado: nenhum resultado
```

---

## VALIDAÇÃO FINAL

| Verificação | Esperado |
|---|---|
| `PROJECT_RULES.md` atualizado | SIM |
| Arquivos `.dart` alterados | NENHUM |
| `lib/` alterado | NENHUM |
| arch_check.sh | Exit 0 (não precisa rodar, nenhum Dart foi tocado) |

---

## ENCERRAMENTO

A regra de plataformas autorizadas foi adicionada ao `PROJECT_RULES.md`.  
Nenhum módulo, contrato, rota, provider ou código Dart do SoloForte foi alterado.
