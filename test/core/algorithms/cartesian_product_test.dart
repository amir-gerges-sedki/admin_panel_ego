import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/algorithms/cartesian_product.dart';

void main() {
  group('CartesianProduct Algorithm Tests', () {
    test('compute handles empty dimensions gracefully', () {
      expect(CartesianProduct.compute<String>([]), isEmpty);
      expect(
        CartesianProduct.compute<String>([
          ['A', 'B'],
          [],
        ]),
        isEmpty,
      );
    });

    test('compute produces exact N-ary product', () {
      final input = [
        ['A', 'B'],
        ['1', '2'],
        ['X'],
      ];
      final result = CartesianProduct.compute<String>(input);

      expect(result.length, equals(4));
      expect(result, equals([
        ['A', '1', 'X'],
        ['A', '2', 'X'],
        ['B', '1', 'X'],
        ['B', '2', 'X'],
      ]));
    });

    test('computeNamed produces named maps and supports early pruning predicates', () {
      final dimensions = {
        'Style': ['MTL', 'DL'],
        'Nicotine': ['3mg', '6mg', '20mg', '50mg'],
      };

      // Validator rule: DL only allows 3mg and 6mg; MTL allows 20mg and 50mg
      final result = CartesianProduct.computeNamed<String>(
        dimensions,
        validator: (candidate) {
          if (candidate.containsKey('Nicotine')) {
            if (candidate['Style'] == 'DL') {
              return candidate['Nicotine'] == '3mg' || candidate['Nicotine'] == '6mg';
            }
            if (candidate['Style'] == 'MTL') {
              return candidate['Nicotine'] == '20mg' || candidate['Nicotine'] == '50mg';
            }
          }
          return true;
        },
      );


      expect(result.length, equals(4));
      expect(
        result.any((m) => m['Style'] == 'DL' && m['Nicotine'] == '3mg'),
        isTrue,
      );
      expect(
        result.any((m) => m['Style'] == 'DL' && m['Nicotine'] == '6mg'),
        isTrue,
      );
      expect(
        result.any((m) => m['Style'] == 'DL' && m['Nicotine'] == '50mg'),
        isFalse,
      );
      expect(
        result.any((m) => m['Style'] == 'MTL' && m['Nicotine'] == '20mg'),
        isTrue,
      );
      expect(
        result.any((m) => m['Style'] == 'MTL' && m['Nicotine'] == '50mg'),
        isTrue,
      );
    });
  });
}
