import 'package:intl/intl.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/dashboard_analytics_model.dart';

class OrderAnalyticsResult {
  final double totalRevenue;
  final double totalCost;
  final double netProfit;
  final double profitMargin;
  final int todayOrders;
  final int pendingOrders;
  final List<RevenuePoint> weeklyTrend;
  final ChannelFinancialMetrics onlineMetrics;
  final ChannelFinancialMetrics posMetrics;
  final ChannelFinancialMetrics combinedMetrics;
  final List<ProductSalesItemMetrics> productSales;
  final DashboardPeriodType periodType;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String periodLabel;

  const OrderAnalyticsResult({
    required this.totalRevenue,
    this.totalCost = 0.0,
    this.netProfit = 0.0,
    this.profitMargin = 0.0,
    required this.todayOrders,
    required this.pendingOrders,
    required this.weeklyTrend,
    required this.onlineMetrics,
    required this.posMetrics,
    required this.combinedMetrics,
    this.productSales = const [],
    this.periodType = DashboardPeriodType.allTime,
    this.filterStartDate,
    this.filterEndDate,
    this.periodLabel = 'كافة الفترات',
  });
}

/// Calculator for order financial, profitability, channel separation, and velocity metrics.
class OrderAnalyticsCalculator {
  const OrderAnalyticsCalculator();

