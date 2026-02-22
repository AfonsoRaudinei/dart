# 📘 SoloForte — Plano Oficial de Estabilização v1.2

**Data:** 18/02/2026
**Branch alvo:** release/v1.2
**Status atual:** 🔴 Instável para produção
**Objetivo:** Elevar o app para 🟡 Operacional Seguro

---

# 1️⃣ Objetivo da v1.2
voce e um programador senior em flutter e dart, e esta liderando a estabilização da versão v1.2 do app SoloForte. O objetivo principal desta versão é eliminar os principais pontos de falha estrutural que impedem o app de ser usado em produção de forma segura.
A versão v1.2 NÃO é uma versão de novas features.
É uma versão de estabilização estrutural.

Meta principal:

* Autenticação real funcionando
* Router estável
* Sem mocks no runtime
* Sem credenciais hardcoded
* Sem catch silencioso
* Sem múltiplas fontes de verdade no módulo de mapa
* Logout funcional
* Timeout e tratamento de erro padronizados

Ao final da v1.2 o app deve estar seguro para uso real controlado.

---

# 2️⃣ Escopo da Estabilização

## Inclui

* Auth
* Router
* Configuração de ambiente
* Drawing (consolidação mínima)
* Conectividade
* Persistência local
* Tratamento de erros

## Não inclui

* Nova feature
* Redesign visual
* Mudança de arquitetura global
* Reescrita completa do módulo Drawing

---

# 3️⃣ Plano de Execução — PRs Numerados

---

# 🔴 PR #1 — Autenticação Real

## Objetivo

Eliminar auth fake e conectar fluxo ao Supabase real.

## Ações

* Remover `auth_service.dart` fake
* Integrar SessionController ao SupabaseAuth
* Usar `onAuthStateChange`
* Transformar SessionController em AsyncNotifier<User?>
* Implementar logout real
* Garantir persistência via Supabase

## Critério de aceite

* Login real funciona
* Logout funciona
* Router responde corretamente ao estado
* Nenhum token fake no código

---

# 🔴 PR #2 — Configuração de Ambiente

## Objetivo

Eliminar credenciais hardcoded.

## Ações

* Criar AppConfig
* Implementar `--dart-define`

  * SUPABASE_URL
  * SUPABASE_ANON_KEY
  * ENV
* Remover URLs literais do código

## Critério de aceite

* Build funciona sem editar código
* Nenhuma credencial no repositório

---

# 🔴 PR #3 — Remoção de Código Mock

## Objetivo

Remover qualquer mock do bundle de produção.

## Ações

* Remover `_getMockPublicacoes()`
* Remover `mock_feedback_repository.dart`
* Remover hardcodes de nomes/dados
* Ajustar feature flags dev

## Critério de aceite

* Nenhum dado fake em produção
* Repositórios reais implementados ou stub seguro explícito

---

# 🟡 PR #4 — Correção do Router

## Objetivo

Evitar recriação do GoRouter.

## Ações

* Instanciar GoRouter uma única vez
* Usar refreshListenable
* Ajustar redirect guard

## Critério de aceite

* Navegação não perde stack
* Mudança de auth não destrói estado da UI

---

# 🟡 PR #5 — Centralização de SharedPreferences

## Objetivo

Eliminar chamadas diretas fora da camada de infra.

## Ações

* Criar PreferencesService
* Injetar via Riverpod
* Remover 100% das chamadas diretas a getInstance()

## Critério de aceite

* Domínio não importa SharedPreferences
* Código testável isoladamente

---

# 🟡 PR #6 — Tratamento de Erros e Logs

## Objetivo

Eliminar silenciamento de exceções.

## Ações

* Remover 24 catch silenciosos
* Introduzir logger estruturado
* Envolver debugPrint com kDebugMode
* Garantir erros de migração visíveis

## Critério de aceite

* Nenhum catch vazio
* Logs padronizados
* Erros não passam invisíveis

---

# 🟡 PR #7 — Conectividade Correta

## Objetivo

Remover DNS manual.

## Ações

* Substituir InternetAddress.lookup
* Usar connectivity_plus
* Garantir fallback adequado

## Critério de aceite

* Sem bloqueio de I/O
* Sem dependência de DNS externo

---

# 🟠 PR #8 — Consolidação Mínima do Drawing

## Objetivo

Eliminar múltiplas máquinas de estado.

## Ações

* Eleger 1 state machine
* Remover v2 e v3 OU migrar totalmente para uma
* Eliminar _syncStateMachine()
* Remover múltiplas fontes de verdade

## Critério de aceite

* Uma única máquina de estado ativa
* Nenhuma sincronização manual paralela

---

# 🟠 PR #9 — Limpeza do PrivateMapScreen

## Objetivo

Remover estado duplicado local.

## Ações

* Eliminar _isDrawMode
* Eliminar _sheetState local
* Mover viewport para provider dedicado
* Reduzir responsabilidade da Screen

## Critério de aceite

* Screen focada apenas em UI
* Sem lógica de negócio interna

---

# 🟢 PR #10 — Timeout e Retry Global

## Objetivo

Evitar bloqueio indefinido.

## Ações

* Configurar timeout padrão (15s)
* Implementar retry mínimo para operações críticas
* Padronizar tratamento de erro de rede

