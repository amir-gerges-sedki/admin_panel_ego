import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/pin_hasher.dart';
import '../models/employee_model.dart';
import '../models/payroll_slip_model.dart';
import '../models/salary_advance_model.dart';

abstract class EmployeesRemoteDataSource {
  // Employees
  Stream<List<EmployeeModel>> watchEmployees();
  Future<List<EmployeeModel>> getEmployees();
  Future<EmployeeModel?> findEmployeeByPin(String pin);
  Future<void> addEmployee(EmployeeModel employee);
  Future<void> updateEmployee(EmployeeModel employee);
  Future<void> deleteEmployee(String id);

  // Salary Advances
  Stream<List<SalaryAdvanceModel>> watchAdvances({String? monthPeriod, String? employeeId});
  Future<List<SalaryAdvanceModel>> getAdvances({String? monthPeriod, String? employeeId});
  Future<void> addAdvance(SalaryAdvanceModel advance);
  Future<void> updateAdvance(SalaryAdvanceModel advance);
  Future<void> deleteAdvance(String id);

  // Payroll Slips
  Stream<List<PayrollSlipModel>> watchPayrollSlips({String? monthPeriod, String? employeeId});
  Future<List<PayrollSlipModel>> getPayrollSlips({String? monthPeriod, String? employeeId});
  Future<void> addPayrollSlip(PayrollSlipModel slip);
  Future<void> deletePayrollSlip(String id);

  // Staff Monthly Sales & Orders
  Stream<Map<String, double>> watchMonthlySales(String monthPeriod);
  Stream<Map<String, int>> watchMonthlyOrdersCount(String monthPeriod);
  Future<Map<String, double>> getMonthlySales(String monthPeriod);
}

class EmployeesRemoteDataSourceImpl implements EmployeesRemoteDataSource {
  final FirebaseFirestore _firestore;

  EmployeesRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  CollectionReference<Map<String, dynamic>> get _empCollection =>
      _firestore.collection('employees');
  CollectionReference<Map<String, dynamic>> get _advCollection =>
      _firestore.collection('salary_advances');
  CollectionReference<Map<String, dynamic>> get _payrollCollection =>
      _firestore.collection('payroll_slips');
  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      FirebaseService.ordersCollection;

  // --- Employees ---

