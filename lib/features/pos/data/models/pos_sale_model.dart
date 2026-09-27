import 'package:equatable/equatable.dart';
import 'pos_cart_item_model.dart';

/// Complete POS In-Store Sale transaction model
class PosSaleModel extends Equatable {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final String cashierName;
  final String cashierId;
  final String customerName;
  final String customerPhone;
  final List<PosCartItemModel> items;
  final double subTotal;
  final double discount; // Cart-level discount
  final double taxFee;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod; // 'cash', 'card', 'instapay', 'split'
  final String notes;
  final String status; // 'completed', 'refunded'

  const PosSaleModel({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    this.cashierName = 'Store Cashier',
    this.cashierId = '',
    this.customerName = 'Walk-in Customer (عميل مباشر)',
    this.customerPhone = '',
    required this.items,
    required this.subTotal,
    this.discount = 0.0,
    this.taxFee = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.changeAmount = 0.0,
    this.paymentMethod = 'cash',
    this.notes = '',
    this.status = 'completed',
  });

  int get totalItemsCount => items.fold(0, (acc, itm) => acc + itm.quantity);

  PosSaleModel copyWith({
    String? id,
    String? orderNumber,
    DateTime? createdAt,
    String? cashierName,
    String? cashierId,
    String? customerName,
    String? customerPhone,
    List<PosCartItemModel>? items,
    double? subTotal,
    double? discount,
    double? taxFee,
    double? totalAmount,
    double? paidAmount,
    double? changeAmount,
    String? paymentMethod,
    String? notes,
    String? status,
  }) {
    return PosSaleModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      createdAt: createdAt ?? this.createdAt,
      cashierName: cashierName ?? this.cashierName,
      cashierId: cashierId ?? this.cashierId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subTotal: subTotal ?? this.subTotal,
      discount: discount ?? this.discount,
      taxFee: taxFee ?? this.taxFee,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'createdAt': createdAt.toIso8601String(),
        'cashierName': cashierName,
        'cashierId': cashierId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': items.map((e) => e.toJson()).toList(),
        'subTotal': subTotal,
        'discount': discount,
        'taxFee': taxFee,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'changeAmount': changeAmount,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'status': status,
        'source': 'pos',
        'orderType': 'in_store',
      };

  factory PosSaleModel.fromJson(Map<String, dynamic> json) {
    return PosSaleModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      cashierName: json['cashierName']?.toString() ?? 'Store Cashier',
      cashierId: json['cashierId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Walk-in Customer',
      customerPhone: json['customerPhone']?.toString() ?? '',
      items: (json['items'] as List?)
              ?.map((e) => PosCartItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      taxFee: (json['taxFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'completed',
    );
  }

  /// Factory constructor to bridge an OrderModel representing a POS sale into PosSaleModel
  factory PosSaleModel.fromOrder(dynamic order) {
    final List<PosCartItemModel> cartItems = [];
    if (order.items != null) {
      for (final itm in order.items) {
        cartItems.add(PosCartItemModel(
          productId: itm.productId ?? '',
          title: itm.title ?? '',
          brand: itm.brand ?? '',
          sku: itm.sku ?? '',
          image: itm.image ?? '',
          unitPrice: (itm.price as num?)?.toDouble() ?? 0.0,
          quantity: (itm.quantity as num?)?.toInt() ?? 1,
          selectedVariation: Map<String, String>.from(itm.selectedVariation ?? {}),
        ));
      }
    }

    final double total = (order.totalAmount as num?)?.toDouble() ?? 0.0;
    final double sub = (order.subTotal as num?)?.toDouble() ?? total;
    final double disc = (order.discount as num?)?.toDouble() ?? 0.0;
    final double tax = (order.taxFee as num?)?.toDouble() ?? 0.0;

    final String cashier = order.rawDocData?['cashierName']?.toString() ??
        (order.cashierName?.toString().isNotEmpty == true ? order.cashierName.toString() : 'Store Cashier');

    final String custName = order.shippingAddress?.name?.toString().isNotEmpty == true
        ? order.shippingAddress.name.toString()
        : 'Walk-in Customer (عميل مباشر)';

    final String custPhone = order.shippingAddress?.phoneNumber?.toString() ?? '';

    return PosSaleModel(
      id: order.id ?? '',
      orderNumber: order.rawDocData?['orderNumber']?.toString() ?? order.id ?? '',
      createdAt: order.orderDate ?? DateTime.now(),
      cashierName: cashier,
      customerName: custName,
      customerPhone: custPhone,
      items: cartItems,
      subTotal: sub,
      discount: disc,
      taxFee: tax,
      totalAmount: total,
      paidAmount: total,
      changeAmount: 0.0,
      paymentMethod: order.paymentMethod ?? 'cash',
      notes: order.orderNotes ?? '',
      status: order.status ?? 'completed',
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        createdAt,
        cashierName,
        cashierId,
        customerName,
        customerPhone,
        items,
        subTotal,
        discount,
        taxFee,
        totalAmount,
        paidAmount,
        changeAmount,
        paymentMethod,
        notes,
        status,
      ];
}
