import 'package:flutter/foundation.dart';

/// Utilitários para memoização e cache de objetos caros de construir.
/// 
/// Útil para:
/// - Markers de mapa (evitar reconstrução a cada frame)
/// - Polígonos complexos (cache de coordenadas processadas)
/// - Ícones customizados (cache de ByteData)
/// 
/// Exemplo:
/// ```dart
/// final markerCache = MemoizedCache<String, Marker>(
///   compute: (id) => _buildMarker(id),
///   maxSize: 100,
/// );
/// ```
class MemoizedCache<K, V> {
  final Map<K, V> _cache = {};
  final V Function(K key) compute;
  final int maxSize;

  MemoizedCache({
    required this.compute,
    this.maxSize = 100,
  });

  /// Obtém valor do cache ou calcula se não existir.
  V get(K key) {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // Limpar cache se exceder tamanho máximo (LRU simplificado)
    if (_cache.length >= maxSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }

    final value = compute(key);
    _cache[key] = value;
    return value;
  }

  /// Invalida entrada específica do cache.
  void invalidate(K key) {
    _cache.remove(key);
  }

  /// Limpa todo o cache.
  void clear() {
    _cache.clear();
  }

  /// Tamanho atual do cache.
  int get size => _cache.length;

  /// Verifica se chave está no cache.
  bool contains(K key) => _cache.containsKey(key);
}

/// Cache especializado para markers de mapa.
/// 
/// Usa hash de propriedades para detectar mudanças.
class MarkerCache<T> {
  final Map<String, T> _cache = {};
  final T Function(String id, Object properties) build;
  final Map<String, int> _propertyHashes = {};

  MarkerCache({required this.build});

  /// Obtém marker, reconstruindo apenas se propriedades mudaram.
  T get(String id, Object properties) {
    final currentHash = properties.hashCode;
    final cachedHash = _propertyHashes[id];

    // Cache hit: propriedades não mudaram
    if (cachedHash == currentHash && _cache.containsKey(id)) {
      return _cache[id]!;
    }

    // Cache miss ou propriedades mudaram: rebuild
    final marker = build(id, properties);
    _cache[id] = marker;
    _propertyHashes[id] = currentHash;

    return marker;
  }

  /// Remove marker do cache.
  void remove(String id) {
    _cache.remove(id);
    _propertyHashes.remove(id);
  }

  /// Limpa cache.
  void clear() {
    _cache.clear();
    _propertyHashes.clear();
  }

  /// IDs atualmente em cache.
  Set<String> get cachedIds => _cache.keys.toSet();

  /// Tamanho do cache.
  int get size => _cache.length;
}

/// Memoiza resultado de função pura baseado em parâmetros.
/// 
/// Exemplo:
/// ```dart
/// final expensiveCalc = memoize((int n) {
///   // Cálculo pesado
///   return fibonacci(n);
/// });
/// 
/// expensiveCalc(10); // Calcula
/// expensiveCalc(10); // Retorna do cache
/// ```
Function memoize(Function fn) {
  final cache = <String, dynamic>{};

  return ([a, b, c, d, e]) {
    final key = '$a:$b:$c:$d:$e';

    if (cache.containsKey(key)) {
      return cache[key];
    }

    final result = Function.apply(fn, [a, b, c, d, e].where((x) => x != null).toList());
    cache[key] = result;
    return result;
  };
}

/// ValueNotifier memoizado que só notifica quando valor realmente muda.
/// 
/// Previne rebuilds desnecessários quando valor é semanticamente igual.
class MemoizedValueNotifier<T> extends ValueNotifier<T> {
  final bool Function(T a, T b)? equals;

  MemoizedValueNotifier(
    super.value, {
    this.equals,
  });

  @override
  set value(T newValue) {
    // Usar comparador customizado ou == padrão
    final areEqual = equals != null ? equals!(value, newValue) : value == newValue;

    if (!areEqual) {
      super.value = newValue;
    }
  }
}

/// Lista memoizada que só notifica quando conteúdo realmente muda.
/// 
/// Útil para listas de features/markers que podem ser recalculadas mas
/// frequentemente resultam nos mesmos objetos.
class MemoizedListNotifier<T> extends ValueNotifier<List<T>> {
  MemoizedListNotifier(super.value);

  @override
  set value(List<T> newValue) {
    // Comparar por referências dos elementos (shallow equality)
    if (value.length != newValue.length) {
      super.value = newValue;
      return;
    }

    for (var i = 0; i < value.length; i++) {
      if (!identical(value[i], newValue[i])) {
        super.value = newValue;
        return;
      }
    }

    // Listas são idênticas, não notificar
  }

  /// Atualiza forçando notificação mesmo se lista for igual.
  void forceUpdate(List<T> newValue) {
    super.value = newValue;
  }
}
