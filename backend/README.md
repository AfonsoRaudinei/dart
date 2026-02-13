# 🚀 SoloForte Backend - Feature Flags Server

Backend Dart puro para gerenciamento de Feature Flags com suporte a rollout progressivo, kill switch, e validação server-side.

## 📦 Estrutura

```
backend/
├── bin/
│   └── server.dart                    # Entry point do servidor
├── lib/
│   ├── routes/
│   │   ├── feature_flag_routes.dart   # GET /api/feature-flags
│   │   └── admin_routes.dart          # CRUD /admin/flags
│   ├── middleware/
│   │   ├── auth_middleware.dart       # Autenticação + CORS + Rate limit
│   │   └── feature_flag_validator.dart # Validação server-side
│   └── storage/
│       └── feature_flag_storage.dart  # Storage JSON (substituível por DB)
├── data/
│   └── feature_flags.json             # Arquivo de flags (gerado automaticamente)
└── pubspec.yaml
```

---

## 🏃 Quick Start

### 1️⃣ Instalar Dependências

```bash
cd backend
dart pub get
```

### 2️⃣ Iniciar Servidor

```bash
dart run bin/server.dart
```

Ou especificar porta:

```bash
dart run bin/server.dart 3000
```

### 3️⃣ Testar

```bash
# Health check
curl http://localhost:8080/health

# Listar flags (app client)
curl -H "Authorization: Bearer app-client-token-2026" \
     http://localhost:8080/api/feature-flags

# Flag específica
curl -H "Authorization: Bearer app-client-token-2026" \
     http://localhost:8080/api/feature-flags/drawing_v1
```

---

## 🔐 Autenticação

### Tokens

| Token | Tipo | Uso |
|---|---|---|
| `app-client-token-2026` | App Client | Leitura de flags (`/api/`) |
| `admin-secret-token-2026` | Admin | CRUD de flags (`/admin/`) |

**TODO**: Substituir por JWT, OAuth2, ou sistema de autenticação real.

### Headers

```http
Authorization: Bearer <token>
```

---

## 📡 API Endpoints

### Públicos (App Client)

#### `GET /api/feature-flags`

Retorna todas as flags.

**Request:**
```bash
curl -H "Authorization: Bearer app-client-token-2026" \
     http://localhost:8080/api/feature-flags
```

**Response:**
```json
{
  "flags": [
    {
      "key": "drawing_v1",
      "enabled": true,
      "rollout_percentage": 100,
      "allowed_roles": ["consultor", "produtor"],
      "version": 1,
      "min_app_version": null
    }
  ]
}
```

#### `GET /api/feature-flags/<key>`

Retorna flag específica.

**Request:**
```bash
curl -H "Authorization: Bearer app-client-token-2026" \
     http://localhost:8080/api/feature-flags/drawing_v1
```

**Response:**
```json
{
  "flag": {
    "key": "drawing_v1",
    "enabled": true,
    "rollout_percentage": 100,
    "allowed_roles": ["consultor", "produtor"],
    "version": 1
  }
}
```

---

### Admin (CRUD Protegido)

#### `GET /admin/flags`

Lista todas as flags com metadados admin.

**Request:**
```bash
curl -H "Authorization: Bearer admin-secret-token-2026" \
     http://localhost:8080/admin/flags
```

**Response:**
```json
{
  "flags": [...],
  "total": 1,
  "timestamp": "2026-02-12T10:30:00.000Z"
}
```

#### `POST /admin/flags`

Cria nova flag.

**Request:**
```bash
curl -X POST \
  -H "Authorization: Bearer admin-secret-token-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "key": "new_feature_v1",
    "enabled": true,
    "rollout_percentage": 50,
    "allowed_roles": ["consultor"],
    "version": 1
  }' \
  http://localhost:8080/admin/flags
```

**Response:**
```json
{
  "message": "Flag created",
  "flag": {...}
}
```

#### `PUT /admin/flags/<key>`

Atualiza flag existente.

**Request:**
```bash
curl -X PUT \
  -H "Authorization: Bearer admin-secret-token-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": false,
    "rollout_percentage": 0
  }' \
  http://localhost:8080/admin/flags/drawing_v1
```

**Response:**
```json
{
  "message": "Flag updated",
  "flag": {...}
}
```

**Kill Switch Example:**
```bash
curl -X PUT \
  -H "Authorization: Bearer admin-secret-token-2026" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false, "rollout_percentage": 0}' \
  http://localhost:8080/admin/flags/drawing_v1
```

#### `DELETE /admin/flags/<key>`

Deleta flag.

**Request:**
```bash
curl -X DELETE \
  -H "Authorization: Bearer admin-secret-token-2026" \
  http://localhost:8080/admin/flags/drawing_v1
```

**Response:**
```json
{
  "message": "Flag deleted",
  "key": "drawing_v1"
}
```

---

## 🛡️ Validação Server-Side em Endpoints Protegidos

