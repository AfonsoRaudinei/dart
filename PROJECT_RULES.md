# O que ESTE projeto VAI ser

## Plataforma alvo

O aplicativo SoloForte é **mobile-first e mobile-only**.

Plataformas suportadas:
- iOS
- Android
- macOS (Desktop Dev)

Plataformas NÃO suportadas neste projeto:
- Web
- Windows
- Linux

As pastas dessas plataformas existem apenas por padrão do Flutter
e **não fazem parte do escopo funcional do produto** neste momento.

Marca isso mentalmente como imutável:

- **App Flutter (Dart)**
- **Mobile-first**
- **Riverpod + @riverpod**
- **Supabase + SQLite**
- **Offline como regra, online como bônus**

Perfeito. Já decidido.

## 0.2 — O que ESTE projeto NÃO vai ser (agora)

Isso evita sabotagem:

- ❌ Mapa
- ❌ Scanner
- ❌ IA
- ❌ Relatórios
- ❌ Gráficos
- ❌ Dashboard “bonito”

Se tentar encaixar algo disso agora, você se atrasa.

## 0.3 — Ordem REAL de construção (não negocie)

1. Projeto Flutter limpo
2. App sobe
3. Riverpod funcionando
4. Navegação funcionando
5. Persistência local OK
6. Supabase OK
7. Offline OK
8. Só então: fluxo

## 0.4 — CONTRATO DE NAVEGAÇÃO E AGENTES

Existe um documento **CONGELADO** que define a arquitetura de navegação:
`docs/arquitetura-navegacao.md`

**REGRA PARA PROMPTS (OBRIGATÓRIO):**
Todo prompt técnico para agentes deve conter:
> "Seguir rigorosamente `docs/arquitetura-navegacao.md`. Se houver conflito, o documento prevalece."

Sem isso, o prompt é inválido.

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