  OrderAnalyticsResult calculate({
    required List<OrderModel> orders,
    List<ProductModel> products = const [],
    DashboardPeriodType periodType = DashboardPeriodType.allTime,
    DateTime? customStartDate,
    DateTime? customEndDate,
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    DateTime? effectiveStart;
    DateTime? effectiveEnd;
    String periodLabel = 'كافة الفترات';

    switch (periodType) {
      case DashboardPeriodType.today:
        effectiveStart = todayStart;
        effectiveEnd = todayEnd;
        periodLabel = 'اليوم (${DateFormat('yyyy/MM/dd').format(now)})';
        break;
      case DashboardPeriodType.thisWeek:
        effectiveStart = todayStart.subtract(const Duration(days: 6));
        effectiveEnd = todayEnd;
        periodLabel = 'آخر 7 أيام';
        break;
      case DashboardPeriodType.thisMonth:
        effectiveStart = DateTime(now.year, now.month, 1);
        effectiveEnd = todayEnd;
        periodLabel = 'هذا الشهر (${DateFormat('MMMM yyyy').format(now)})';
        break;
      case DashboardPeriodType.thisYear:
        effectiveStart = DateTime(now.year, 1, 1);
        effectiveEnd = todayEnd;
        periodLabel = 'هذا العام (${now.year})';
        break;
      case DashboardPeriodType.custom:
        effectiveStart = customStartDate != null
            ? DateTime(customStartDate.year, customStartDate.month, customStartDate.day)
            : null;
        effectiveEnd = customEndDate != null
            ? DateTime(customEndDate.year, customEndDate.month, customEndDate.day, 23, 59, 59, 999)
            : null;
        if (effectiveStart != null && effectiveEnd != null) {
          periodLabel = '${DateFormat('MM/dd').format(effectiveStart)} - ${DateFormat('MM/dd').format(effectiveEnd)}';
        } else {
          periodLabel = 'فترة مخصصة';
        }
        break;
      case DashboardPeriodType.allTime:
        effectiveStart = null;
        effectiveEnd = null;
        periodLabel = 'كافة الفترات';
        break;
    }

    // 1. Filter orders within the selected time period
    final scopedOrders = orders.where((o) {
      if (effectiveStart != null && o.orderDate.isBefore(effectiveStart)) return false;
      if (effectiveEnd != null && o.orderDate.isAfter(effectiveEnd)) return false;
      return true;
    }).toList();

    // 2. Separate into Online App orders and In-Store POS sales
    final onlineOrders = scopedOrders.where((o) => o.isOnlineOrder).toList();
    final posOrders = scopedOrders.where((o) => o.isPosSale).toList();

    final onlineMetrics = _calculateChannelMetrics(onlineOrders, products);
    final posMetrics = _calculateChannelMetrics(posOrders, products);
    final combinedMetrics = _calculateChannelMetrics(scopedOrders, products);

    // 3. Calculate Itemized Product Sales Breakdown
    final productSales = _calculateProductSales(scopedOrders, products);

    // 4. Count today and pending orders from total scoped orders (excluding cancelled/returned)
    int todayOrdersCount = 0;
    int pendingOrdersCount = 0;

    for (final order in orders) {
      final status = order.status.toLowerCase().trim();
      final isCancelled = status == 'cancelled' || status == 'canceled' || status == 'rejected' || status == 'ملغي';
      final isFullReturned = status == 'returned' ||
          status == 'refunded' ||
          status == 'مرتجع' ||
          (order.refundedAmount >= order.totalAmount && order.totalAmount > 0);
      final date = order.orderDate;

      if (status == 'pending') {
        pendingOrdersCount++;
      }
      if (!date.isBefore(todayStart) && !date.isAfter(todayEnd) && !isCancelled && !isFullReturned) {
        todayOrdersCount++;
      }
    }

    // 5. Generate Timeline Points
    final List<RevenuePoint> weeklyTrend = _buildTimelineTrend(
      orders: scopedOrders,
      periodType: periodType,
      startDate: effectiveStart ?? (orders.isNotEmpty ? orders.last.orderDate : todayStart),
      endDate: effectiveEnd ?? todayEnd,
    );

    return OrderAnalyticsResult(
      totalRevenue: combinedMetrics.revenue,
      totalCost: combinedMetrics.cost,
      netProfit: combinedMetrics.netProfit,
      profitMargin: combinedMetrics.profitMargin,
      todayOrders: todayOrdersCount,
      pendingOrders: pendingOrdersCount,
      weeklyTrend: weeklyTrend,
      onlineMetrics: onlineMetrics,
      posMetrics: posMetrics,
      combinedMetrics: combinedMetrics,
      productSales: productSales,
      periodType: periodType,
      filterStartDate: effectiveStart,
      filterEndDate: effectiveEnd,
      periodLabel: periodLabel,
    );
  }

  ChannelFinancialMetrics _calculateChannelMetrics(
    List<OrderModel> channelOrders,
    List<ProductModel> products,
  ) {
    double revenue = 0.0;
    double cost = 0.0;
    double totalRefunded = 0.0;
    int count = 0;
    int returnedCount = 0;

    for (final order in channelOrders) {
      final status = order.status.toLowerCase().trim();
      final isCancelled = status == 'cancelled' ||
          status == 'canceled' ||
          status == 'rejected' ||
          status == 'ملغي';
      final isFullReturned = status == 'returned' ||
          status == 'refunded' ||
          status == 'مرتجع' ||
          (order.refundedAmount >= order.totalAmount && order.totalAmount > 0);

      // Cancelled orders contribute 0 revenue and 0 cost
      if (isCancelled) {
        continue;
      }

      // Fully returned orders contribute 0 revenue and 0 cost
      if (isFullReturned) {
        totalRefunded += order.refundedAmount > 0 ? order.refundedAmount : order.totalAmount;
        returnedCount++;
        continue;
      }

      final isDelivered = status == 'delivered' ||
          status == 'completed' ||
          status == 'تم التسليم' ||
          status == 'partially_returned' ||
          order.isPosSale;

      if (!isDelivered) {
        continue;
      }

      // Net revenue = totalAmount - refundedAmount
      final refunded = order.refundedAmount.clamp(0.0, order.totalAmount);
      final netOrderRevenue = (order.totalAmount - refunded).clamp(0.0, double.infinity);

      if (refunded > 0) {
        totalRefunded += refunded;
        returnedCount++;
      }

      if (netOrderRevenue <= 0 && refunded > 0) {
        continue; // Fully refunded
      }

      revenue += netOrderRevenue;
      count++;

      // Build returned item quantities map from returnHistory
      final Map<String, int> returnedQuantities = {};
      for (final ret in order.returnHistory) {
        final retItems = ret['items'];
        if (retItems is List) {
          for (final ri in retItems) {
            if (ri is Map) {
              final pId = (ri['productId'] ?? ri['id'])?.toString().trim() ?? '';
              final sku = ri['sku']?.toString().trim() ?? '';
              final q = (ri['quantity'] as num?)?.toInt() ?? 1;
              if (sku.isNotEmpty) {
                returnedQuantities['sku:${sku.toLowerCase()}'] =
                    (returnedQuantities['sku:${sku.toLowerCase()}'] ?? 0) + q;
              }
              if (pId.isNotEmpty) {
                returnedQuantities['pid:$pId'] = (returnedQuantities['pid:$pId'] ?? 0) + q;
              }
            }
          }
        }
      }

      double orderCost = 0.0;
      for (final item in order.items) {
        final originalQty = item.quantity > 0 ? item.quantity : 1;
        int returnedQty = 0;
        final skuKey = item.sku.isNotEmpty ? 'sku:${item.sku.toLowerCase()}' : '';
        final pidKey = item.productId.isNotEmpty ? 'pid:${item.productId}' : '';

        if (skuKey.isNotEmpty && returnedQuantities.containsKey(skuKey)) {
          returnedQty = returnedQuantities[skuKey]!;
        } else if (pidKey.isNotEmpty && returnedQuantities.containsKey(pidKey)) {
          returnedQty = returnedQuantities[pidKey]!;
        }

        final netQty = (originalQty - returnedQty).clamp(0, originalQty);
        if (netQty <= 0) continue;

        double unitCost = 0.0;
        if (products.isNotEmpty) {
          final matchedProd = products
              .where((p) =>
                  p.id == item.productId ||
                  (p.title.isNotEmpty &&
                      p.title.toLowerCase() == item.title.toLowerCase()))
              .firstOrNull;

          if (matchedProd != null) {
            if (matchedProd.productVariations.isNotEmpty) {
              final matchedVar = matchedProd.productVariations.where((v) {
                if (item.sku.isNotEmpty &&
                    v.sku.toLowerCase() == item.sku.toLowerCase()) {
                  return true;
                }
                if (item.selectedVariation.isNotEmpty) {
                  return item.selectedVariation.entries.every((e) =>
                      (v.attributeValues[e.key] ?? '').toLowerCase() ==
                      e.value.toLowerCase());
                }
                return false;
              }).firstOrNull;

              if (matchedVar != null && matchedVar.costPrice > 0) {
                unitCost = matchedVar.costPrice;
              } else if (matchedProd.costPrice > 0) {
                unitCost = matchedProd.costPrice;
              }
            } else if (matchedProd.costPrice > 0) {
              unitCost = matchedProd.costPrice;
            }
          }
        }

        orderCost += unitCost * netQty;
      }

      // If returnHistory was not itemized but refundedAmount was recorded, adjust cost proportionally
      if (order.returnHistory.isEmpty && refunded > 0 && order.totalAmount > 0) {
        final refundRatio = (refunded / order.totalAmount).clamp(0.0, 1.0);
        orderCost = orderCost * (1.0 - refundRatio);
      }

      cost += orderCost;
    }

    final netProfit = revenue - cost;
    final profitMargin = revenue > 0 ? (netProfit / revenue) * 100 : 0.0;
    final averageTicket = count > 0 ? (revenue / count) : 0.0;

    return ChannelFinancialMetrics(
      revenue: revenue,
      cost: cost,
      netProfit: netProfit,
      profitMargin: profitMargin,
      count: count,
      averageTicket: averageTicket,
      refundedAmount: totalRefunded,
      returnedCount: returnedCount,
    );
  }

  List<RevenuePoint> _buildTimelineTrend({
    required List<OrderModel> orders,
    required DashboardPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final Map<String, ({double revenue, int count})> pointsMap = {};

    if (periodType == DashboardPeriodType.today) {
      // 6 time blocks throughout the day
      for (int h = 0; h < 24; h += 4) {
        final label = '${h.toString().padLeft(2, '0')}:00';
        pointsMap[label] = (revenue: 0.0, count: 0);
      }
      for (final o in orders) {
        final status = o.status.toLowerCase().trim();
        final isCancelled = status == 'cancelled' ||
            status == 'canceled' ||
            status == 'rejected' ||
            status == 'ملغي';
        final isFullReturned = status == 'returned' ||
            status == 'refunded' ||
            status == 'مرتجع' ||
            (o.refundedAmount >= o.totalAmount && o.totalAmount > 0);

        if (isCancelled || isFullReturned) continue;

        final isDelivered = status == 'delivered' ||
            status == 'completed' ||
            status == 'تم التسليم' ||
            status == 'partially_returned' ||
            o.isPosSale;

        if (!isDelivered) continue;

        final netOrderRev = (o.totalAmount - o.refundedAmount).clamp(0.0, double.infinity);
        final blockHour = (o.orderDate.hour ~/ 4) * 4;
        final label = '${blockHour.toString().padLeft(2, '0')}:00';
        if (pointsMap.containsKey(label)) {
          final cur = pointsMap[label]!;
          pointsMap[label] = (
            revenue: cur.revenue + netOrderRev,
            count: cur.count + 1,
          );
        }
      }
    } else {
      // Default: Last 7 days / Daily breakdown
      final daysDiff = endDate.difference(startDate).inDays.clamp(1, 30);
      final int stepDays = (daysDiff / 7).ceil().clamp(1, 30);

      for (int i = 6; i >= 0; i--) {
        final d = endDate.subtract(Duration(days: i * stepDays));
        final label = DateFormat('E d/M').format(d);
        pointsMap[label] = (revenue: 0.0, count: 0);
      }

      for (final order in orders) {
        final status = order.status.toLowerCase().trim();
        final isCancelled = status == 'cancelled' ||
            status == 'canceled' ||
            status == 'rejected' ||
            status == 'ملغي';
        final isFullReturned = status == 'returned' ||
            status == 'refunded' ||
            status == 'مرتجع' ||
            (order.refundedAmount >= order.totalAmount && order.totalAmount > 0);

        if (isCancelled || isFullReturned) continue;

        final isDelivered = status == 'delivered' ||
            status == 'completed' ||
            status == 'تم التسليم' ||
            status == 'partially_returned' ||
            order.isPosSale;

        if (!isDelivered) continue;

        final netOrderRev = (order.totalAmount - order.refundedAmount).clamp(0.0, double.infinity);

        // Find matching day bucket
        final orderDayStr = DateFormat('E d/M').format(order.orderDate);
        if (pointsMap.containsKey(orderDayStr)) {
          final cur = pointsMap[orderDayStr]!;
          pointsMap[orderDayStr] = (
            revenue: cur.revenue + netOrderRev,
            count: cur.count + 1,
          );
        } else {
          for (final entry in pointsMap.entries) {
            final cur = entry.value;
            pointsMap[entry.key] = (
              revenue: cur.revenue + (netOrderRev / pointsMap.length),
              count: cur.count + 1,
            );
            break;
          }
        }
      }
    }

    return pointsMap.entries.map((e) {
      return RevenuePoint(
        label: e.key,
        revenue: e.value.revenue,
        ordersCount: e.value.count,
      );
    }).toList();
  }

  List<ProductSalesItemMetrics> _calculateProductSales(
    List<OrderModel> orders,
    List<ProductModel> products,
  ) {
    final Map<String, ProductSalesItemMetrics> productMap = {};

    for (final order in orders) {
      final status = order.status.toLowerCase().trim();
      final isCancelled = status == 'cancelled' ||
          status == 'canceled' ||
          status == 'rejected' ||
          status == 'ملغي';
      final isFullReturned = status == 'returned' ||
          status == 'refunded' ||
          status == 'مرتجع' ||
          (order.refundedAmount >= order.totalAmount && order.totalAmount > 0);

      if (isCancelled || isFullReturned) continue;

      final isDelivered = status == 'delivered' ||
          status == 'completed' ||
          status == 'تم التسليم' ||
          status == 'partially_returned' ||
          order.isPosSale;

      if (!isDelivered) continue;

      final isOnline = order.isOnlineOrder;
      final isPos = order.isPosSale;

      // Build returned item quantities map from returnHistory
      final Map<String, int> returnedQuantities = {};
      for (final ret in order.returnHistory) {
        final retItems = ret['items'];
        if (retItems is List) {
          for (final ri in retItems) {
            if (ri is Map) {
              final pId = (ri['productId'] ?? ri['id'])?.toString().trim() ?? '';
              final sku = ri['sku']?.toString().trim() ?? '';
              final q = (ri['quantity'] as num?)?.toInt() ?? 1;
              if (sku.isNotEmpty) {
                returnedQuantities['sku:${sku.toLowerCase()}'] =
                    (returnedQuantities['sku:${sku.toLowerCase()}'] ?? 0) + q;
              }
              if (pId.isNotEmpty) {
                returnedQuantities['pid:$pId'] = (returnedQuantities['pid:$pId'] ?? 0) + q;
              }
            }
          }
        }
      }

      for (final item in order.items) {
        final key = item.productId.isNotEmpty ? item.productId : item.title.trim().toLowerCase();
        if (key.isEmpty) continue;

        final originalQty = item.quantity > 0 ? item.quantity : 1;
        int returnedQty = 0;
        final skuKey = item.sku.isNotEmpty ? 'sku:${item.sku.toLowerCase()}' : '';
        final pidKey = item.productId.isNotEmpty ? 'pid:${item.productId}' : '';

        if (skuKey.isNotEmpty && returnedQuantities.containsKey(skuKey)) {
          returnedQty = returnedQuantities[skuKey]!;
        } else if (pidKey.isNotEmpty && returnedQuantities.containsKey(pidKey)) {
          returnedQty = returnedQuantities[pidKey]!;
        }

        final netQty = (originalQty - returnedQty).clamp(0, originalQty);
        if (netQty <= 0) continue;

        final revenue = item.price * netQty;

        // Determine unit cost
        double unitCost = 0.0;
        ProductModel? matchedProd;
        if (products.isNotEmpty) {
          matchedProd = products
              .where((p) =>
                  p.id == item.productId ||
                  (p.title.isNotEmpty && p.title.toLowerCase() == item.title.toLowerCase()))
              .firstOrNull;

          if (matchedProd != null) {
            if (matchedProd.productVariations.isNotEmpty) {
              final matchedVar = matchedProd.productVariations.where((v) {
                if (item.sku.isNotEmpty && v.sku.toLowerCase() == item.sku.toLowerCase()) {
                  return true;
                }
                if (item.selectedVariation.isNotEmpty) {
                  return item.selectedVariation.entries.every((e) =>
                      (v.attributeValues[e.key] ?? '').toLowerCase() == e.value.toLowerCase());
                }
                return false;
              }).firstOrNull;

              if (matchedVar != null && matchedVar.costPrice > 0) {
                unitCost = matchedVar.costPrice;
              } else if (matchedProd.costPrice > 0) {
                unitCost = matchedProd.costPrice;
              }
            } else if (matchedProd.costPrice > 0) {
              unitCost = matchedProd.costPrice;
            }
          }
        }

        final itemCost = unitCost * netQty;
        final profit = revenue - itemCost;

        if (productMap.containsKey(key)) {
          final existing = productMap[key]!;
          final updatedOnlineQty = existing.onlineQuantity + (isOnline ? netQty : 0);
          final updatedPosQty = existing.posQuantity + (isPos ? netQty : 0);
          final updatedTotalQty = existing.totalQuantity + netQty;
          final updatedRevenue = existing.totalRevenue + revenue;
          final updatedCost = existing.totalCost + itemCost;
          final updatedProfit = updatedRevenue - updatedCost;
          final updatedMargin = updatedRevenue > 0 ? (updatedProfit / updatedRevenue) * 100 : 0.0;
          final updatedOrderIds = List<String>.from(existing.orderIds);
          if (order.id.isNotEmpty && !updatedOrderIds.contains(order.id)) {
            updatedOrderIds.add(order.id);
          }

          productMap[key] = ProductSalesItemMetrics(
            productId: existing.productId,
            productTitle: existing.productTitle,
            productImage: existing.productImage.isNotEmpty
                ? existing.productImage
                : (item.image.isNotEmpty ? item.image : (matchedProd?.thumbnail ?? '')),
            categoryName: existing.categoryName.isNotEmpty
                ? existing.categoryName
                : (matchedProd?.categoryId ?? ''),
            brandName: existing.brandName.isNotEmpty
                ? existing.brandName
                : (item.brand.isNotEmpty ? item.brand : (matchedProd?.brand.name ?? '')),
            sku: existing.sku.isNotEmpty ? existing.sku : item.sku,
            onlineQuantity: updatedOnlineQty,
            posQuantity: updatedPosQty,
            totalQuantity: updatedTotalQty,
            avgUnitPrice: updatedTotalQty > 0 ? updatedRevenue / updatedTotalQty : 0.0,
            avgUnitCost: updatedTotalQty > 0 ? updatedCost / updatedTotalQty : 0.0,
            totalRevenue: updatedRevenue,
            totalCost: updatedCost,
            netProfit: updatedProfit,
            profitMargin: updatedMargin,
            ordersCount: updatedOrderIds.length,
            orderIds: updatedOrderIds,
          );
        } else {
          final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
          final orderIdsList = order.id.isNotEmpty ? [order.id] : <String>[];

          productMap[key] = ProductSalesItemMetrics(
            productId: item.productId.isNotEmpty ? item.productId : (matchedProd?.id ?? key),
            productTitle: item.title.isNotEmpty ? item.title : (matchedProd?.title ?? 'منتج'),
            productImage: item.image.isNotEmpty
                ? item.image
                : (matchedProd?.thumbnail ?? (matchedProd?.images.firstOrNull ?? '')),
            categoryName: matchedProd?.categoryId ?? '',
            brandName: item.brand.isNotEmpty ? item.brand : (matchedProd?.brand.name ?? ''),
            sku: item.sku.isNotEmpty
                ? item.sku
                : (matchedProd?.productVariations.firstOrNull?.sku ?? ''),
            onlineQuantity: isOnline ? netQty : 0,
            posQuantity: isPos ? netQty : 0,
            totalQuantity: netQty,
            avgUnitPrice: item.price,
            avgUnitCost: unitCost,
            totalRevenue: revenue,
            totalCost: itemCost,
            netProfit: profit,
            profitMargin: margin,
            ordersCount: orderIdsList.length,
            orderIds: orderIdsList,
          );
        }
      }
    }

    final sortedList = productMap.values.where((p) => p.totalQuantity > 0).toList()
      ..sort((a, b) {
        final qtyComp = b.totalQuantity.compareTo(a.totalQuantity);
        if (qtyComp != 0) return qtyComp;
        return b.totalRevenue.compareTo(a.totalRevenue);
      });

    return sortedList;
  }
}
