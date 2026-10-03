import 'package:equatable/equatable.dart';
import '../../../customers/data/models/customer_model.dart';
import 'package:admin_panel_ego/features/customers/domain/services/loyalty_service.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/pos_cart_item_model.dart';
import '../../data/models/pos_catalog_item.dart';
import '../../data/models/pos_sale_model.dart';

enum PosSaleStatus { initial, loading, success, failure }

class PosState extends Equatable {
  final List<ProductModel> allProducts;
  final List<ProductModel> filteredProducts;
  final String searchQuery;
  final ProductCategoryType? selectedCategory;
  final List<PosCartItemModel> cartItems;
  final double cartDiscount; // Additional discount on the total bill
  final String customerName;
  final String customerPhone;
  final CustomerModel? matchedCustomer;
  final int pointsRedeemed;
  final double pointsDiscount;
  final bool isSearchingCustomer;
  final String orderNotes;
  final String paymentMethod; // 'cash', 'card', 'instapay'
  final double paidAmount;
  final PosSaleStatus saleStatus;
  final PosSaleModel? lastCompletedSale;
  final String? errorMessage;
  final String? barcodeFeedbackMessage;

  const PosState({
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.cartItems = const [],
    this.cartDiscount = 0.0,
    this.customerName = '',
    this.customerPhone = '',
    this.matchedCustomer,
    this.pointsRedeemed = 0,
    this.pointsDiscount = 0.0,
    this.isSearchingCustomer = false,
    this.orderNotes = '',
    this.paymentMethod = 'cash',
    this.paidAmount = 0.0,
    this.saleStatus = PosSaleStatus.initial,
    this.lastCompletedSale,
    this.errorMessage,
    this.barcodeFeedbackMessage,
  });

  /// All flattened saleable units across the entire catalog (every variation as a separate item)
  List<PosCatalogItem> get allCatalogItems {
    final List<PosCatalogItem> list = [];
    for (final product in allProducts) {
      if (product.isVariable && product.productVariations.isNotEmpty) {
        for (final variation in product.productVariations) {
          list.add(PosCatalogItem(product: product, variation: variation));
        }
      } else {
        list.add(PosCatalogItem(product: product));
      }
    }
    return list;
  }

  /// Filtered saleable units matching active category and search query
  List<PosCatalogItem> get filteredCatalogItems {
    var items = allCatalogItems;

    if (selectedCategory != null) {
      items = items.where((i) => i.categoryType == selectedCategory).toList();
    }

    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      items = items.where((i) => i.matchesSearch(words)).toList();
    }

    return items;
  }

  /// Total sum of all line items before any discounts
  double get subTotal => cartItems.fold(0.0, (sum, itm) => sum + itm.originalLineTotal);

  /// Total sum of discounts applied directly to items
  double get itemDiscounts => cartItems.fold(0.0, (sum, itm) => sum + itm.totalLineDiscount);

  /// Grand total discount (item discounts + overall cart discount + loyalty points discount)
  double get totalDiscount => itemDiscounts + cartDiscount + pointsDiscount;

  /// Loyalty points earned on this sale
  int get pointsEarned => LoyaltyService.calculateEarnedPoints(grandTotal);

  /// Final payable amount
  double get grandTotal => (subTotal - totalDiscount).clamp(0.0, double.infinity);

  /// Remaining change to return to customer when paying cash
  double get changeAmount {
    if (paymentMethod != 'cash' || paidAmount <= 0) return 0.0;
    return (paidAmount - grandTotal).clamp(0.0, double.infinity);
  }

  /// Total number of physical units in cart
  int get totalItemsCount => cartItems.fold(0, (sum, itm) => sum + itm.quantity);

  /// Whether cart contains any items
  bool get hasItems => cartItems.isNotEmpty;

  PosState copyWith({
    List<ProductModel>? allProducts,
    List<ProductModel>? filteredProducts,
    String? searchQuery,
    ProductCategoryType? selectedCategory,
    bool clearCategory = false,
    List<PosCartItemModel>? cartItems,
    double? cartDiscount,
    String? customerName,
    String? customerPhone,
    CustomerModel? matchedCustomer,
    bool clearMatchedCustomer = false,
    int? pointsRedeemed,
    double? pointsDiscount,
    bool? isSearchingCustomer,
    String? orderNotes,
    String? paymentMethod,
    double? paidAmount,
    PosSaleStatus? saleStatus,
    PosSaleModel? lastCompletedSale,
    String? errorMessage,
    String? barcodeFeedbackMessage,
    bool clearFeedback = false,
  }) {
    return PosState(
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      cartItems: cartItems ?? this.cartItems,
      cartDiscount: cartDiscount ?? this.cartDiscount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      matchedCustomer: clearMatchedCustomer ? null : (matchedCustomer ?? this.matchedCustomer),
      pointsRedeemed: pointsRedeemed ?? this.pointsRedeemed,
      pointsDiscount: pointsDiscount ?? this.pointsDiscount,
      isSearchingCustomer: isSearchingCustomer ?? this.isSearchingCustomer,
      orderNotes: orderNotes ?? this.orderNotes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      saleStatus: saleStatus ?? this.saleStatus,
      lastCompletedSale: lastCompletedSale ?? this.lastCompletedSale,
      errorMessage: errorMessage,
      barcodeFeedbackMessage: clearFeedback ? null : (barcodeFeedbackMessage ?? this.barcodeFeedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        allProducts,
        filteredProducts,
        searchQuery,
        selectedCategory,
        cartItems,
        cartDiscount,
        customerName,
        customerPhone,
        matchedCustomer,
        pointsRedeemed,
        pointsDiscount,
        isSearchingCustomer,
        orderNotes,
        paymentMethod,
        paidAmount,
        saleStatus,
        lastCompletedSale,
        errorMessage,
        barcodeFeedbackMessage,
      ];
}
