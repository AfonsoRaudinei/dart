# RELATÓRIO: ALERTA GEOGRÁFICO POR DISTÂNCIA

**Data:** 21 de fevereiro de 2026  
**Módulo:** Agenda  
**Escopo:** Isolado - sem alterações em outros módulos

---

## 📋 RESUMO EXECUTIVO

A Agenda do SoloForte App agora possui **alerta automático de distância excessiva** entre visitas consecutivas no mesmo dia, **sem bloquear o salvamento**.

### ✅ Funcionalidades Implementadas

1. **Cálculo de distância** usando fórmula Haversine (precisão geográfica)
2. **Detecção automática** de possível conflito logístico
3. **Dialog informativo** (não bloqueante) ao criar visita
4. **Indicador visual** discreto em visitas com aviso
5. **Flag interna** `hasDistanceWarning` para rastreamento

---

## 🎯 REGRA DE NEGÓCIO

### Critério de Aviso

Alerta é exibido quando **TODAS** as condições são atendidas:

```
✓ Mesma data
✓ Distância > 50 km
✓ Intervalo entre visitas < 1 hora
✓ Ambas visitas têm localização (lat/lng)
✓ Ambas visitas têm horário definido
```

### Comportamento

1. **Ao criar visita:** sistema verifica conflitos
2. **Se detectado:** mostra dialog com informações
3. **Usuário escolhe:**
   - **Revisar:** volta ao formulário
   - **Continuar:** salva normalmente
4. **Nunca bloqueia** o salvamento

---

## 📂 ARQUIVOS MODIFICADOS

### 1. Entidades

#### `/lib/modules/agenda/domain/entities/event.dart`
**Adições:**
- ➕ `double? latitude` - Coordenada geográfica
- ➕ `double? longitude` - Coordenada geográfica
- ➕ `bool hasDistanceWarning` - Flag de aviso (padrão: false)

**Atualizado:**
- Construtor com novos parâmetros opcionais
- `copyWith()` com novos campos
- `props` com novos campos

#### `/lib/modules/agenda/domain/entities/visit.dart`
**Adições:**
- ➕ `hasLocation` getter - Verifica se tem lat/lng
- ➕ `distanceToInKm(Event other)` - Calcula distância em km
- ➕ `hasLogisticalConflictWith(Event other)` - Verifica conflito
- ➕ Implementação completa de **Haversine** (sem dependências externas)

**Métodos matemáticos implementados:**
```dart
_haversineDistance() // Fórmula principal
_degreesToRadians()  // Conversão graus → radianos
_sin(), _cos()       // Funções trigonométricas
_sqrt()              // Raiz quadrada (método Newton)
_atan(), _atan2()    // Arco tangente
```

### 2. Providers

#### `/lib/modules/agenda/presentation/providers/agenda_provider.dart`
**Adições:**
- ➕ `checkDistanceWarning()` - Valida conflitos de distância
- ➕ Classe `DistanceWarning` - Informações sobre o conflito
- ✏️ `createEvent()` aceita `latitude` e `longitude`

**Lógica de validação:**
1. Busca visitas do mesmo dia
2. Ordena por horário
3. Verifica conflitos com visita consecutiva
4. Retorna `DistanceWarning` se detectar

### 3. Widgets

#### `/lib/modules/agenda/presentation/widgets/distance_warning_dialog.dart` *(NOVO)*
**Características:**
- Dialog informativo com ícone âmbar
- Mostra distância calculada
- Exibe detalhes da visita conflitante
- Recomendação de ajuste
- Botões: "Revisar" ou "Continuar Mesmo Assim"

#### `/lib/modules/agenda/presentation/widgets/visit_form_dialog.dart`
**Modificações:**
- ➕ Campos `_latitude` e `_longitude`
- ✏️ `_submitForm()` verifica aviso de distância
- ✏️ Integração com `DistanceWarningDialog`
- ✏️ Passa lat/lng para `createEvent()`

**Fluxo atualizado:**
```
1. Validação local (horário)
   ↓
2. Verificação de conflito de horário (já existente)
   ↓
3. Verificação de aviso de distância (NOVO)
   ↓ (se detectado)
4. Dialog de aviso
   ↓
5. Usuário escolhe revisar ou continuar
   ↓
6. Salva normalmente
```

#### `/lib/modules/agenda/presentation/widgets/day_event_card.dart`
**Adições:**
- ➕ Indicador âmbar discreto se `hasDistanceWarning == true`
- ➕ Tooltip: "Possível conflito logístico"
- ➕ Ícone: `warning_amber_rounded` (14px)

---

## 🧮 FÓRMULA HAVERSINE

### Implementação

Cálculo de distância entre dois pontos geográficos:

```dart
d = 2r × arcsin(√(sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlon/2)))

onde:
r = raio da Terra (6371 km)
Δlat = lat2 - lat1 (em radianos)
Δlon = lon2 - lon1 (em radianos)
```

### Precisão

- **Erro médio:** < 0.5%
- **Adequado para:** distâncias até 500 km
- **Sem dependências:** implementação pura em Dart

---

## 🎨 INDICADORES VISUAIS

### No DayEventCard (Planejamento)

**Visita SEM aviso:**
```
┌─────────────────────────────┐
│ Visita Técnica - Cliente X  │
│ 09:00 - 11:00  [Normal]     │
└─────────────────────────────┘
```

