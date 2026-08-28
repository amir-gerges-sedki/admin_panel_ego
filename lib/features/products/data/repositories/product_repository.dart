import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
}

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final docs = await FirebaseService.getMultipleCollectionsDocs([
        'Products',
        'products',
        'Items',
        'items',
      ]);
      return docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Firestore Products fetch note: $e');
      return [];
    }
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final json = product.toJson(forFirestore: true);
    try {
      // Write exclusively to canonical 'Products' collection
      await FirebaseService.firestore
          .collection('Products')
          .doc(product.id)
          .set(json, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore addProduct error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final json = product.toJson(forFirestore: true);
    try {
      // Update exclusively in canonical 'Products' collection
      await FirebaseService.firestore
          .collection('Products')
          .doc(product.id)
          .set(json, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updateProduct error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await FirebaseService.firestore
          .collection('Products')
          .doc(productId)
          .delete();
    } catch (e) {
      debugPrint('Firestore deleteProduct error: $e');
      rethrow;
    }
  }
}