## Critério de aceite

* Nenhuma requisição pode travar indefinidamente
* Erros retornam feedback consistente

---

# 4️⃣ Definição de Pronto (Definition of Done v1.2)

A v1.2 será considerada estável quando:

* Auth real funcionando
* Logout funcional
* Router estável
* Zero mock em produção
* Zero catch silencioso
* Configuração via ambiente
* Timeout de rede implementado
* Uma única state machine no Drawing
* Nenhuma credencial hardcoded

---

# 5️⃣ Resultado Esperado

Estado atual:
🔴 Protótipo avançado instável

Estado após v1.2:
🟡 Produto operacional seguro com dívida controlada

---

# 6️⃣ Observação Final

A v1.2 NÃO é o fim da refatoração.
Ela é a consolidação mínima necessária para impedir falhas estruturais em produção.

Arquitetura ideal e escalabilidade virão após estabilização.

---


# 📦 SoloForte --- Template Oficial de Pull Request (v1.2)

Uso obrigatório para qualquer PR na branch release/v1.2. Este template é
parte do Plano Oficial de Estabilização v1.2.

  ------------------
  1️⃣ IDENTIFICAÇÃO
  ------------------

ID do PR: Título objetivo: Módulo afetado: Rota(s) afetada(s): Branch
base: release/v1.2 Responsável: Data:

  -----------------------
  2️⃣ OBJETIVO (1 FRASE)
  -----------------------

Descreva exatamente o que este PR resolve.

Exemplo correto: "Remove autenticação fake e integra SessionController
ao Supabase real."

  ----------------------
  3️⃣ TIPO DE ALTERAÇÃO
  ----------------------

\[ \] Correção crítica (bloqueador) \[ \] Estabilização estrutural \[ \]
Consolidação de módulo \[ \] Hardening / segurança \[ \] Testes \[ \]
Limpeza técnica \[ \] Infraestrutura / Configuração

  -----------------
  4️⃣ ESCOPO DO PR
  -----------------

## Arquivos modificados:

## Arquivos removidos:

## Arquivos criados:

  ---------------------------------------
  5️⃣ PLANEJAMENTO TÉCNICO (OBRIGATÓRIO)
  ---------------------------------------

## Dados que entram:

## Dados que saem:

## Onde persiste:

## Evento que grava:

Se não houver persistência: "Este PR não altera persistência."

  ---------------------
  6️⃣ EXECUÇÃO TÉCNICA
  ---------------------

Descrever objetivamente: - O que foi removido - O que foi alterado - O
que foi substituído - O que foi padronizado

  ----------------------
  7️⃣ TESTES EXECUTADOS
  ----------------------

Validação automática:

\[ \] flutter analyze sem erros \[ \] flutter test passando \[ \] Nenhum
warning novo \[ \] Nenhum TODO crítico introduzido \[ \] Nenhum catch
silencioso introduzido

Resultado:

flutter analyze: flutter test:

Validação manual:

1.  
2.  
3.  

  --------------
  8️⃣ SEGURANÇA
  --------------

\[ \] Nenhuma credencial hardcoded \[ \] Nenhum token exposto \[ \]
Nenhum debugPrint em produção \[ \] Nenhum mock no runtime \[ \] Timeout
aplicado se envolver rede

  ----------------------
  9️⃣ RISCOS CONHECIDOS
  ----------------------

-   

Se não houver: "Nenhum risco estrutural identificado."

  ------------------------------------
  🔒 10️⃣ GATE DE MERGE (OBRIGATÓRIO)
  ------------------------------------

\[ \] Não altera módulo fora do escopo \[ \] Não altera navegação global
indevidamente \[ \] Não recria GoRouter \[ \] Não cria fonte de verdade
duplicada \[ \] Não mistura ChangeNotifier com Riverpod indevidamente \[
\] Não introduz dependência desnecessária \[ \] Não aumenta dívida
técnica \[ \] Não mantém código morto \[ \] Não adiciona estado global
oculto

  -----------------------------------
  11️⃣ RESULTADO ESPERADO APÓS MERGE
  -----------------------------------

-   
-   

  -----------------------
  12️⃣ CONFIRMAÇÃO FINAL
  -----------------------

Dashboard alterado? NÃO Outros módulos alterados? NÃO Navegação global
alterada? NÃO Apenas o escopo do PR foi afetado? SIM

  --------------------------
  13️⃣ IMPACTO ARQUITETURAL
  --------------------------

\[ \] Não altera arquitetura \[ \] Melhora arquitetura \[ \] Reduz
dívida técnica \[ \] Introduz nova dependência \[ \] Introduz novo
padrão

Explicação:

  ------------------------------
  14️⃣ REFERÊNCIA AO PLANO v1.2
  ------------------------------

Este PR pertence a qual item do plano?

-   PR #1 --- Auth
-   PR #2 --- Env
-   PR #3 --- Remoção de Mock
-   PR #4 --- Router
-   PR #5 --- Preferences
-   PR #6 --- Erros & Logs
-   PR #7 --- Conectividade
-   PR #8 --- Drawing
-   PR #9 --- MapScreen
-   PR #10 --- Timeout

------------------------------------------------------------------------

Template Oficial --- SoloForte v1.2
