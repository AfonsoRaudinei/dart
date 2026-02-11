# 🗺️ MapController Lifecycle Contract

## 📋 Regra de Ouro

**MapController só pode ser usado após `onMapReady` ser chamado.**

---

## ❌ O Que É PROIBIDO

1. **Chamar MapController no `initState`**
   ```dart
   @override
   void initState() {
     super.initState();
     _mapController.move(...); // ❌ PROIBIDO!
   }
   ```

2. **Usar MapController em listeners que disparam antes de onMapReady**
   ```dart
   ref.listen(someProvider, (prev, next) {
     _mapController.fitCamera(...); // ❌ PERIGOSO sem guard!
   });
   ```

3. **Criar timers ou delays artificiais**
   ```dart
   Future.delayed(Duration(seconds: 1), () {
     _mapController.move(...); // ❌ HACK! Não fazer isso!
   });
   ```

4. **Acessar `camera.zoom` antes do mapa estar pronto**
   ```dart
   final zoom = _mapController.camera.zoom; // ❌ Exceção se mapa não renderizado
   ```

---

## ✅ O Que É PERMITIDO

1. **Usar o callback oficial `onMapReady`**
   ```dart
   FlutterMap(
     mapController: _mapController,
     options: MapOptions(
       onMapReady: () {
         setState(() => _isMapReady = true); // ✅ CORRETO
       },
     ),
   )
   ```

2. **Proteger chamadas com guard `_isMapReady`**
   ```dart
   void _centerOnUser() {
     if (!_isMapReady) return; // ✅ Guard explícito
     
     _mapController.move(...);
   }
   ```

3. **Verificar antes de acessar propriedades do controller**
   ```dart
   if (_isMapReady) {
     final zoom = _mapController.camera.zoom; // ✅ Seguro
   }
   ```

---

## 🔒 Implementação Atual (PrivateMapScreen)

### 1. Flag de Guard
```dart
bool _isMapReady = false; // 🔒 Guard: MapController só pode ser usado se true
```

**Localização:** [private_map_screen.dart](../lib/ui/screens/private_map_screen.dart#L54)

### 2. Callback onMapReady
```dart
onMapReady: () {
  setState(() => _isMapReady = true);
  // Executar lógica pendente após mapa estar pronto
},
```

**Localização:** [private_map_screen.dart](../lib/ui/screens/private_map_screen.dart#L430)

### 3. Funções Protegidas

| Função | Proteção | Linha |
|--------|----------|-------|
| `_handleAutoZoom` | Verifica `_isMapReady` antes de `fitCamera` | L120 |
| `_centerOnUser` | Verifica `_isMapReady` antes de `move` | L291 |
| `MarkerLayer` (occurrences) | Condição `&& _isMapReady` | L598 |
| `MarkerLayer` (publicações) | Condição `&& _isMapReady` | L607 |

---

## 🧪 Testes

### Teste Automatizado
**Arquivo:** [test/map/map_lifecycle_test.dart](../test/map/map_lifecycle_test.dart)

**O que garante:**
- ✅ MapController não é usado antes de onMapReady
- ✅ Nenhuma exceção ocorre durante inicialização
- ✅ Guard `_isMapReady` está presente
- ✅ Callback `onMapReady` está configurado

### Como Executar
```bash
flutter test test/map/map_lifecycle_test.dart
```

---

## 🔍 Detecção de Regressão

### Script de Auditoria
**Arquivo:** [scripts/audit_mapcontroller.sh](../scripts/audit_mapcontroller.sh)

**Como usar:**
```bash
./scripts/audit_mapcontroller.sh
```

**O que verifica:**
- ✅ Presença da flag `_isMapReady`
- ✅ Presença do callback `onMapReady`
- 📍 Lista todos os usos de `_mapController.`
- 🧠 Checklist manual para code review

### Auditoria Manual (Grep)
```bash
# Listar todos os usos do MapController
grep -n "_mapController\." lib/ui/screens/private_map_screen.dart

# Verificar presença do guard
grep -n "_isMapReady" lib/ui/screens/private_map_screen.dart

# Verificar callback onMapReady
grep -n "onMapReady:" lib/ui/screens/private_map_screen.dart
```

---

## 🧠 Por Que Esse Contrato Existe?

### Contexto Técnico
O FlutterMap requer que o widget seja **renderizado ao menos uma vez** antes que o `MapController` possa ser usado. Isso acontece porque:

1. O controller precisa de acesso à câmera do mapa
2. A câmera só existe após o primeiro frame ser renderizado
3. Chamadas prematuras causam exceção: `"FlutterMap widget not rendered"`

### Histórico
Este contrato foi estabelecido após a **refatoração Stack-based do AppShell** (v1.1), que revelou um bug latente de ciclo de vida que estava mascarado na arquitetura anterior.

**ADR:** MapController Lifecycle v1.0  
**Data:** 10 de fevereiro de 2026  
**Correção:** [Commit da correção](#)

---

## ✅ Checklist para Code Review

Ao revisar código que usa MapController:

- [ ] Nenhuma chamada ao `_mapController` no `initState`
- [ ] Todos os usos verificam `_isMapReady` antes de executar
- [ ] Callback `onMapReady` está configurado e marca `_isMapReady = true`
- [ ] Nenhum timer ou delay artificial foi adicionado
- [ ] Teste `map_lifecycle_test.dart` está passando
- [ ] Script `audit_mapcontroller.sh` não reporta erros

---

## 📚 Referências

- **FlutterMap Documentation:** https://docs.fleaflet.dev/
- **Flutter Widget Lifecycle:** https://api.flutter.dev/flutter/widgets/State-class.html
- **Teste do Contrato:** [test/map/map_lifecycle_test.dart](../test/map/map_lifecycle_test.dart)
- **Script de Auditoria:** [scripts/audit_mapcontroller.sh](../scripts/audit_mapcontroller.sh)

---

**Última atualização:** 10 de fevereiro de 2026  
**Versão:** 1.0  
**Responsável:** Equipe SoloForte
