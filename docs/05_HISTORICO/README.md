# ÍNDICE DE CONTRATOS ARQUITETURAIS — SOLOFORTE
**Atualizado em:** 08/02/2026

Este índice organiza todos os contratos arquiteturais vigentes do projeto SoloForte.

---

## 📜 HIERARQUIA DE DOCUMENTOS

### 🏛️ Contratos Fundamentais (Obrigatórios)

Estes documentos definem a arquitetura nuclear do sistema:

1. **[Navegação](./arquitetura-navegacao.md)**
   - Map-first philosophy
   - One FAB (SmartButton)
   - No AppBar
   - SideMenu behavior
   - Dashboard map-centric

2. **[Namespaces de Rotas](./arquitetura-namespaces-rotas.md)**
   - Detecção por namespace, não rota exata
   - `/dashboard/*` como domínio funcional
   - Navegação declarativa obrigatória
   - Proibições de `pop()` e stack-based navigation

3. **[Persistência Geoespacial](./arquitetura-persistencia.md)**
   - Offline-first (SQLite)
   - Estados de sincronização
   - Soft Delete obrigatório
   - Fonte da verdade local vs remota

4. **[Modo Desenho e Edição Geográfica](./arquitetura-navegacao.md#6-modo-desenho-e-edicao-geografica)**
   - Desenho como estado, não rota
   - SmartButton permanece imutável
   - Controles explícitos de confirmação/cancelamento

5. **[Ocorrências Geoespaciais](./arquitetura-ocorrencias.md)**
   - Eventos técnicos georreferenciados
   - Independência de sessão
   - Geometria obrigatória (GeoJSON)
   - Persistência local garantida

---

## 🔧 Contratos Técnicos (Especializados)

### Implementação e Integrações

6. **[GPS e Localização](./gps-integracao.md)**
   - Dependência obrigatória para mapa
   - Validação antes de funcionalidades geográficas
   - Comportamento em caso de indisponibilidade

7. **[Persistência Agrícola](./persistenca-agricola.md)**
   - Schema de Clientes, Fazendas, Talhões
   - Relacionamentos hierárquicos
   - Estratégia de sincronização futura

---

## 📋 Validações e Checklists

8. **[Validação: SmartButton Dashboard Namespace](./validation_smartbutton_dashboard_namespace.md)**
   - Fix definitivo do bug namespace
   - Checklist de testes manuais
   - Conformidade arquitetural

9. **[Validação: SmartButton (Legacy)](./validation_checklist_smartbutton.md)**
   - Checklist antigo (pode ser depreciado)

---

## 🎯 Como Usar Este Índice

### Para Desenvolvedores

Antes de implementar qualquer feature que envolva:
- **Navegação** → Ler contratos 1 e 2
- **Mapa/Geometria** → Ler contratos 3, 4 e 5
- **Dados de campo** → Ler contratos 3, 5 e 7
- **Localização** → Ler contrato 6

### Para Revisores de Código

Ao revisar PRs, validar conformidade com:
- Contrato de **Namespaces** (proibição de `pop()`, path exato)
- Contrato de **Persistência** (offline-first, soft delete)
- Contrato de **Navegação** (Map-first, One FAB)

### Para Agentes IA

Todo prompt técnico deve incluir:
```
Seguir rigorosamente os contratos arquiteturais em docs/:
- arquitetura-navegacao.md
- arquitetura-namespaces-rotas.md
- arquitetura-persistencia.md
- arquitetura-ocorrencias.md

Se houver conflito, os contratos prevalecem.
```

---

## 🚫 Proibições Transversais (Todos os Contratos)

Independente do módulo, é **sempre proibido**:

1. ❌ `Navigator.pop()` ou `context.pop()` para navegação primária
2. ❌ Comparação exata de rotas (`path == '/dashboard'`) em componentes globais
3. ❌ Hard Delete em dados sincronizáveis
4. ❌ Depender de conectividade para ações de campo
5. ❌ Criar geometrias sem persistência local
6. ❌ AppBar padrão do Material Design
7. ❌ Múltiplos FABs na mesma tela
8. ❌ Inferir estado de sync por heurística

---

## 📅 Histórico de Atualizações

| Data | Documento | Mudança |
|---|---|---|
| 08/02/2026 | `arquitetura-namespaces-rotas.md` | **Criado** — Formalização de namespaces |
| 08/02/2026 | `arquitetura-persistencia.md` | **Criado** — Offline-first SQLite |
| 08/02/2026 | `arquitetura-ocorrencias.md` | **Criado** — Eventos geoespaciais |
| 08/02/2026 | `arquitetura-navegacao.md` | **Atualizado** — Modo Desenho + Namespaces |
| 04/02/2026 | `arquitetura-navegacao.md` | **Criado** — Map-first, One FAB |

---

## ✅ Status de Conformidade

Todos os contratos listados são:
- ✅ **Oficiais**
- ✅ **Obrigatórios**
- ✅ **Validados por Engenheiro Sênior Flutter/Dart (Top 0.1%)**
- ❌ **Não opcionais**
- ❌ **Não sujeitos a exceções sem revisão formal**

---

**FIM DO ÍNDICE**
