import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/customer_model.dart';

abstract class CustomerRepository {
  Future<List<CustomerModel>> getCustomers();
}

class CustomerRepositoryImpl implements CustomerRepository {
  @override
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final snapshot = await FirebaseService.getDocsSafely('Users', secondaryName: 'users');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CustomerModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Firestore Users fetch note: $e');
      return [];
    }
  }
}