  @override
  Stream<List<EmployeeModel>> watchEmployees() {
    return _empCollection
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => EmployeeModel.fromJson(d.data(), d.id)).toList())
        .handleError((e) {
      debugPrint('Firestore watchEmployees error: $e');
      return <EmployeeModel>[];
    });
  }

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final snap = await _empCollection.orderBy('name').get();
      return snap.docs.map((d) => EmployeeModel.fromJson(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('Firestore getEmployees error: $e');
      return [];
    }
  }

  @override
  Future<EmployeeModel?> findEmployeeByPin(String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin.isEmpty) return null;
    try {
      final hashedPin = PinHasher.hashPin(cleanPin);

      // 1. Check against hashed PIN in Firestore
      var snap = await _empCollection
          .where('pinCode', isEqualTo: hashedPin)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first;
        return EmployeeModel.fromJson(d.data(), d.id);
      }

      // 2. Fallback check for legacy unhashed PIN in Firestore
      snap = await _empCollection
          .where('pinCode', isEqualTo: cleanPin)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first;
        return EmployeeModel.fromJson(d.data(), d.id);
      }
    } catch (e) {
      debugPrint('Firestore findEmployeeByPin error: $e');
    }
    return null;
  }

  @override
  Future<void> addEmployee(EmployeeModel employee) async {
    final docRef = employee.id.isNotEmpty ? _empCollection.doc(employee.id) : _empCollection.doc();
    final data = employee.copyWith(id: docRef.id).toJson();
    await docRef.set(data);
  }

  @override
  Future<void> updateEmployee(EmployeeModel employee) async {
    await _empCollection.doc(employee.id).set(employee.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _empCollection.doc(id).delete();
  }

  // --- Salary Advances ---

  @override
  Stream<List<SalaryAdvanceModel>> watchAdvances({String? monthPeriod, String? employeeId}) {
    Query<Map<String, dynamic>> query = _advCollection.orderBy('date', descending: true);
    if (monthPeriod != null && monthPeriod.isNotEmpty) {
      query = query.where('monthPeriod', isEqualTo: monthPeriod);
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }

    return query.snapshots().map((snap) {
      return snap.docs.map((d) => SalaryAdvanceModel.fromJson(d.data(), d.id)).toList();
    }).handleError((e) {
      debugPrint('Firestore watchAdvances error: $e');
      return <SalaryAdvanceModel>[];
    });
  }

  @override
  Future<List<SalaryAdvanceModel>> getAdvances({String? monthPeriod, String? employeeId}) async {
    try {
      Query<Map<String, dynamic>> query = _advCollection.orderBy('date', descending: true);
      if (monthPeriod != null && monthPeriod.isNotEmpty) {
        query = query.where('monthPeriod', isEqualTo: monthPeriod);
      }
      if (employeeId != null && employeeId.isNotEmpty) {
        query = query.where('employeeId', isEqualTo: employeeId);
      }
      final snap = await query.get();
      return snap.docs.map((d) => SalaryAdvanceModel.fromJson(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('Firestore getAdvances error: $e');
      return [];
    }
  }

  @override
  Future<void> addAdvance(SalaryAdvanceModel advance) async {
    final docRef = advance.id.isNotEmpty ? _advCollection.doc(advance.id) : _advCollection.doc();
    final data = advance.copyWith(id: docRef.id).toJson();
    await docRef.set(data);
  }

  @override
  Future<void> updateAdvance(SalaryAdvanceModel advance) async {
    await _advCollection.doc(advance.id).set(advance.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteAdvance(String id) async {
    await _advCollection.doc(id).delete();
  }

  // --- Payroll Slips ---

  @override
  Stream<List<PayrollSlipModel>> watchPayrollSlips({String? monthPeriod, String? employeeId}) {
    Query<Map<String, dynamic>> query = _payrollCollection.orderBy('paymentDate', descending: true);
    if (monthPeriod != null && monthPeriod.isNotEmpty) {
      query = query.where('monthPeriod', isEqualTo: monthPeriod);
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }

    return query.snapshots().map((snap) {
      return snap.docs.map((d) => PayrollSlipModel.fromJson(d.data(), d.id)).toList();
    }).handleError((e) {
      debugPrint('Firestore watchPayrollSlips error: $e');
      return <PayrollSlipModel>[];
    });
  }

  @override
  Future<List<PayrollSlipModel>> getPayrollSlips({String? monthPeriod, String? employeeId}) async {
    try {
      Query<Map<String, dynamic>> query = _payrollCollection.orderBy('paymentDate', descending: true);
      if (monthPeriod != null && monthPeriod.isNotEmpty) {
        query = query.where('monthPeriod', isEqualTo: monthPeriod);
      }
      if (employeeId != null && employeeId.isNotEmpty) {
        query = query.where('employeeId', isEqualTo: employeeId);
      }
      final snap = await query.get();
      return snap.docs.map((d) => PayrollSlipModel.fromJson(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('Firestore getPayrollSlips error: $e');
      return [];
    }
  }

  @override
  Future<void> addPayrollSlip(PayrollSlipModel slip) async {
    final docRef = slip.id.isNotEmpty ? _payrollCollection.doc(slip.id) : _payrollCollection.doc();
    final data = slip.copyWith(id: docRef.id).toJson();
    await docRef.set(data);
  }

  @override
  Future<void> deletePayrollSlip(String id) async {
    await _payrollCollection.doc(id).delete();
  }

  // --- Staff Monthly Sales & Orders ---

  @override
  Stream<Map<String, double>> watchMonthlySales(String monthPeriod) {
    return _ordersCollection.snapshots().map((snap) {
      final Map<String, double> salesMap = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        if (status == 'cancelled' || status == 'returned') continue;

        final rawDate = data['orderDate'] ?? data['createdAt'];
        DateTime? dt;
        if (rawDate is Timestamp) {
          dt = rawDate.toDate();
        } else if (rawDate is String) {
          dt = DateTime.tryParse(rawDate);
        }

        if (dt != null) {
          final period = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          if (period == monthPeriod) {
            final staffId = data['salesPersonId']?.toString() ?? data['cashierId']?.toString() ?? '';
            final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
            if (staffId.isNotEmpty && amount > 0) {
              salesMap[staffId] = (salesMap[staffId] ?? 0.0) + amount;
            }
          }
        }
      }
      return salesMap;
    }).handleError((e) {
      debugPrint('Firestore watchMonthlySales error: $e');
      return <String, double>{};
    });
  }

  @override
  Stream<Map<String, int>> watchMonthlyOrdersCount(String monthPeriod) {
    return _ordersCollection.snapshots().map((snap) {
      final Map<String, int> countsMap = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        if (status == 'cancelled' || status == 'returned') continue;

        final rawDate = data['orderDate'] ?? data['createdAt'];
        DateTime? dt;
        if (rawDate is Timestamp) {
          dt = rawDate.toDate();
        } else if (rawDate is String) {
          dt = DateTime.tryParse(rawDate);
        }

        if (dt != null) {
          final period = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          if (period == monthPeriod) {
            final staffId = data['salesPersonId']?.toString() ?? data['cashierId']?.toString() ?? '';
            if (staffId.isNotEmpty) {
              countsMap[staffId] = (countsMap[staffId] ?? 0) + 1;
            }
          }
        }
      }
      return countsMap;
    }).handleError((e) {
      debugPrint('Firestore watchMonthlyOrdersCount error: $e');
      return <String, int>{};
    });
  }

  @override
  Future<Map<String, double>> getMonthlySales(String monthPeriod) async {
    try {
      final snap = await _ordersCollection.get();
      final Map<String, double> salesMap = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        if (status == 'cancelled' || status == 'returned') continue;

        final rawDate = data['orderDate'] ?? data['createdAt'];
        DateTime? dt;
        if (rawDate is Timestamp) {
          dt = rawDate.toDate();
        } else if (rawDate is String) {
          dt = DateTime.tryParse(rawDate);
        }

        if (dt != null) {
          final period = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          if (period == monthPeriod) {
            final staffId = data['salesPersonId']?.toString() ?? data['cashierId']?.toString() ?? '';
            final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
            if (staffId.isNotEmpty && amount > 0) {
              salesMap[staffId] = (salesMap[staffId] ?? 0.0) + amount;
            }
          }
        }
      }
      return salesMap;
    } catch (e) {
      debugPrint('Firestore getMonthlySales error: $e');
      return {};
    }
  }
}
