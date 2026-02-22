# PROJETO: Persistência Agrícola (Fase 1)
**STATUS: PLANEJAMENTO TÉCNICO**
**DATA:** 04/02/2026

Este documento define a estratégia de persistência para as entidades nucleares do SoloForte: Clientes, Fazendas e Talhões.

---

## 1. ESTRATÉGIA DE DADOS

### 1.1. Arquitetura: Offline-First
* **Fonte da Verdade Local:** SQLite (via `sqflite` ou `drift`). O app deve funcionar 100% sem internet.
* **Fonte da Verdade Remota:** Supabase (PostgreSQL).
* **Sincronização:** Bidirecional ("Last Write Wins" ou log-based) futura.
* **Identificadores:** UUID v4 para todas as chaves primárias (`id`) para permitir geração offline sem colisão.

### 1.2. Controle de Sincronização
Todas as tabelas devem possuir colunas de audit para facilitar o sync:
* `created_at` (DateTime, UTC)
* `updated_at` (DateTime, UTC)
* `deleted_at` (DateTime?, nullable) -> **Soft Delete** obrigatório.
* `sync_status` (Enum/Integer): 0 (Synced), 1 (Pending Insert), 2 (Pending Update).

---

## 2. SCHEMA (MODELAGEM DE DADOS)

### 2.1. Tabela: `clientes` (Produtores)
Representa o proprietário ou entidade legal.

| Coluna | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | TEXT (UUID) | SIM | PK |
| `nome` | TEXT | SIM | Nome completo / Razão Social |
| `documento` | TEXT | NÃO | CPF/CNPJ |
| `telefone` | TEXT | NÃO | Contato principal |
| `email` | TEXT | NÃO | |
| `created_at` | INTEGER/TEXT | SIM | ISO8601 ou Timestamp |
| `updated_at` | INTEGER/TEXT | SIM | |
| `deleted_at` | INTEGER/TEXT | NÃO | |

### 2.2. Tabela: `fazendas`
Propriedades rurais pertencentes a um cliente.

| Coluna | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | TEXT (UUID) | SIM | PK |
| `cliente_id` | TEXT (UUID) | SIM | FK -> clientes.id |
| `nome` | TEXT | SIM | Nome da propriedade |
| `area_total` | REAL | NÃO | Em hectares |
| `municipio` | TEXT | NÃO | |
| `uf` | TEXT | NÃO | |
| `created_at` | INTEGER/TEXT | SIM | |
| `updated_at` | INTEGER/TEXT | SIM | |
| `deleted_at` | INTEGER/TEXT | NÃO | |

### 2.3. Tabela: `talhoes` (Fields)
Unidades produtivas dentro de uma fazenda. Esta é a entidade que se conecta ao MAPA.

| Coluna | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | TEXT (UUID) | SIM | PK |
| `fazenda_id` | TEXT (UUID) | SIM | FK -> fazendas.id |
| `codigo` | TEXT | NÃO | Código interno (ex: "T-01") |
| `nome` | TEXT | SIM | Descrição amigável |
| `area_produtiva`| REAL | NÃO | Em hectares |
| `bordadura_geo` | TEXT (JSON) | NÃO | GeoJSON do polígono (se disponível) |
| `centro_geo` | TEXT (JSON) | NÃO | Ponto central (lat/lng) para navegação |
| `created_at` | INTEGER/TEXT | SIM | |
| `updated_at` | INTEGER/TEXT | SIM | |
| `deleted_at` | INTEGER/TEXT | NÃO | |

---

## 3. RELACIONAMENTOS

* **Cliente 1 : N Fazendas** (Um cliente tem várias fazendas; uma fazenda tem um dono).
* **Fazenda 1 : N Talhões** (Uma fazenda tem vários talhões; um talhão pertence a uma fazenda).

## 4. PRÓXIMOS PASSOS (IMPLEMENTAÇÃO)

1. Criar migrations para criar estas tabelas no SQLite local.
2. Criar DTOs/Models no Dart (`lib/modules/core/domain/models/...`).
3. Implementar Repositories com métodos básicos (`findById`, `save`, `delete`).
4. **NÃO** criar UI ainda. Apenas a camada de dados.
## 5. STATUS DA INTERFACE (CTAs)

Os seguintes elementos de interface (CTAs) foram habilitados como parte do fluxo de navegação, mas possuem status de implementação "Provisório/Parcial". Eles existem para garantir a descoberta do recurso (feature discovery) e validar o fluxo de navegação L2/L3.

### 5.1. Botão "Nova Fazenda" (Tela Detalhe Cliente)
* **Status UI:** Habilitado (ícone `add`, label `Nova`)
* **Ação Atual:** Feedback visual (SnackBar "Em breve")
* **Contrato Futuro:** Abrir formulário `FarmFormScreen` -> Persistir em SQLite `fazendas` com `sync_status=1`.

### 5.2. Botão "Novo Talhão" (Tela Detalhe Fazenda)
* **Status UI:** Habilitado (ícone `add`, label `Novo`)
* **Ação Atual:** Feedback visual (SnackBar "Em breve")
* **Contrato Futuro:** Abrir formulário de desenho/cadastro de talhão -> Persistir em SQLite `talhoes`.

Esta definição transforma estes botões de "placeholders" para "Dívida Técnica Gerenciada" e parte oficial do domínio.
