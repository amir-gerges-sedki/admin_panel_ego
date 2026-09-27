import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../domain/models/admin_role.dart';

abstract class RolesRemoteDataSource {
  Future<RolePermissionsModel> getPermissionsConfig();
  Stream<RolePermissionsModel> watchPermissionsConfig();
  Future<void> savePermissionsConfig(RolePermissionsModel config);

  Future<SecurityPasscodesModel> getSecurityPasscodes();
  Stream<SecurityPasscodesModel> watchSecurityPasscodes();
  Future<void> saveSecurityPasscodes(SecurityPasscodesModel passcodes);

  Future<void> updateUserRole(String userId, AdminRole role);
}

class RolesRemoteDataSourceImpl implements RolesRemoteDataSource {
  final FirebaseFirestore _firestore;

  RolesRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  DocumentReference<Map<String, dynamic>> get _configDoc =>
      _firestore.collection('Settings').doc('roles_permissions');

  DocumentReference<Map<String, dynamic>> get _passcodesDoc =>
      _firestore.collection('Settings').doc('security_passcodes');

  @override
  Future<RolePermissionsModel> getPermissionsConfig() async {
    try {
      final doc = await _configDoc.get();
      if (!doc.exists || doc.data() == null) {
        return RolePermissionsModel.defaultPermissions();
      }
      return RolePermissionsModel.fromJson(doc.data());
    } catch (e) {
      debugPrint('Error getting roles permissions config: $e');
      return RolePermissionsModel.defaultPermissions();
    }
  }

  @override
  Stream<RolePermissionsModel> watchPermissionsConfig() {
    return _configDoc.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return RolePermissionsModel.defaultPermissions();
      }
      return RolePermissionsModel.fromJson(doc.data());
    });
  }

  @override
  Future<void> savePermissionsConfig(RolePermissionsModel config) async {
    try {
      await _configDoc.set(config.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving roles permissions config: $e');
      rethrow;
    }
  }

  @override
  Future<SecurityPasscodesModel> getSecurityPasscodes() async {
    try {
      final doc = await _passcodesDoc.get();
      if (!doc.exists || doc.data() == null) {
        return SecurityPasscodesModel.defaults();
      }
      return SecurityPasscodesModel.fromJson(doc.data());
    } catch (e) {
      debugPrint('Error getting security passcodes: $e');
      return SecurityPasscodesModel.defaults();
    }
  }

  @override
  Stream<SecurityPasscodesModel> watchSecurityPasscodes() {
    return _passcodesDoc.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return SecurityPasscodesModel.defaults();
      }
      return SecurityPasscodesModel.fromJson(doc.data());
    });
  }

  @override
  Future<void> saveSecurityPasscodes(SecurityPasscodesModel passcodes) async {
    try {
      await _passcodesDoc.set(passcodes.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving security passcodes: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserRole(String userId, AdminRole role) async {
    try {
      await _firestore.collection('Users').doc(userId).set({
        'role': role.id,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }
}
