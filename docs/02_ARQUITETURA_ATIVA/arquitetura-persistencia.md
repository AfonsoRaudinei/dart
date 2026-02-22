# CONTRATO ARQUITETURAL DE PERSISTÊNCIA GEOESPACIAL (SQLITE ↔ SYNC)
**STATUS: CONTRATO CONGELADO**
**DATA:** 08/02/2026

Este documento define a estratégia oficial de persistência para dados geoespaciais e operacionais no SoloForte.
Qualquer implementação de banco de dados ou sincronização deve seguir rigorosamente este contrato.

---

## 1. VISÃO GERAL (OFFLINE-FIRST)

O SoloForte adota um modelo **offline-first** para dados geoespaciais.
Toda geometria criada ou editada no mapa é **persistida localmente (SQLite) como fonte primária** e **sincronizada posteriormente** com o backend quando houver conectividade.

### 1.1. Regra Fundamental
> **"Nenhuma ação de campo pode depender de conectividade."**
> **"SQLite é a fonte da verdade no dispositivo. O backend é a fonte da verdade consolidada."**

Todo desenho relevante deve sobreviver a:
- Fechamento do app
- Crash / Hot Restart
- Perda de sinal / Modo Avião
- Bateria zerada

---

## 2. MODELO DE PERSISTÊNCIA LOCAL (SQLITE)

### 2.1. Fonte da Verdade Local
* Todas as geometrias são salvas **imediatamente** no SQLite após confirmação do usuário.
* **Nenhuma** geometria confirmada pode existir apenas em RAM (State/Provider).

### 2.2. Estrutura Conceitual de Dados
Cada registro geoespacial deve conter, no mínimo:

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | UUID | Identificador único gerado localmente (v4) |
| `entity_type` | String/Enum | Tipo da entidade (ex: `talhao`, `ocorrencia`, `zona`) |
| `geometry` | GeoJSON | Representação geométrica padrão |
| `created_at` | DateTime | Timestamp de criação (UTC) |
| `updated_at` | DateTime | Timestamp de atualização (UTC) |
| `sync_status` | Enum | Estado de sincronização (ver seção 3) |
| `deleted_at` | DateTime? | Timestamp para Soft Delete (nullable) |

---

## 3. ESTADOS DE SINCRONIZAÇÃO (OBRIGATÓRIO)

Todo registro geoespacial deve possuir um **estado explícito de sync**.

### 3.1. Estados Canônicos
1. `local_only`: Criado localmente, nunca enviado ao backend.
2. `pending_sync`: Alterado localmente (update), aguardando envio.
3. `synced`: Sincronizado com sucesso (espelho do backend).
4. `sync_error`: Falha ao tentar sincronizar (deve permitir retry).
5. `deleted_local`: Removido localmente, aguardando sync de exclusão no backend.

❌ **Proibido:** Inferir estado de sync por heurística, booleano simples ou apenas timestamp.

---

## 4. FLUXOS DE DADOS

### 4.1. Fluxo de Criação (Campo)
1. Usuário desenha e confirma geometria no mapa.
2. Geometria é salva no SQLite com `sync_status = local_only`.
3. UI reflete imediatamente o dado (lê do SQLite ou Cache Local).
4. Sistema agenda sincronização (background ou próxima oportunidade).

⚠️ **Regra:** A UI **não pode** bloquear esperando resposta do backend.

### 4.2. Fluxo de Edição
1. Usuário edita geometria existente.
2. Registro local é atualizado.
3. `sync_status` muda para `pending_sync` (se já estava `synced`) ou continua `local_only`.
4. `updated_at` é renovado.

### 4.3. Fluxo de Exclusão (Soft Delete)
1. Usuário exclui geometria.
2. Registro local **não é apagado fisicamente**.
3. `deleted_at` é preenchido.
4. `sync_status` muda para `deleted_local`.
5. O dado deixa de aparecer na UI padrão (filtros ignoram `deleted_at != null`).

❌ **Proibido:** Hard delete imediato (SQL `DELETE FROM ...`) para dados sincronizáveis.

---

## 5. PROCESSO DE SINCRONIZAÇÃO

### 5.1. Gatilhos de Sync
A sincronização deve ser resiliente e pode ser disparada por:
* Reconexão de rede (listener de conectividade).
* Abertura do app (cold start).
* Ação manual ("Puxar para atualizar" ou botão Sync).
* Tarefa agendada (WorkManager/BackgroundFetch).

### 5.2. Resolução de Conflitos
O SoloForte adota o modelo:
> **"Local vence temporariamente até confirmação explícita."**

* Alterações locais recentes prevalecem na UI do dispositivo.
* Em caso de conflito real (ID alterado no servidor vs local), o servidor é a autoridade, mas o dado local deve ser preservado para resolução (ex: cópia conflitante).
* **NUNCA** sobrescrever trabalho de campo do usuário silenciosamente.

---

## 6. RELAÇÃO COM NAVEGAÇÃO E MODO DESENHO

* **Persistência é independente da navegação.**
* Sair da tela ou trocar de contexto **não cancela** a persistência de um dado já confirmado.
* O Modo Desenho não decide *quando* sincronizar, apenas *salva* o resultado.
* A navegação (`pop`, `go`) não deve disparar exclusão automática de rascunhos salvos explicitamente.

---

## 7. ANTIPADRÕES PROIBIDOS

* ❌ Depender de sucesso de API para fechar tela de cadastro.
* ❌ Manter geometria apenas em memória (`Provider`/`State`) após confirmação.
* ❌ Usar Hard Delete em registros que já foram sincronizados.
* ❌ Sincronizar dentro do método `build()` ou `initState()` de widgets.
* ❌ Acoplar lógica de sync ao ciclo de vida da navegação (`dispose`).

---

## 8. REGRA PARA AGENTES (PROMPTS FUTUROS)

Para garantir a integridade deste contrato, todo prompt técnico envolvendo dados deve conter:

> "Seguir rigorosamente `docs/arquitetura-persistencia.md`.
> O app é Offline-First com SQLite como fonte da verdade local.
> Se houver conflito, o contrato de persistência prevalece."

**Agentes são instruídos a rejeitar implementações que dependam de conexão constante.**
