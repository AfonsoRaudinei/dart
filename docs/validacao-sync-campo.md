## ⚠️ VALIDAÇÃO BLOQUEADA - CONFIGURAÇÃO NECESSÁRIA

### Status Pré-Campo
- ❌ Supabase não configurado (placeholders)
- ✅ Código de sync implementado
- ✅ Schema SQL criado
- ✅ Migração SQLite pronta
- ✅ GeoJSON backward compatible

### BLOQUEIO CRÍTICO

```dart
// lib/main.dart (linhas 13-17)
await Supabase.initialize(
  url: 'https://your-project.supabase.co',  // ❌ PLACEHOLDER
  anonKey: 'your-anon-key',                  // ❌ PLACEHOLDER
);
```

### AÇÕES OBRIGATÓRIAS ANTES DO TESTE

#### 1. Configurar Supabase

```bash
# Substituir placeholders em lib/main.dart
url: 'https://SEU-PROJETO.supabase.co'
anonKey: 'SUA-CHAVE-ANON'
```

#### 2. Criar Schema no Supabase

```bash
# Executar no Supabase SQL Editor:
cat supabase/schema_v1.1.sql
```

#### 3. Rebuild Completo

```bash
flutter clean
flutter pub get
flutter run
```

### CHECKLIST DE VALIDAÇÃO EM CAMPO

#### 3.1 — Offline Total
- [ ] Ativar modo avião
- [ ] Criar visita
- [ ] Criar 3+ ocorrências (pins)
- [ ] Editar ocorrências
- [ ] Encerrar visita
- [ ] Verificar: `SELECT * FROM visit_sessions WHERE sync_status = 1`
- [ ] Verificar: `SELECT * FROM occurrences WHERE sync_status = 'local'`

#### 3.2 — Persistência Local
- [ ] Matar app (force close)
- [ ] Reabrir app
- [ ] Visita intacta
- [ ] Ocorrências visíveis
- [ ] Pins permanentes no mapa

#### 3.3 — Retorno Online
- [ ] Desativar modo avião
- [ ] Aguardar 5min (ciclo de sync)
- [ ] Log: "🔄 Sync completo (silencioso)"
- [ ] Verificar Supabase dashboard: registros apareceram
- [ ] Verificar: `SELECT * FROM visit_sessions WHERE sync_status = 0`
- [ ] Verificar: `SELECT * FROM occurrences WHERE sync_status = 'synced'`
- [ ] Nenhum duplicado
- [ ] Nenhum reset visual

#### 3.4 — Regressão
- [ ] Navegar mapa
- [ ] Abrir SideMenu
- [ ] Testar modo armado
- [ ] Criar nova ocorrência online
- [ ] Comportamento inalterado

#### 3.5 — Conflitos (Local Wins)
- [ ] Criar ocorrência offline
- [ ] Editar mesma ocorrência online (via outro dispositivo)
- [ ] Conectar dispositivo offline
- [ ] Validar: versão local prevaleceu
- [ ] Nenhum dado perdido

### LOGS ESPERADOS

```
🔄 Sync completo (silencioso)
```

### LOGS DE FALHA (RETRY AUTOMÁTICO)

```
⚠️ Sync Visitas falhou: [erro]
⚠️ Sync Ocorrências falhou: [erro]
⚠️ Sync falhou (será retentado): [erro]
```

### COMANDOS SQLite PARA DEBUG

```bash
# Ver banco local
adb shell
run-as com.example.soloforte_app
cd databases
sqlite3 soloforte.db

# Queries úteis
SELECT id, sync_status, created_at FROM visit_sessions;
SELECT id, sync_status, geometry, created_at FROM occurrences;
SELECT COUNT(*) FROM occurrences WHERE sync_status = 'local';
```

### RESULTADO ESPERADO

✅ Todas as ocorrências offline sincronizadas
✅ Status correto (sync_status = 'synced')
✅ Dados no Supabase
✅ Zero perda de dados
✅ Comportamento UI inalterado
✅ Nenhuma regressão

### BLOQUEIO ATUAL

⚠️ **IMPOSSÍVEL VALIDAR SEM CONFIGURAR SUPABASE**

Substitua os placeholders no `main.dart` com credenciais reais antes de testar.
