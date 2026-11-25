import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/utils/pin_hasher.dart';
import 'package:admin_panel_ego/features/employees/data/models/employee_model.dart';
import 'package:admin_panel_ego/features/employees/data/models/payroll_slip_model.dart';
import 'package:admin_panel_ego/features/employees/data/models/salary_advance_model.dart';
import 'package:admin_panel_ego/features/employees/data/repositories/employees_repository.dart';
import 'package:admin_panel_ego/features/customers/data/models/customer_model.dart';
import 'package:admin_panel_ego/features/customers/data/repositories/customer_repository.dart';
import 'package:admin_panel_ego/features/pos/data/models/pos_cart_item_model.dart';
import 'package:admin_panel_ego/features/pos/data/models/pos_sale_model.dart';
import 'package:admin_panel_ego/features/pos/data/repositories/pos_repository.dart';
import 'package:admin_panel_ego/features/pos/presentation/cubit/pos_cubit.dart';
import 'package:admin_panel_ego/features/pos/presentation/cubit/pos_state.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';

class MockPosRepository implements PosRepository {
  List<ProductModel> products = [];
  PosSaleModel? lastSubmittedSale;

  @override
  Future<List<ProductModel>> getProducts() async => products;

  @override
  Stream<List<ProductModel>> getProductsStream() => Stream.value(products);

  @override
  Future<PosSaleModel> submitPosSale(PosSaleModel sale) async {
    lastSubmittedSale = sale;
    return sale.copyWith(id: 'sale-test-id');
  }
}

class MockEmployeesRepository implements EmployeesRepository {
  List<EmployeeModel> staffList = [];

  @override
  Future<List<EmployeeModel>> getEmployees() async => staffList;

  @override
  Stream<List<EmployeeModel>> watchEmployees() => Stream.value(staffList);

  @override
  Future<EmployeeModel?> findEmployeeByPin(String pin) async {
    for (final emp in staffList) {
      if (emp.verifyPin(pin)) return emp;
    }
    return null;
  }

  @override
  Future<void> addEmployee(EmployeeModel employee) async {}
  @override
  Future<void> updateEmployee(EmployeeModel employee) async {}
  @override
  Future<void> deleteEmployee(String id) async {}

  @override
  Stream<List<SalaryAdvanceModel>> watchAdvances({String? monthPeriod, String? employeeId}) => Stream.value([]);
  @override
  Future<List<SalaryAdvanceModel>> getAdvances({String? monthPeriod, String? employeeId}) async => [];
  @override
  Future<void> disburseSalaryAdvance(SalaryAdvanceModel advance) async {}
  @override
  Future<void> deleteAdvance(String id) async {}

  @override
  Stream<List<PayrollSlipModel>> watchPayrollSlips({String? monthPeriod, String? employeeId}) => Stream.value([]);
  @override
  Future<List<PayrollSlipModel>> getPayrollSlips({String? monthPeriod, String? employeeId}) async => [];
  @override
  Future<void> disbursePayroll({required PayrollSlipModel slip, required List<SalaryAdvanceModel> advancesToDeduct, bool recordToExpenses = true}) async {}
  @override
  Future<void> deletePayrollSlip(PayrollSlipModel slip) async {}

  @override
  Stream<Map<String, double>> watchMonthlySales(String monthPeriod) => Stream.value({});
  @override
  Stream<Map<String, int>> watchMonthlyOrdersCount(String monthPeriod) => Stream.value({});
  @override
  Future<Map<String, double>> getMonthlySales(String monthPeriod) async => {};
}

class MockCustomerRepository implements CustomerRepository {
  @override
  Future<CustomerModel?> findCustomerByPhone(String phone) async => null;
  @override
  Future<List<CustomerModel>> getCustomers() async => [];
  @override
  Stream<List<CustomerModel>> getCustomersStream() => Stream.value([]);
  @override
  Future<void> updateCustomerPoints({required String customerId, required int pointsDelta, String? reason}) async {}
  @override
  Stream<CustomerModel?> watchCustomer(CustomerModel initialCustomer) => Stream.value(initialCustomer);
}

class TestPosCubit extends PosCubit {
  TestPosCubit({
    super.repository,
    super.customerRepository,
    super.employeesRepository,
  });

  void emitState(PosState newState) => emit(newState);
}

