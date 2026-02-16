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
