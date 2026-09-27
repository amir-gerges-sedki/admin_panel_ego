/// High-performance in-memory search indexer using normalized tokenized inverted indexing.
///
/// Enables fast substring, multi-keyword, and prefix matching across multiple item fields.
class SearchIndexer<T> {
  final Map<String, Set<T>> _invertedIndex = {};
  final List<T> _items = [];
  final List<String> Function(T item) _tokenExtractor;

  SearchIndexer({
    required this._tokenExtractor,
    List<T> initialItems = const [],
  }) {
    if (initialItems.isNotEmpty) {
      indexAll(initialItems);
    }
  }

  /// Normalizes a string into lowercased search tokens.
  static List<String> tokenize(String input) {
    final clean = input.toLowerCase().trim();
    if (clean.isEmpty) return const [];

    // Split on whitespace, punctuation, brackets, parentheses, hyphens, and slashes
    final rawTokens = clean.split(RegExp(r'[\s,._/\\|#\-+()\[\]{}!?:;"*~`]+'));
    final Set<String> tokens = {};

    for (final token in rawTokens) {
      final t = token.trim();
      if (t.isNotEmpty) {
        tokens.add(t);
        // Include full text for multi-word exact matches
        if (clean != t && clean.length <= 100) {
          tokens.add(clean);
        }
      }
    }

    return tokens.toList();
  }


  /// Indexes a single item.
  void indexItem(T item) {
    _items.add(item);
    final rawTokens = _tokenExtractor(item);

    for (final raw in rawTokens) {
      final tokens = tokenize(raw);
      for (final t in tokens) {
        _invertedIndex.putIfAbsent(t, () => {}).add(item);
      }
    }
  }

  /// Clears and re-indexes all items.
  void indexAll(List<T> items) {
    clear();
    for (final item in items) {
      indexItem(item);
    }
  }

  /// Clears the index.
  void clear() {
    _invertedIndex.clear();
    _items.clear();
  }

  /// Returns all currently indexed items.
  List<T> get allItems => List.unmodifiable(_items);

  /// Searches the index with a query string.
  ///
  /// Multiple query tokens are matched using intersection (AND logic).
  /// If query is empty, returns all items.
  List<T> search(String query) {
    final queryTokens = tokenize(query);
    if (queryTokens.isEmpty) return List.unmodifiable(_items);

    Set<T>? matchingSet;

    for (final qToken in queryTokens) {
      final Set<T> tokenMatches = {};

      // Direct match or prefix/substring match in inverted index
      for (final entry in _invertedIndex.entries) {
        final indexedToken = entry.key;
        if (indexedToken.contains(qToken) || qToken.contains(indexedToken)) {
          tokenMatches.addAll(entry.value);
        }
      }

      if (matchingSet == null) {
        matchingSet = Set<T>.from(tokenMatches);
      } else {
        matchingSet = matchingSet.intersection(tokenMatches);
      }

      if (matchingSet.isEmpty) break;
    }

    return matchingSet?.toList() ?? const [];
  }
}
