/// High-performance combinatorial algorithms for N-ary Cartesian product generation.
class CartesianProduct {
  CartesianProduct._();

  /// Computes the Cartesian product of multiple lists of elements.
  ///
  /// Example:
  /// `CartesianProduct.compute([['A', 'B'], ['1', '2']])`
  /// returns `[['A', '1'], ['A', '2'], ['B', '1'], ['B', '2']]`.
  ///
  /// Complexity: O(∏ |L_i|).
  static List<List<T>> compute<T>(List<List<T>> dimensions) {
    if (dimensions.isEmpty) return const [];
    if (dimensions.any((dim) => dim.isEmpty)) return const [];

    List<List<T>> result = [[]];

    for (final dimension in dimensions) {
      final List<List<T>> temp = [];
      for (final currentCombination in result) {
        for (final item in dimension) {
          temp.add([...currentCombination, item]);
        }
      }
      result = temp;
    }

    return result;
  }

  /// Computes the Cartesian product of named attribute sets represented as a Map of keys to lists of values,
  /// with optional predicate-based early pruning.
  ///
  /// Example:
  /// ```dart
  /// CartesianProduct.computeNamed<String>({
  ///   'Style': ['MTL', 'DL'],
  ///   'Nicotine': ['3mg', '6mg', '20mg', '50mg'],
  ///   'Size': ['30ml', '60ml'],
  /// }, validator: (candidate) {
  ///   if (candidate['Style'] == 'DL') {
  ///     return candidate['Nicotine'] == '3mg' || candidate['Nicotine'] == '6mg';
  ///   }
  ///   return true;
  /// });
  /// ```
  static List<Map<String, T>> computeNamed<T>(
    Map<String, List<T>> attributeDimensions, {
    bool Function(Map<String, T> partialOrFullCombination)? validator,
  }) {
    final validDimensions = attributeDimensions.entries
        .where((e) => e.value.isNotEmpty)
        .toList();

    if (validDimensions.isEmpty) return const [];

    List<Map<String, T>> result = [{}];

    for (final entry in validDimensions) {
      final key = entry.key;
      final values = entry.value;
      final List<Map<String, T>> temp = [];

      for (final currentMap in result) {
        for (final val in values) {
          final candidate = Map<String, T>.from(currentMap)..[key] = val;
          if (validator == null || validator(candidate)) {
            temp.add(candidate);
          }
        }
      }
      result = temp;
    }

    return result;
  }
}
