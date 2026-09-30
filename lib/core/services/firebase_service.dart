import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Central Firebase Service providing standardized Cloud Firestore references
/// and configuration for the EGO Store ecosystem.
class FirebaseService {
  static bool isInitialized = false;
  static bool isLiveFirebase = false;

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Safe initialization that works across all environments
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

  // ─── Standardized Firestore Collections ───

  /// 1. Users / Customers
  static CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('Users');

  /// 2. Catalog & Products
  static CollectionReference<Map<String, dynamic>> get productsCollection =>
      firestore.collection('Products');

  /// 3. Brands
  static CollectionReference<Map<String, dynamic>> get brandsCollection =>
      firestore.collection('Brands');

  /// 4. Categories
  static CollectionReference<Map<String, dynamic>> get categoriesCollection =>
      firestore.collection('Categories');

  /// 5. Banners (Hero / Promos)
  static CollectionReference<Map<String, dynamic>> get bannersCollection =>
      firestore.collection('Banners');

  /// 6. Badges (Product / Highlight Badges)
  static CollectionReference<Map<String, dynamic>> get badgesCollection =>
      firestore.collection('Badges');

  /// 7. Orders
  static CollectionReference<Map<String, dynamic>> get ordersCollection =>
      firestore.collection('Orders');

  /// 8. Coupons
  static CollectionReference<Map<String, dynamic>> get couponsCollection =>
      firestore.collection('Coupons');

  /// 9. Admin Broadcasts (Push Notifications & Live Cloud Triggers)
  static CollectionReference<Map<String, dynamic>> get adminBroadcastsCollection =>
      firestore.collection('AdminBroadcasts');

  /// 10. Store Settings & RBAC Roles
  static CollectionReference<Map<String, dynamic>> get settingsCollection =>
      firestore.collection('Settings');

  static DocumentReference<Map<String, dynamic>> get settingsDoc =>
      settingsCollection.doc('store_settings');

  static DocumentReference<Map<String, dynamic>> get rolesDoc =>
      settingsCollection.doc('roles_permissions');

  static DocumentReference<Map<String, dynamic>> get passcodesDoc =>
      settingsCollection.doc('security_passcodes');

  // ─── ERP / Operations Collections ───

  /// 11. Suppliers & Vendors
  static CollectionReference<Map<String, dynamic>> get suppliersCollection =>
      firestore.collection('suppliers');

  /// 12. Purchase Invoices
  static CollectionReference<Map<String, dynamic>> get purchaseInvoicesCollection =>
      firestore.collection('purchase_invoices');

  /// 13. Supplier Payment Vouchers
  static CollectionReference<Map<String, dynamic>> get supplierPaymentsCollection =>
      firestore.collection('supplier_payments');

  /// 14. Stock Movements (Audit Trail)
  static CollectionReference<Map<String, dynamic>> get stockMovementsCollection =>
      firestore.collection('stock_movements');

  /// 15. Operational Expenses (OpEx)
  static CollectionReference<Map<String, dynamic>> get expensesCollection =>
      firestore.collection('expenses');

  /// 16. Damaged Stock (Waste / Write-offs)
  static CollectionReference<Map<String, dynamic>> get damagedStockCollection =>
      firestore.collection('damaged_stock');

  /// 17. Employees / Staff Directory
  static CollectionReference<Map<String, dynamic>> get employeesCollection =>
      firestore.collection('employees');

  /// 18. Salary Advances Ledger
  static CollectionReference<Map<String, dynamic>> get salaryAdvancesCollection =>
      firestore.collection('salary_advances');

  /// 19. Payroll Slips History
  static CollectionReference<Map<String, dynamic>> get payrollHistoryCollection =>
      firestore.collection('payroll_history');

  /// 20. POS Cashier Sales
  static CollectionReference<Map<String, dynamic>> get posSalesCollection =>
      firestore.collection('pos_sales');

  // ─── User Subcollection Helpers ───

  static CollectionReference<Map<String, dynamic>> userNotificationsCollection(String userId) =>
      usersCollection.doc(userId).collection('Notifications');

  static CollectionReference<Map<String, dynamic>> userAddressesCollection(String userId) =>
      usersCollection.doc(userId).collection('Addresses');

  static CollectionReference<Map<String, dynamic>> userFavoritesCollection(String userId) =>
      usersCollection.doc(userId).collection('Favorites');

  static CollectionReference<Map<String, dynamic>> userCartCollection(String userId) =>
      usersCollection.doc(userId).collection('Cart');
}
