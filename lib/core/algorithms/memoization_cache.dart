import 'dart:collection';

/// Generic bounded LRU (Least Recently Used) cache for memoizing expensive computations.
class MemoizationCache<K, V> {
  final int capacity;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  MemoizationCache({this.capacity = 100}) : assert(capacity > 0);

  /// Retrieves a cached value, refreshing its recency in the LRU order.
  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    final value = _cache.remove(key) as V;
    _cache[key] = value;
    return value;
  }

  /// Puts a value into the cache. If capacity is exceeded, the least recently used item is evicted.
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= capacity) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = value;
  }

  /// Gets the cached value or computes and stores it if not present.
  V getOrCompute(K key, V Function(K key) compute) {
    final existing = get(key);
    if (existing != null) return existing;

    final computed = compute(key);
    put(key, computed);
    return computed;
  }

  /// Returns the current number of cached items.
  int get size => _cache.length;

  /// Clears all cached items.
  void clear() => _cache.clear();
}
