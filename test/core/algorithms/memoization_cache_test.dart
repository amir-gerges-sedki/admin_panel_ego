import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/algorithms/memoization_cache.dart';

void main() {
  group('MemoizationCache LRU Tests', () {
    test('Stores and retrieves cached values', () {
      final cache = MemoizationCache<String, int>(capacity: 3);

      cache.put('a', 10);
      cache.put('b', 20);

      expect(cache.get('a'), equals(10));
      expect(cache.get('b'), equals(20));
      expect(cache.get('c'), isNull);
    });

    test('Evicts least recently used items when capacity is reached', () {
      final cache = MemoizationCache<String, int>(capacity: 3);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Access 'a' to make it recently used -> order of LRU is now: b, c, a
      expect(cache.get('a'), equals(1));

      // Put 'd' -> 'b' should be evicted
      cache.put('d', 4);

      expect(cache.get('b'), isNull);
      expect(cache.get('a'), equals(1));
      expect(cache.get('c'), equals(3));
      expect(cache.get('d'), equals(4));
    });

    test('getOrCompute computes only once for same key', () {
      final cache = MemoizationCache<String, int>(capacity: 5);
      int computeCount = 0;

      int computeVal(String k) {
        computeCount++;
        return k.length * 10;
      }

      final val1 = cache.getOrCompute('hello', computeVal);
      expect(val1, equals(50));
      expect(computeCount, equals(1));

      final val2 = cache.getOrCompute('hello', computeVal);
      expect(val2, equals(50));
      expect(computeCount, equals(1)); // Was not recomputed!
    });
  });
}
