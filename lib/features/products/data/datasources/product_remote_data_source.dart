import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<void> saveProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProductRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

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
  Future<void> saveProduct(ProductModel product) async {
    final json = product.toJson();
    await _firestore.collection('Products').doc(product.id).set(json);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('Products').doc(productId).delete();
  }
}
