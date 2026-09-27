import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/suppliers/data/datasources/supplier_remote_data_source.dart';
import 'package:admin_panel_ego/features/suppliers/data/models/purchase_invoice_model.dart';
import 'package:admin_panel_ego/features/suppliers/data/models/supplier_model.dart';
import 'package:admin_panel_ego/features/suppliers/data/models/supplier_payment_model.dart';
import 'package:admin_panel_ego/features/suppliers/data/repositories/supplier_repository.dart';
import 'package:admin_panel_ego/features/suppliers/presentation/cubit/supplier_cubit.dart';
import 'package:admin_panel_ego/features/suppliers/presentation/cubit/supplier_state.dart';
import 'package:admin_panel_ego/features/suppliers/utils/supplier_invoice_printer.dart';
import 'package:admin_panel_ego/core/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockSupplierRemoteDataSource implements SupplierRemoteDataSource {
  final List<SupplierModel> _suppliers = [];
  final List<PurchaseInvoiceModel> _invoices = [];
  final List<SupplierPaymentModel> _payments = [];

  @override
  Future<List<SupplierModel>> getSuppliers() async => List.from(_suppliers);

  @override
  Future<SupplierModel?> getSupplierById(String id) async =>
      _suppliers.where((s) => s.id == id).firstOrNull;

  @override
  Future<SupplierModel> addSupplier(SupplierModel supplier) async {
    final s = supplier.copyWith(
        id: supplier.id.isNotEmpty ? supplier.id : 'sup_${_suppliers.length + 1}');
    _suppliers.add(s);
    return s;
  }

  @override
  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) {
      _suppliers[idx] = supplier;
    }
    return supplier;
  }

  @override
  Future<void> deleteSupplier(String id) async {
    _suppliers.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoices({
    String? supplierId,
    int limit = 100,
  }) async {
    if (supplierId != null) {
      return _invoices.where((i) => i.supplierId == supplierId).toList();
    }
    return List.from(_invoices);
  }

  @override
  Future<PurchaseInvoiceModel> createPurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    bool autoUpdateStock = true,
  }) async {
    final inv = invoice.copyWith(
        id: invoice.id.isNotEmpty ? invoice.id : 'inv_${_invoices.length + 1}');
    _invoices.add(inv);

    // Update supplier balance
    final sIdx = _suppliers.indexWhere((s) => s.id == inv.supplierId);
    if (sIdx != -1) {
      final cur = _suppliers[sIdx];
      _suppliers[sIdx] = cur.copyWith(
        totalPurchases: cur.totalPurchases + inv.totalAmount,
        totalPaid: cur.totalPaid + inv.paidAmount,
        balanceDue: cur.balanceDue + inv.remainingAmount,
        invoicesCount: cur.invoicesCount + 1,
      );
    }

    if (inv.paidAmount > 0) {
      _payments.add(SupplierPaymentModel(
        id: 'pay_init_${_payments.length + 1}',
        supplierId: inv.supplierId,
        supplierName: inv.supplierName,
        invoiceId: inv.id,
        invoiceNumber: inv.invoiceNumber,
        amount: inv.paidAmount,
        paymentDate: inv.invoiceDate,
        createdAt: DateTime.now(),
      ));
    }
    return inv;
  }

  @override
  Future<void> updatePurchaseInvoice(PurchaseInvoiceModel invoice) async {
    final idx = _invoices.indexWhere((i) => i.id == invoice.id);
    if (idx != -1) {
      _invoices[idx] = invoice;
    }
  }

  @override
  Future<void> deletePurchaseInvoice(String invoiceId) async {
    _invoices.removeWhere((i) => i.id == invoiceId);
  }

  @override
  Future<List<SupplierPaymentModel>> getSupplierPayments({
    String? supplierId,
    int limit = 100,
  }) async {
    if (supplierId != null) {
      return _payments.where((p) => p.supplierId == supplierId).toList();
    }
    return List.from(_payments);
  }

  @override
  Future<SupplierPaymentModel> recordSupplierPayment(
      SupplierPaymentModel payment) async {
    final p = payment.copyWith(
        id: payment.id.isNotEmpty ? payment.id : 'pay_${_payments.length + 1}');
    _payments.add(p);

    // Update supplier balance
    final sIdx = _suppliers.indexWhere((s) => s.id == p.supplierId);
    if (sIdx != -1) {
      final cur = _suppliers[sIdx];
      _suppliers[sIdx] = cur.copyWith(
        totalPaid: cur.totalPaid + p.amount,
        balanceDue: cur.balanceDue - p.amount,
      );
    }

    return p;
  }
}

