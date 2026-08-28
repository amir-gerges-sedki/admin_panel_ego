import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Central Firebase Service handling initialization and Cloud Firestore references
class FirebaseService {
  static bool isInitialized = false;
  static bool isLiveFirebase = false;

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Safe initialization that works in all environments
  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isInitialized = true;
      isLiveFirebase = true;
      debugPrint('🔥 Firebase successfully initialized for EGO Admin Panel');
    } catch (e) {
      debugPrint('⚠️ Firebase Core init note: $e');
      isInitialized = true;
    }
  }

  /// Helper to get docs from multiple possible collection names (e.g. ['Lines', 'Brands'], ['Products', 'products'])
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getMultipleCollectionsDocs(
    List<String> collectionNames,
  ) async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = [];
    final Set<String> seenIds = {};

    for (final name in collectionNames) {
      try {
        final snapshot = await firestore.collection(name).get();
        for (final doc in snapshot.docs) {
          if (!seenIds.contains(doc.id)) {
            seenIds.add(doc.id);
            allDocs.add(doc);
          }
        }
      } catch (e) {
        debugPrint('Firestore fetch note for $name: $e');
      }
    }

    return allDocs;
  }

  /// Helper to get docs supporting both PascalCase and lowercase collection names
  static Future<QuerySnapshot<Map<String, dynamic>>> getDocsSafely(
    String primaryName, {
    String? secondaryName,
    String? orderByField,
    bool descending = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firestore.collection(primaryName);
      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }
      var snapshot = await query.get();
      if (snapshot.docs.isEmpty && secondaryName != null) {
        Query<Map<String, dynamic>> query2 = firestore.collection(secondaryName);
        if (orderByField != null) {
          query2 = query2.orderBy(orderByField, descending: descending);
        }
        snapshot = await query2.get();
      }
      return snapshot;
    } catch (e) {
      try {
        var snap = await firestore.collection(primaryName).get();
        if (snap.docs.isEmpty && secondaryName != null) {
          snap = await firestore.collection(secondaryName).get();
        }
        return snap;
      } catch (err) {
        debugPrint('Firestore fetch error for $primaryName: $err');
        rethrow;
      }
    }
  }

  /// Cloud Firestore Collections definitions strictly from FIREBASE_STRUCTURE.md
  static CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('Users');

  static CollectionReference<Map<String, dynamic>> get productsCollection =>
      firestore.collection('Products');

  static CollectionReference<Map<String, dynamic>> get linesCollection =>
      firestore.collection('Lines');

  static CollectionReference<Map<String, dynamic>> get categoriesCollection =>
      firestore.collection('Categories');

  static CollectionReference<Map<String, dynamic>> get brandsCollection =>
      firestore.collection('Brands');

  static CollectionReference<Map<String, dynamic>> get bannersCollection =>
      firestore.collection('Banners');

  static CollectionReference<Map<String, dynamic>> get ordersCollection =>
      firestore.collection('Orders');

  /// User notifications subcollection reference: Users/{userId}/Notifications
  static CollectionReference<Map<String, dynamic>> userNotificationsCollection(String userId) =>
      usersCollection.doc(userId).collection('Notifications');

  static CollectionReference<Map<String, dynamic>> get couponsCollection =>
      firestore.collection('Coupons');

  static DocumentReference<Map<String, dynamic>> get contactInfoDoc =>
      firestore.collection('ContactInfo').doc('support');
}
