# CONTRATO ARQUITETURAL DE OCORRÊNCIAS GEOESPACIAIS
**STATUS: CONTRATO CONGELADO**
**DATA:** 08/02/2026

Este documento define a estratégia oficial para o domínio de **Ocorrências** (Occurrences) no SoloForte.
As ocorrências são o registro primário de eventos técnicos em campo.

---

## 1. VISÃO GERAL

Uma **Ocorrência** é um **evento técnico georreferenciado** registrado no mapa durante operações de campo (ex.: praga, falha, estresse, recomendação, observação técnica).

A ocorrência é uma **entidade independente**, porém **contextualizada ao mapa** e, quando aplicável, **associada a uma Sessão de Visita**.
Ela **não depende** de navegação e **não é apenas uma anotação visual**.

### 1.1. Princípio Fundamental
> **"Ocorrência é um evento atômico, persistente e auditável."**
> **"Pode existir com ou sem sessão ativa."**

A ocorrência:
- Deve sobreviver a encerramento do app (SQLite).
- Não pode depender de conectividade.
- Deve existir fora de memória (RAM).

---

## 2. ARQUITETURA E LOCALIZAÇÃO

As ocorrências existem **dentro do contexto do Dashboard**, tipicamente sob a rota:
`/dashboard/ocorrencias`

⚠️ **Importante:**
- Essa rota **não representa uma tela isolada**.
- Ela representa um **estado do mapa** com foco em ocorrências e suas ferramentas.
- A navegação global (SmartButton) se mantém inalterada (Menu ☰).

---

## 3. MODELO DE DADOS CONCEITUAL

Cada ocorrência deve conter, no mínimo:

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | SIM | Identificador único (v4) |
| `geometry` | GeoJSON | SIM | Point, LineString ou Polygon |
| `type` | String/Enum | SIM | Categoria técnica (Praga, Doença, Solo, etc.) |
| `description` | Text | NÃO | Observações técnicas |
| `severity` | Enum | NÃO | Grau de severidade (Leve, Moderna, Grave) |
| `photo_paths` | List<String> | NÃO | Caminhos locais de fotos anexadas |
| `visit_session_id` | UUID | NÃO | ID da sessão de visita ativa (se houver) |
| `created_by` | UUID | SIM | ID do usuário autor |
| `created_at` | DateTime | SIM | Timestamp de criação (UTC) |
| `updated_at` | DateTime | SIM | Timestamp de atualização (UTC) |
| `sync_status` | Enum | SIM | Status de sincronização (ver `arquitetura-persistencia.md`) |
| `deleted_at` | DateTime | NÃO | Timestamp para Soft Delete |

❌ **Proibido:** Ocorrência sem geometria (coordenada ou polígono).

---

## 4. FLUXOS DE VIDA

### 4.1. Criação (Campo)
1.  Usuário ativa ferramenta de ocorrência no mapa (Contexto `/dashboard/ocorrencias`).
2.  Seleciona posição ou desenha área.
3.  Preenche metadados (tipo, foto, obs).
4.  Confirma criação.
5.  Ocorrência é persistida **imediatamente** no SQLite (`local_only`).
6.  UI reflete o overlay no mapa.

### 4.2. Relação com Sessão de Visita
*   **Com Sessão Ativa:** A ocorrência herda automaticamente o `visit_session_id` atual.
*   **Sem Sessão Ativa:** A ocorrência é criada "órfã" (independente), podendo ser associada manualmente depois ou permanecer como registro avulso.
*   ❌ É proibido bloquear criação de ocorrência por falta de sessão.

### 4.3. Edição e Exclusão
*   **Edição:** Atualiza registro local, muda `sync_status` para `pending_sync`, atualiza `updated_at`.
*   **Exclusão:** Aplica **Soft Delete** (`deleted_at` preenchido, `sync_status = deleted_local`).
*   **Restrição:** Ocorrências consolidadas em relatórios fechados podem ser bloqueadas para edição (regra de negócio), mas nunca deletadas fisicamente.

---

## 5. RELAÇÃO COM O MAPA E NAVEGAÇÃO

### 5.1. Comportamento Visual
*   Ocorrências são renderizadas como **Overlays** (Marcadores ou Polígonos).
*   Devem respeitar o nível de zoom (clustering se necessário).
*   A seleção de uma ocorrência abre um **Bottom Sheet** de detalhes, sem navegar para outra página cheia.
*   O mapa **não perde o contexto geográfico** ao focar numa ocorrência.

### 5.2. Persistência e Sync
*   Seguem estritamente o `docs/arquitetura-persistencia.md`.
*   Falha de sync **não remove** a ocorrência do mapa.
*   Conflito de edição segue a regra "Local vence temporariamente".

---

## 6. ANTIPADRÕES PROIBIDOS

*   ❌ Criar "Ocorrência Rascunho" que se perde ao fechar o app.
*   ❌ Depender de chamada de API para salvar a ocorrência ("Spinner da Morte").
*   ❌ Hard Delete (SQL `DELETE`) em ocorrências já sincronizadas.
*   ❌ Navegar para uma tela branca separada para criar ocorrência (perde o contexto do mapa).
*   ❌ Bloquear o usuário de criar ocorrência se estiver offline.

---

## 7. REGRA PARA AGENTES (PROMPTS FUTUROS)

Para garantir a integridade deste contrato, todo prompt técnico envolvendo Ocorrências deve conter:

> "Seguir rigorosamente `docs/arquitetura-ocorrencias.md`.
> Ocorrências são eventos georreferenciados offline-first com persistência local garantida.
> Se houver conflito, este documento prevalece."

**Agentes são instruídos a rejeitar implementações que tratem ocorrências como dados efêmeros.**