void main() {
  group('PinHasher Tests', () {
    test('hashes 4-digit PIN into 64-character SHA-256 string', () {
      final hashed = PinHasher.hashPin('1234');
      expect(hashed.length, 64);
      expect(PinHasher.isHashed(hashed), isTrue);
      expect(PinHasher.isHashed('1234'), isFalse);
    });

    test('verifies matching PIN against hashed PIN', () {
      final hashed = PinHasher.hashPin('5678');
      expect(PinHasher.verifyPin(candidatePin: '5678', storedHashOrPlain: hashed), isTrue);
      expect(PinHasher.verifyPin(candidatePin: '0000', storedHashOrPlain: hashed), isFalse);
    });

    test('verifies legacy plain PIN for backward compatibility', () {
      expect(PinHasher.verifyPin(candidatePin: '4321', storedHashOrPlain: '4321'), isTrue);
      expect(PinHasher.verifyPin(candidatePin: '1111', storedHashOrPlain: '4321'), isFalse);
    });
  });

  group('EmployeeModel & PIN Attribution Tests', () {
    test('EmployeeModel verifies hashed pin and serializes commissionRate', () {
      final hashedPin = PinHasher.hashPin('9876');
      final emp = EmployeeModel(
        id: 'emp-peter',
        name: 'Peter Staff',
        phone: '01012345678',
        role: 'staff',
        jobTitle: 'Sales Specialist',
        pinCode: hashedPin,
        commissionRate: 3.5,
        baseSalary: 6000,
        hireDate: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1),
      );

      expect(emp.verifyPin('9876'), isTrue);
      expect(emp.verifyPin('1234'), isFalse);

      final json = emp.toJson();
      expect(json['commissionRate'], 3.5);
      expect(json['pinCode'], hashedPin);

      final reconstructed = EmployeeModel.fromJson(json);
      expect(reconstructed.commissionRate, 3.5);
      expect(reconstructed.verifyPin('9876'), isTrue);
    });
  });

  group('PosSaleModel Sales Attribution Tests', () {
    test('preserves salesPersonId, salesPersonName, and commissionRate in toJson and fromJson', () {
      final sale = PosSaleModel(
        id: 'sale-123',
        orderNumber: 'POS-001',
        createdAt: DateTime(2026, 11, 23, 10, 0),
        cashierId: 'cashier-1',
        cashierName: 'Store Cashier',
        salesPersonId: 'emp-peter',
        salesPersonName: 'Peter Sales',
        commissionRate: 3.5,
        items: const [
          PosCartItemModel(
            productId: 'prod-1',
            title: 'EGO Device',
            unitPrice: 500.0,
            quantity: 2,
          ),
        ],
        subTotal: 1000.0,
        totalAmount: 1000.0,
      );

      final json = sale.toJson();
      expect(json['salesPersonId'], 'emp-peter');
      expect(json['salesPersonName'], 'Peter Sales');
      expect(json['commissionRate'], 3.5);

      final fromJson = PosSaleModel.fromJson(json);
      expect(fromJson.salesPersonId, 'emp-peter');
      expect(fromJson.salesPersonName, 'Peter Sales');
      expect(fromJson.commissionRate, 3.5);
    });

    test('toJson defaults salesPersonId and salesPersonName to cashier if empty', () {
      final sale = PosSaleModel(
        id: 'sale-456',
        orderNumber: 'POS-002',
        createdAt: DateTime(2026, 11, 23, 10, 0),
        cashierId: 'cashier-main',
        cashierName: 'Main Cashier',
        salesPersonId: '',
        salesPersonName: '',
        commissionRate: 0.0,
        items: const [],
        subTotal: 0.0,
        totalAmount: 0.0,
      );

      final json = sale.toJson();
      expect(json['salesPersonId'], 'cashier-main');
      expect(json['salesPersonName'], 'Main Cashier');
    });
  });

  group('PosCubit Quick PIN Switching & Attribution Tests', () {
    late MockPosRepository mockPosRepo;
    late MockCustomerRepository mockCustomerRepo;
    late MockEmployeesRepository mockEmployeesRepo;
    late TestPosCubit cubit;

    final peter = EmployeeModel(
      id: 'emp-peter',
      name: 'Peter Sales',
      phone: '01000000001',
      role: 'staff',
      jobTitle: 'Sales Agent',
      pinCode: PinHasher.hashPin('2468'),
      commissionRate: 4.0,
      baseSalary: 5000,
      hireDate: DateTime(2025, 1, 1),
      createdAt: DateTime(2025, 1, 1),
    );

    setUp(() {
      mockPosRepo = MockPosRepository();
      mockCustomerRepo = MockCustomerRepository();
      mockEmployeesRepo = MockEmployeesRepository();
      mockEmployeesRepo.staffList = [peter];

      cubit = TestPosCubit(
        repository: mockPosRepo,
        customerRepository: mockCustomerRepo,
        employeesRepository: mockEmployeesRepo,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has null activeSalesPerson', () {
      expect(cubit.state.activeSalesPerson, isNull);
    });

    test('switchSalesPersonWithPin activates salesperson when PIN is correct', () async {
      final result = await cubit.switchSalesPersonWithPin(
        staff: peter,
        pin: '2468',
      );

      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(cubit.state.activeSalesPerson, equals(peter));
      expect(cubit.state.activeSalesPerson?.commissionRate, 4.0);
    });

    test('switchSalesPersonWithPin rejects incorrect PIN and locks out after 5 failures', () async {
      // 1 to 4 failed attempts
      for (int i = 1; i <= 4; i++) {
        final res = await cubit.switchSalesPersonWithPin(staff: peter, pin: '0000');
        expect(res.success, isFalse);
        expect(res.error, contains('المتبقي ${5 - i} محاولات'));
        expect(cubit.state.activeSalesPerson, isNull);
      }

      // 5th failed attempt triggers 5-minute lockout
      final fifthRes = await cubit.switchSalesPersonWithPin(staff: peter, pin: '0000');
      expect(fifthRes.success, isFalse);
      expect(fifthRes.error, contains('تم إيقاف المحاولات'));
      expect(cubit.isStaffLockedOut(peter.id), isTrue);

      // 6th attempt while locked out is immediately rejected
      final sixthRes = await cubit.switchSalesPersonWithPin(staff: peter, pin: '2468');
      expect(sixthRes.success, isFalse);
      expect(sixthRes.error, contains('تم حظر المحاولات مؤقتاً'));
      expect(cubit.state.activeSalesPerson, isNull);
    });

    test('completeSale writes sales attribution snapshot of activeSalesPerson', () async {
      // 1. Switch active salesperson
      await cubit.switchSalesPersonWithPin(staff: peter, pin: '2468');
      expect(cubit.state.activeSalesPerson, equals(peter));

      // 2. Set cart items in state
      cubit.emitState(cubit.state.copyWith(
        cartItems: const [
          PosCartItemModel(
            productId: 'item-1',
            title: 'Vape Pod',
            unitPrice: 200.0,
            availableStock: 10,
            quantity: 1,
          ),
        ],
      ));

      // 3. Complete sale
      final completed = await cubit.completeSale(
        cashierId: 'cashier-station-1',
        cashierName: 'Admin Register',
        autoPrint: false,
      );

      expect(completed, isTrue);
      final captured = mockPosRepo.lastSubmittedSale;
      expect(captured, isNotNull);
      expect(captured!.salesPersonId, 'emp-peter');
      expect(captured.salesPersonName, 'Peter Sales');
      expect(captured.commissionRate, 4.0);
      expect(captured.cashierId, 'cashier-station-1');
      expect(captured.cashierName, 'Admin Register');
    });

    test('completeSale falls back to cashier metadata when no salesperson is active', () async {
      cubit.clearActiveSalesPerson();

      cubit.emitState(cubit.state.copyWith(
        cartItems: const [
          PosCartItemModel(
            productId: 'item-2',
            title: 'E-Liquid 60ml',
            unitPrice: 350.0,
            availableStock: 5,
            quantity: 1,
          ),
        ],
      ));

      final completed = await cubit.completeSale(
        cashierId: 'cashier-station-1',
        cashierName: 'Admin Register',
        autoPrint: false,
      );

      expect(completed, isTrue);
      final captured = mockPosRepo.lastSubmittedSale;
      expect(captured, isNotNull);
      expect(captured!.salesPersonId, 'cashier-station-1');
      expect(captured.salesPersonName, 'Admin Register');
      // Takes the store-wide default commission rate from settings (2.5%)
      expect(captured.commissionRate, 2.5);
    });
  });
}