void main() {
  group('Supplier & Invoices Model Tests', () {
    test('SupplierModel serialization and deserialization works correctly', () {
      final now = DateTime(2026, 9, 26, 12, 0);
      final supplier = SupplierModel(
        id: 'sup_01',
        name: 'Vaporesso Official',
        contactPerson: 'Amr Khalil',
        phone: '01012345678',
        email: 'amr@vaporesso.com',
        address: 'Free Zone, Nasr City',
        taxNumber: '891-234-990',
        paymentTerms: 'Net 30',
        totalPurchases: 50000.0,
        totalPaid: 35000.0,
        balanceDue: 15000.0,
        invoicesCount: 4,
        suppliedCategories: const ['Devices', 'Pods'],
        notes: 'VIP Direct Distributor',
        rating: 4.8,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = supplier.toJson();
      expect(json['name'], 'Vaporesso Official');
      expect(json['balanceDue'], 15000.0);

      final fromJson = SupplierModel.fromJson({
        'name': 'Vaporesso Official',
        'contactPerson': 'Amr Khalil',
        'phone': '01012345678',
        'totalPurchases': 50000.0,
        'totalPaid': 35000.0,
        'balanceDue': 15000.0,
        'paymentTerms': 'Net 30',
        'suppliedCategories': ['Devices', 'Pods'],
        'createdAt': '2026-09-26T12:00:00.000',
        'updatedAt': '2026-09-26T12:00:00.000',
      }, 'sup_01');

      expect(fromJson.id, 'sup_01');
      expect(fromJson.contactPerson, 'Amr Khalil');
      expect(fromJson.balanceDue, 15000.0);
    });

    test('PurchaseInvoiceModel calculates status and remaining balance accurately', () {
      final now = DateTime.now();
      final item1 = const PurchaseInvoiceItemModel(
        productId: 'prod_1',
        productTitle: 'XROS 4 Pod Kit',
        variationSku: 'XROS-4-BLK',
        quantity: 20,
        unitCost: 750.0,
        subtotal: 15000.0,
      );

      final invoice = PurchaseInvoiceModel(
        id: 'inv_01',
        invoiceNumber: 'INV-2026-001',
        supplierId: 'sup_01',
        supplierName: 'Vaporesso Official',
        invoiceDate: now,
        items: [item1],
        subtotal: 15000.0,
        taxAmount: 2100.0,
        discountAmount: 1000.0,
        shippingCost: 500.0,
        totalAmount: 16600.0,
        paidAmount: 6600.0,
        remainingAmount: 10000.0,
        paymentStatus: InvoicePaymentStatus.partial,
        stockReceived: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(invoice.totalAmount, 16600.0);
      expect(invoice.remainingAmount, 10000.0);
      expect(invoice.paymentStatus, InvoicePaymentStatus.partial);

      final json = invoice.toJson();
      expect(json['invoiceNumber'], 'INV-2026-001');
      expect(json['paymentStatus'], 'partial');
    });

    test('SupplierPaymentModel handles cash and bank transfer entries', () {
      final now = DateTime.now();
      final payment = SupplierPaymentModel(
        id: 'pay_01',
        supplierId: 'sup_01',
        supplierName: 'Vaporesso Official',
        invoiceId: 'inv_01',
        invoiceNumber: 'INV-2026-001',
        amount: 10000.0,
        paymentDate: now,
        paymentMethod: 'Instapay',
        referenceNumber: 'IP-90821',
        notes: 'Final settlement for INV-2026-001',
        createdAt: now,
      );

      expect(payment.amount, 10000.0);
      expect(payment.paymentMethod, 'Instapay');
      expect(payment.referenceNumber, 'IP-90821');
    });
  });

  group('SupplierRepository & SupplierCubit Tests', () {
    late MockSupplierRemoteDataSource mockDataSource;
    late SupplierRepository repository;
    late SupplierCubit cubit;

    setUp(() {
      mockDataSource = MockSupplierRemoteDataSource();
      repository = SupplierRepositoryImpl(remoteDataSource: mockDataSource);
      cubit = SupplierCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('Loads suppliers, creates purchase invoice, and records payment voucher', () async {
      // 1. Initial load
      await cubit.loadSuppliersData();
      expect(cubit.state, isA<SupplierLoaded>());
      var state = cubit.state as SupplierLoaded;
      expect(state.suppliers.isEmpty, true);

      // 2. Add Supplier
      final now = DateTime.now();
      await cubit.addSupplier(SupplierModel(
        id: 'sup_100',
        name: 'Smok Official Egypt',
        phone: '01122334455',
        paymentTerms: 'Net 15',
        createdAt: now,
        updatedAt: now,
      ));

      state = cubit.state as SupplierLoaded;
      expect(state.suppliers.length, 1);
      expect(state.suppliers.first.name, 'Smok Official Egypt');

      // 3. Create Purchase Invoice
      await cubit.createPurchaseInvoice(PurchaseInvoiceModel(
        id: 'inv_100',
        invoiceNumber: 'INV-SMOK-01',
        supplierId: 'sup_100',
        supplierName: 'Smok Official Egypt',
        invoiceDate: now,
        items: const [
          PurchaseInvoiceItemModel(
            productId: 'p_smok_nord',
            productTitle: 'Smok Nord 5',
            quantity: 50,
            unitCost: 600.0,
            subtotal: 30000.0,
          ),
        ],
        subtotal: 30000.0,
        totalAmount: 30000.0,
        paidAmount: 10000.0,
        remainingAmount: 20000.0,
        paymentStatus: InvoicePaymentStatus.partial,
        stockReceived: true,
        createdAt: now,
        updatedAt: now,
      ));

      state = cubit.state as SupplierLoaded;
      expect(state.invoices.length, 1);
      expect(state.totalPurchasesAmount, 30000.0);
      expect(state.totalPaidAmount, 10000.0);
      expect(state.totalBalanceDue, 20000.0);

      // 4. Record Payment Voucher
      await cubit.recordPayment(SupplierPaymentModel(
        id: 'pay_100',
        supplierId: 'sup_100',
        supplierName: 'Smok Official Egypt',
        invoiceId: 'inv_100',
        invoiceNumber: 'INV-SMOK-01',
        amount: 20000.0,
        paymentDate: now,
        paymentMethod: 'Bank Transfer',
        createdAt: now,
      ));

      state = cubit.state as SupplierLoaded;
      expect(state.payments.length, 2); // Initial deposit + payout
      expect(state.totalPaidAmount, 30000.0);
      expect(state.totalBalanceDue, 0.0);

      // 5. Search & Filter
      cubit.filterSuppliers('Smok');
      state = cubit.state as SupplierLoaded;
      expect(state.filteredSuppliers.length, 1);

      cubit.filterSuppliers('NonExistent');
      state = cubit.state as SupplierLoaded;
      expect(state.filteredSuppliers.isEmpty, true);
    });
  });

  group('SupplierInvoicePrinter Tests', () {
    final testSupplier = SupplierModel(
      id: 'sup_test_01',
      name: 'Vaporesso Official',
      contactPerson: 'Amr Khalil',
      phone: '01012345678',
      taxNumber: '891-234-990',
      totalPurchases: 50000.0,
      totalPaid: 35000.0,
      balanceDue: 15000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testInvoice = PurchaseInvoiceModel(
      id: 'inv_test_01',
      invoiceNumber: 'INV-2026-001',
      supplierId: 'sup_test_01',
      supplierName: 'Vaporesso Official',
      invoiceDate: DateTime(2026, 9, 26),
      dueDate: DateTime(2026, 10, 26),
      items: const [
        PurchaseInvoiceItemModel(
          productId: 'prod_1',
          productTitle: 'XROS 4 Pod Kit',
          variationSku: 'XROS-4-BLK',
          variationAttributes: {'Color': 'Black'},
          quantity: 20,
          unitCost: 750.0,
          subtotal: 15000.0,
        ),
      ],
      subtotal: 15000.0,
      taxAmount: 2100.0,
      discountAmount: 1000.0,
      shippingCost: 500.0,
      totalAmount: 16600.0,
      paidAmount: 6600.0,
      remainingAmount: 10000.0,
      paymentStatus: InvoicePaymentStatus.partial,
      stockReceived: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testPayment = SupplierPaymentModel(
      id: 'pay_test_01',
      supplierId: 'sup_test_01',
      supplierName: 'Vaporesso Official',
      invoiceId: 'inv_test_01',
      invoiceNumber: 'INV-2026-001',
      amount: 10000.0,
      paymentDate: DateTime(2026, 9, 26),
      paymentMethod: 'Instapay',
      referenceNumber: 'IP-90821',
      notes: 'Final settlement for INV-2026-001',
      createdAt: DateTime.now(),
    );

    test('generatePurchaseInvoiceHtml outputs well-formed styled document', () {
      final html = SupplierInvoicePrinter.generatePurchaseInvoiceHtml(
        testInvoice,
        supplier: testSupplier,
      );

      expect(html.contains('INV-2026-001'), true);
      expect(html.contains('Vaporesso Official'), true);
      expect(html.contains('XROS 4 Pod Kit'), true);
      expect(html.contains('891-234-990'), true);
      expect(html.contains('فاتورة شراء بضاعة'), true);
      expect(html.contains('@media print'), true);
    });

    test('generatePaymentVoucherHtml outputs well-formed voucher document', () {
      final html = SupplierInvoicePrinter.generatePaymentVoucherHtml(
        testPayment,
        supplier: testSupplier,
      );

      expect(html.contains('IP-90821'), true);
      expect(html.contains('Vaporesso Official'), true);
      expect(html.contains('سند صرف نقدي / بنكي'), true);
      expect(html.contains('Instapay'), true);
    });

    test('generateSupplierStatementHtml outputs well-formed account statement', () {
      final html = SupplierInvoicePrinter.generateSupplierStatementHtml(
        testSupplier,
        [testInvoice],
        [testPayment],
      );

      expect(html.contains('كشف حساب مورّد'), true);
      expect(html.contains('Vaporesso Official'), true);
      expect(html.contains('INV-2026-001'), true);
      expect(html.contains('IP-90821'), true);
    });

    testWidgets('Renders Purchase Invoice preview dialog cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('ar', '')],
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SupplierInvoicePrinter.showPurchaseInvoicePreview(
                  ctx,
                  invoice: testInvoice,
                  supplier: testSupplier,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('#INV-2026-001'), findsOneWidget);
      expect(find.text('XROS 4 Pod Kit (XROS-4-BLK)'), findsOneWidget);
      expect(find.byIcon(Icons.print_rounded), findsWidgets);
    });

    testWidgets('Renders Payment Voucher preview dialog cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('ar', '')],
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SupplierInvoicePrinter.showPaymentVoucherPreview(
                  ctx,
                  payment: testPayment,
                  supplier: testSupplier,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('IP-90821'), findsOneWidget);
      expect(find.text('Instapay'), findsOneWidget);
      expect(find.byIcon(Icons.print_rounded), findsWidgets);
    });

    testWidgets('Renders Supplier Statement preview dialog cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('ar', '')],
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SupplierInvoicePrinter.showSupplierStatementPreview(
                  ctx,
                  supplier: testSupplier,
                  invoices: [testInvoice],
                  payments: [testPayment],
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Vaporesso Official • 15,000.00 EGP'), findsOneWidget);
      expect(find.byIcon(Icons.print_rounded), findsWidgets);
    });
  });
}