### Uso

Para proteger um endpoint que depende de feature flag:

```dart
import 'package:shelf/shelf.dart';
import 'lib/middleware/feature_flag_validator.dart';
import 'lib/storage/feature_flag_storage.dart';

void main() {
  final storage = FeatureFlagStorage();
  final validator = FeatureFlagValidator(storage);

  // Endpoint protegido por drawing_v1
  final drawingHandler = Pipeline()
      .addMiddleware(validator.requireFeature('drawing_v1'))
      .addHandler(_drawingSyncHandler);

  // Se flag desabilitada ou usuário não no rollout → 403 Forbidden
}

Response _drawingSyncHandler(Request request) {
  // Lógica de sync de drawing
  return Response.ok('Drawing synced');
}
```

### Headers Necessários

| Header | Descrição |
|---|---|
| `X-User-Id` | ID único do usuário (obrigatório) |
| `X-User-Role` | Papel do usuário (`consultor`/`produtor`) |
| `X-App-Version` | Versão do app (ex: `1.1.0`) |

### Exemplo

```bash
curl -X POST \
  -H "Authorization: Bearer app-client-token-2026" \
  -H "X-User-Id: user-123" \
  -H "X-User-Role: consultor" \
  -H "X-App-Version: 1.1.0" \
  http://localhost:8080/api/drawing/sync
```

**Se feature desabilitada:**
```json
{
  "error": "Feature not available",
  "feature": "drawing_v1",
  "reason": "Feature flag disabled or user not in rollout"
}
```

---

## 🔧 Middleware Disponíveis

### `AuthMiddleware`

```dart
// Proteger com token de app client
Pipeline().addMiddleware(AuthMiddleware.appAuth())

// Proteger com token de admin
Pipeline().addMiddleware(AuthMiddleware.adminAuth())

// Rate limiting (1000 req/min por IP)
Pipeline().addMiddleware(AuthMiddleware.rateLimit(maxRequests: 1000))
```

### `corsHeaders()`

Habilita CORS para requests de browsers.

### `requestLogger()`

Loga todas as requests e responses.

### `FeatureFlagValidator`

Valida feature flags em endpoints protegidos.

```dart
validator.requireFeature('drawing_v1')
```

---

## 📊 Storage

### JSON File (atual)

Flags armazenadas em `data/feature_flags.json`.

**Estrutura:**
```json
{
  "flags": [
    {
      "key": "drawing_v1",
      "enabled": true,
      "rollout_percentage": 100,
      "allowed_roles": ["consultor", "produtor"],
      "version": 1,
      "min_app_version": null,
      "created_at": "2026-02-12T10:00:00.000Z",
      "updated_at": "2026-02-12T10:30:00.000Z"
    }
  ],
  "updated_at": "2026-02-12T10:30:00.000Z"
}
```

### Migração para Banco de Dados

Para produção, substituir `FeatureFlagStorage` por adaptador de banco:

```dart
// lib/storage/postgres_storage.dart
class PostgresFeatureFlagStorage implements FeatureFlagStorage {
  final DatabaseConnection _db;

  @override
  Future<List<Map<String, dynamic>>> getAllFlags() async {
    final result = await _db.query('SELECT * FROM feature_flags');
    return result.toList();
  }

  // ...
}
```

---

## 🧪 Testes

```bash
# TODO: Implementar testes
dart test
```

---

## 🚀 Deploy

### Docker

Criar `Dockerfile`:

```dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/
EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]
```

Build e run:

```bash
docker build -t soloforte-backend .
docker run -p 8080:8080 soloforte-backend
```

### Cloud Run / Heroku

Adicionar `Procfile`:

```
web: dart run bin/server.dart $PORT
```

---

## 📝 TODO

- [ ] JWT authentication (substituir tokens fixos)
- [ ] Integração com banco de dados real
- [ ] Testes de integração
- [ ] Metrics/observabilidade (Prometheus)
- [ ] Admin UI web (dashboard)
- [ ] Logs estruturados
- [ ] Health checks avançados
- [ ] Backup automático de flags

---

## 🔒 Segurança

⚠️ **IMPORTANTE**: Este é um servidor de desenvolvimento/POC.

Para produção:
- ✅ Substituir tokens fixos por JWT/OAuth2
- ✅ HTTPS obrigatório
- ✅ Validação de input rigorosa
- ✅ Rate limiting por usuário (não só por IP)
- ✅ Logs de auditoria
- ✅ Backup de flags
- ✅ Ambiente secrets (não hardcoded)

---

## 📚 Recursos

- [Shelf Package](https://pub.dev/packages/shelf)
- [Shelf Router](https://pub.dev/packages/shelf_router)
- [Feature Flags Best Practices](https://martinfowler.com/articles/feature-toggles.html)

---

**Status**: ✅ Backend completo e funcional  
**Port**: `8080` (configurável)  
**Ready for**: Integração com app Flutter
