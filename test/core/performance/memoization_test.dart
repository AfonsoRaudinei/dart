import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/performance/memoization.dart';

void main() {
  group('MemoizedCache', () {
    test('computes value on first access', () {
      var computeCount = 0;
      final cache = MemoizedCache<int, String>(
        compute: (key) {
          computeCount++;
          return 'value_$key';
        },
      );

      final result = cache.get(1);

      expect(result, 'value_1');
      expect(computeCount, 1);
    });

    test('returns cached value on subsequent access', () {
      var computeCount = 0;
      final cache = MemoizedCache<int, String>(
        compute: (key) {
          computeCount++;
          return 'value_$key';
        },
      );

      cache.get(1);
      cache.get(1);
      cache.get(1);

      expect(computeCount, 1); // Computed only once
    });

    test('computes different values for different keys', () {
      final cache = MemoizedCache<int, String>(
        compute: (key) => 'value_$key',
      );

      expect(cache.get(1), 'value_1');
      expect(cache.get(2), 'value_2');
      expect(cache.get(3), 'value_3');
    });

    test('respects maxSize and evicts oldest entry', () {
      final cache = MemoizedCache<int, String>(
        compute: (key) => 'value_$key',
        maxSize: 2,
      );

      cache.get(1);
      cache.get(2);
      cache.get(3); // Should evict key 1

      expect(cache.contains(1), false);
      expect(cache.contains(2), true);
      expect(cache.contains(3), true);
      expect(cache.size, 2);
    });

    test('invalidate removes specific entry', () {
      final cache = MemoizedCache<int, String>(
        compute: (key) => 'value_$key',
      );

      cache.get(1);
      expect(cache.contains(1), true);

      cache.invalidate(1);
      expect(cache.contains(1), false);
    });

    test('clear removes all entries', () {
      final cache = MemoizedCache<int, String>(
        compute: (key) => 'value_$key',
      );

      cache.get(1);
      cache.get(2);
      cache.get(3);

      expect(cache.size, 3);

      cache.clear();
      expect(cache.size, 0);
    });
  });

  group('MarkerCache', () {
    test('builds marker on first access', () {
      var buildCount = 0;
      final cache = MarkerCache<String>(
        build: (id, props) {
          buildCount++;
          return 'marker_$id';
        },
      );

      final result = cache.get('1', {'color': 'red'});

      expect(result, 'marker_1');
      expect(buildCount, 1);
    });

    test('returns cached marker if properties unchanged', () {
      var buildCount = 0;
      final props = {'color': 'red', 'size': 10};
      final cache = MarkerCache<String>(
        build: (id, props) {
          buildCount++;
          return 'marker_$id';
        },
      );

      cache.get('1', props);
      cache.get('1', props); // Same properties
      cache.get('1', props);

      expect(buildCount, 1); // Built only once
    });

    test('rebuilds marker if properties changed', () {
      var buildCount = 0;
      final cache = MarkerCache<String>(
        build: (id, props) {
          buildCount++;
          return 'marker_$id';
        },
      );

      cache.get('1', {'color': 'red'});
      cache.get('1', {'color': 'blue'}); // Different properties
      cache.get('1', {'color': 'green'}); // Different again

      expect(buildCount, 3); // Rebuilt each time
    });

    test('remove deletes marker from cache', () {
      final cache = MarkerCache<String>(
        build: (id, props) => 'marker_$id',
      );

      cache.get('1', {});
      expect(cache.cachedIds.contains('1'), true);

      cache.remove('1');
      expect(cache.cachedIds.contains('1'), false);
    });

    test('clear removes all markers', () {
      final cache = MarkerCache<String>(
        build: (id, props) => 'marker_$id',
      );

      cache.get('1', {});
      cache.get('2', {});
      cache.get('3', {});

      expect(cache.size, 3);

      cache.clear();
      expect(cache.size, 0);
      expect(cache.cachedIds.isEmpty, true);
    });
  });

  group('memoize', () {
    test('caches function result', () {
      var callCount = 0;
      final expensiveFn = memoize((int n) {
        callCount++;
        return n * n;
      });

      expensiveFn(5);
      expensiveFn(5);
      expensiveFn(5);

      expect(callCount, 1); // Called only once
    });

    test('computes different results for different arguments', () {
      final square = memoize((int n) => n * n);

      expect(square(2), 4);
      expect(square(3), 9);
      expect(square(4), 16);
    });
  });

  group('MemoizedValueNotifier', () {
    test('notifies on initial value', () {
      final notifier = MemoizedValueNotifier<int>(0);
      var notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      expect(notifyCount, 0); // No notification yet
    });

    test('notifies when value changes', () {
      final notifier = MemoizedValueNotifier<int>(0);
      var notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.value = 1;
      notifier.value = 2;

      expect(notifyCount, 2);
    });

    test('does not notify when value is equal', () {
      final notifier = MemoizedValueNotifier<int>(0);
      var notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.value = 0; // Same value
      notifier.value = 0;
      notifier.value = 0;

      expect(notifyCount, 0); // No notifications
    });

    test('uses custom equality function', () {
      final notifier = MemoizedValueNotifier<String>(
        'hello',
        equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
      );
      var notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.value = 'HELLO'; // Equal by case-insensitive comparison
      expect(notifyCount, 0);

      notifier.value = 'world'; // Different
      expect(notifyCount, 1);
    });
  });

  group('MemoizedListNotifier', () {
    test('notifies when list length changes', () {
      final notifier = MemoizedListNotifier<int>([1, 2, 3]);
      var notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.value = [1, 2, 3, 4]; // Length changed
      expect(notifyCount, 1);
    });

    test('notifies when list elements change', () {
      final notifier = MemoizedListNotifier<int>([1, 2, 3]);
      var notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.value = [1, 2, 999]; // Element changed
      expect(notifyCount, 1);
    });

    test('does not notify when list is identical', () {
      final list = [1, 2, 3];
      final notifier = MemoizedListNotifier<int>(list);
      var notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.value = list; // Same list reference
      expect(notifyCount, 0);
    });

    test('does not notify when list has same elements (shallow equality)', () {
      final obj1 = Object();
      final obj2 = Object();

      final notifier = MemoizedListNotifier<Object>([obj1, obj2]);
      var notifyCount = 0;

      notifier.addListener(() => notifyCount++);

      notifier.value = [obj1, obj2]; // Same objects
      expect(notifyCount, 0);
    });

    test('forceUpdate always notifies', () {
      final list = [1, 2, 3];
      final notifier = MemoizedListNotifier<int>(list);
      var notifyCount = 0;

      notifier.addListener(() {
        notifyCount++;
      });

      // Force update com nova lista (mesmo conteúdo)
      notifier.forceUpdate(List.from(list));
      expect(notifyCount, 1);
    });
  });
}