**Visita COM aviso:**
```
┌─────────────────────────────┐
│ Visita Técnica - Cliente Y  │
│ 11:30 - 13:30  [Alta] ⚠️    │
│ └─ Possível conflito logístico
└─────────────────────────────┘
```

### No Dialog de Aviso

```
⚠️ Atenção: Distância entre visitas

┌──────────────────────────────────┐
│ ℹ️ Distância de 65.3 km entre    │
│    visitas com intervalo curto.  │
│    Verifique logística.          │
└──────────────────────────────────┘

Visita conflitante:
┌──────────────────────────────────┐
│ 📅 Visita Técnica - Cliente X    │
│ ⏰ 09:00 - 11:00                 │
└──────────────────────────────────┘

💡 Considere ajustar horários ou
   priorizar visitas próximas.

[Revisar]  [Continuar Mesmo Assim]
```

---

## 📊 EXEMPLO DE USO

### Cenário 1: Sem Conflito

```dart
Visita A:
- Local: Fazenda Norte
- Horário: 08:00 - 10:00
- Coordenadas: -23.5505, -46.6333

Visita B:
- Local: Fazenda Sul
- Horário: 14:00 - 16:00  // Intervalo > 1h
- Coordenadas: -23.6000, -46.7000

Distância: ~12 km
Intervalo: 4 horas
Resultado: ✅ Sem aviso
```

### Cenário 2: Com Conflito

```dart
Visita A:
- Local: Fazenda Norte
- Horário: 09:00 - 11:00
- Coordenadas: -23.5505, -46.6333

Visita B:
- Local: Fazenda Extremo Sul
- Horário: 11:30 - 13:30  // Intervalo < 1h
- Coordenadas: -24.1000, -47.2000

Distância: ~78 km
Intervalo: 30 minutos
Resultado: ⚠️ AVISO EXIBIDO
```

### Cenário 3: Sem Localização

```dart
Visita A:
- Local: Fazenda Norte
- Horário: 09:00 - 11:00
- Coordenadas: null  // Sem localização

Visita B:
- Local: Fazenda Sul
- Horário: 11:30 - 13:30
- Coordenadas: -23.6000, -46.7000

Resultado: ✅ Sem validação (não bloqueia)
```

---

## 🔒 VALIDAÇÕES

### Compilação
- ✅ Zero erros de compilação
- ✅ Todos os arquivos formatados
- ✅ Imports corretos

### Isolamento
- ✅ Dashboard não alterado
- ✅ Mapa não alterado
- ✅ Navegação global não alterada
- ✅ Outros módulos não alterados

### Compatibilidade
- ✅ Campos opcionais (lat/lng)
- ✅ Visitas antigas funcionam
- ✅ Sem localização = sem validação

---

## 🚀 INTEGRAÇÃO

### Como Adicionar Localização ao Criar Visita

```dart
await ref.read(agendaProvider.notifier).createEvent(
  tipo: EventType.visitaTecnica,
  clienteId: 'client-id',
  titulo: 'Visita Técnica',
  dataInicioPlanejada: DateTime(2026, 2, 21, 9, 0),
  dataFimPlanejada: DateTime(2026, 2, 21, 11, 0),
  startTime: TimeOfDay(hour: 9, minute: 0),
  endTime: TimeOfDay(hour: 11, minute: 0),
  priority: VisitPriority.alta,
  latitude: -23.5505,  // ← NOVO
  longitude: -46.6333, // ← NOVO
);
```

### Como o Sistema Valida

```dart
// Automático no createEvent
final warning = checkDistanceWarning(
  date: data,
  startTime: inicio,
  endTime: fim,
  latitude: lat,
  longitude: lng,
);

if (warning != null) {
  // Mostra dialog
  final continuar = await DistanceWarningDialog.show(context, warning);
  
  if (!continuar) {
    return; // Usuário escolheu revisar
  }
}

// Salva normalmente
```

---

## 📝 NOTAS TÉCNICAS

### Por Que Haversine?

1. **Precisão adequada** para agricultura (< 0.5% erro)
2. **Sem dependências** externas (implementação pura)
3. **Leve** computacionalmente
4. **Funciona offline**

### Por Que Não Bloquear?

1. **Flexibilidade operacional** - campo pode ter urgências
2. **Usuário conhece melhor** o contexto local
3. **Estradas rurais** podem ter atalhos não mapeados
4. **Aviso é suficiente** para decisão informada

### Limitações Conhecidas

1. **Linha reta:** não considera estradas reais
2. **Distâncias longas:** precisão reduz (> 500 km)
3. **Terra plana assumida** localmente (OK para uso rural)

---

## ✅ CHECKLIST DE ENTREGA

- [x] Campos de localização adicionados
- [x] Função Haversine implementada
- [x] Validação de distância criada
- [x] Dialog de aviso implementado
- [x] Indicador visual adicionado
- [x] Integração com formulário
- [x] Zero erros de compilação
- [x] Código formatado
- [x] Isolamento validado
- [x] Testes manuais realizados

---

## 🎯 RESULTADO ESTRATÉGICO

A Agenda agora oferece **inteligência logística** sem sacrificar flexibilidade:

- ✔ Previne deslocamentos inviáveis
- ✔ Alerta sobre otimização de rota
- ✔ Mantém autonomia do usuário
- ✔ Base para relatórios de eficiência
- ✔ Planejamento mais realista

**Impacto:**  
Redução de tempo em trânsito, otimização de rotas, planejamento mais eficiente, sem bloqueios desnecessários.

---

**Fim do Relatório** ✅
