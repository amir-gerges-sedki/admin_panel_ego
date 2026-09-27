import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/algorithms/search_indexer.dart';

class SampleItem {
  final String id;
  final String title;
  final String tag;

  SampleItem(this.id, this.title, this.tag);
}

void main() {
  group('SearchIndexer Inverted Index Tests', () {
    test('Tokenizes text correctly by stripping punctuation and lowercasing', () {
      final tokens = SearchIndexer.tokenize('Vaporesso XROS 3 Pod - 0.6ohm (Red/Black)');
      expect(tokens, contains('vaporesso'));
      expect(tokens, contains('xros'));
      expect(tokens, contains('3'));
      expect(tokens, contains('pod'));
      expect(tokens, contains('0'));
      expect(tokens, contains('6ohm'));
      expect(tokens, contains('red'));
      expect(tokens, contains('black'));
    });

    test('Indexes and finds items via single and multi-keyword intersection', () {
      final items = [
        SampleItem('1', 'Vaporesso XROS 3 Kit', 'Pod System'),
        SampleItem('2', 'Oxva Xlim Pro Kit', 'Pod System'),
        SampleItem('3', 'VGOD Cubano 60ml', 'E-Liquid DL'),
        SampleItem('4', 'Nasty Salt Cush Man 30ml', 'Salt Nic MTL'),
      ];

      final indexer = SearchIndexer<SampleItem>(
        tokenExtractor: (item) => [item.id, item.title, item.tag],
        initialItems: items,
      );

      // Search empty returns all
      expect(indexer.search('').length, equals(4));

      // Single token search
      final xrosResults = indexer.search('xros');
      expect(xrosResults.length, equals(1));
      expect(xrosResults.first.id, equals('1'));

      // Tag search
      final podResults = indexer.search('Pod');
      expect(podResults.length, equals(2));

      // Multi-keyword intersection
      final vgodDlResults = indexer.search('vgod dl');
      expect(vgodDlResults.length, equals(1));
      expect(vgodDlResults.first.id, equals('3'));

      // No match
      final noMatches = indexer.search('Smok Nord');
      expect(noMatches, isEmpty);
    });

    test('Dynamic item indexing and indexAll re-indexing', () {
      final indexer = SearchIndexer<SampleItem>(
        tokenExtractor: (item) => [item.id, item.title, item.tag],
      );

      expect(indexer.allItems, isEmpty);
      indexer.indexItem(SampleItem('1', 'Geekvape Aegis', 'Mod'));
      expect(indexer.search('geekvape').length, equals(1));

      indexer.clear();
      expect(indexer.search('geekvape'), isEmpty);
    });
  });
}
