import '../../../core/formatters/formatters.dart';
import '../data/models/order_model.dart';

/// Strategy interface for formatting order data for distinct communication and dispatch channels (OCP).
abstract class OrderShareFormatterStrategy {
  String get strategyName;
  String format(OrderModel order);
}

/// Formatter strategy specifically tuned for delivery couriers and shipping slips.
class CourierSlipShareStrategy implements OrderShareFormatterStrategy {
  const CourierSlipShareStrategy();

  @override
  String get strategyName => 'Courier Delivery Slip';

  /// Build direct Google Maps search URL from shipping address
  static String buildGoogleMapsUrl(ShippingAddressModel addr) {
    final queryParts = <String>[];
    if (addr.street.isNotEmpty) queryParts.add(addr.street);
    if (addr.landmark.isNotEmpty) queryParts.add(addr.landmark);
    if (addr.city.isNotEmpty) queryParts.add(addr.city);
    if (addr.governorate.isNotEmpty &&
        addr.governorate.toLowerCase() != addr.city.toLowerCase()) {
      queryParts.add(addr.governorate);
    }
    if (addr.country.isNotEmpty) queryParts.add(addr.country);

    final query =
        queryParts.isNotEmpty ? queryParts.join(', ') : 'Cairo, Egypt';
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
  }

  @override
  String format(OrderModel order) {
    final addr = order.shippingAddress;
    final buffer = StringBuffer();

    // 1. Header
    buffer.writeln('📦 *طلب توصيل - EGO VAPE STORE*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🆔 *رقم الطلب:* #${order.id}');
    buffer.writeln('📅 *التاريخ:* ${AppFormatters.formatDateTime(order.orderDate)}');
    buffer.writeln('');

    // 2. Customer details
    buffer.writeln('👤 *بيانات العميل:*');
    buffer.writeln('• الاسم: ${addr.name.isNotEmpty ? addr.name : "عميل إيجو ستور"}');
    if (addr.phoneNumber.isNotEmpty) {
      buffer.writeln('• رقم الهاتف: ${addr.phoneNumber}');
    }
    if (addr.alternatePhone.isNotEmpty) {
      buffer.writeln('• هاتف إضافي: ${addr.alternatePhone}');
    }
    buffer.writeln('');

    // 3. Detailed Address
    buffer.writeln('📍 *عنوان التوصيل:*');
    final govCity = addr.governorate.isNotEmpty &&
            addr.city.isNotEmpty &&
            addr.governorate.toLowerCase() != addr.city.toLowerCase()
        ? '${addr.governorate} - ${addr.city}'
        : (addr.governorate.isNotEmpty ? addr.governorate : addr.city);
    if (govCity.isNotEmpty) {
      buffer.writeln('• المحافظة / المنطقة: $govCity');
    }
    if (addr.street.isNotEmpty) {
      buffer.writeln('• الشارع: ${addr.street}');
    }
    if (addr.building.isNotEmpty || addr.floor.isNotEmpty || addr.apartment.isNotEmpty) {
      final buildingParts = <String>[];
      if (addr.building.isNotEmpty) buildingParts.add('عمارة/مبنى: ${addr.building}');
      if (addr.floor.isNotEmpty) buildingParts.add('طابق: ${addr.floor}');
      if (addr.apartment.isNotEmpty) buildingParts.add('شقة: ${addr.apartment}');
      buffer.writeln('• تفاصيل المبنى: ${buildingParts.join(' | ')}');
    }
    if (addr.landmark.isNotEmpty) {
      buffer.writeln('• علامة مميزة: ${addr.landmark}');
    }

    // Google Maps link
    final mapsUrl = buildGoogleMapsUrl(addr);
    buffer.writeln('🗺️ *موقع الخريطة (GPS):*');
    buffer.writeln(mapsUrl);
    buffer.writeln('');

    // 4. Customer Notes (if any)
    if (order.orderNotes.isNotEmpty) {
      buffer.writeln('📝 *ملاحظات خاصة بالتوصيل:*');
      buffer.writeln(order.orderNotes);
      buffer.writeln('');
    }

    // 5. Ordered Items
    buffer.writeln('🛍️ *الأصناف والمنتجات (${order.items.length}):*');
    if (order.items.isEmpty) {
      buffer.writeln('• تفاصيل الأصناف مسجلة بالنظام');
    } else {
      for (int i = 0; i < order.items.length; i++) {
        final itm = order.items[i];
        final varString = itm.selectedVariation.isNotEmpty
            ? ' (${itm.selectedVariation.entries.map((e) => '${e.key}: ${e.value}').join(', ')})'
            : '';
        final itemTitle = itm.formattedTitleWithBrand;
        buffer.writeln('${i + 1}. ${itm.quantity}x $itemTitle$varString');
      }
    }
    buffer.writeln('');

    // 6. Financial Summary & Collection Amount
    buffer.writeln('💰 *المبلغ والحساب المطلوب تحصيله:*');
    buffer.writeln('• قيمة المنتجات: ${AppFormatters.formatEGP(order.subTotal)}');
    buffer.writeln(
      '• مصاريف التوصيل: ${order.shippingCost == 0 ? "مجاني" : AppFormatters.formatEGP(order.shippingCost)}',
    );
    if (order.discount > 0) {
      buffer.writeln('• الخصم: -${AppFormatters.formatEGP(order.discount)}');
    }

    final isPaid = order.paymentStatus.toLowerCase() == 'paid' ||
        order.paymentMethod.toLowerCase().contains('card') ||
        order.paymentMethod.toLowerCase().contains('visa') ||
        order.paymentMethod.toLowerCase().contains('wallet');

    if (isPaid) {
      buffer.writeln(
        '💵 *المطلوب تحصيله:* *0.00 ج.م* (✅ مدفوع مسبقاً إلكترونياً - لا يتم تحصيل مبلغ)',
      );
    } else {
      buffer.writeln(
        '💵 *المطلوب تحصيله من العميل:* *${AppFormatters.formatEGP(order.totalAmount)}* (الدفع عند الاستلام - COD)',
      );
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.write('⚡ *EGO Vape Store Management*');

    return buffer.toString();
  }
}

/// Concise WhatsApp notification message for customers.
class CustomerWhatsAppShareStrategy implements OrderShareFormatterStrategy {
  const CustomerWhatsAppShareStrategy();

  @override
  String get strategyName => 'Customer WhatsApp Message';

  @override
  String format(OrderModel order) {
    return 'مرحباً ${order.shippingAddress.name}، بخصوص طلبك #${order.id} من متجر EGO Store بقيمة ${AppFormatters.formatEGP(order.totalAmount)}، حالته الآن: ${order.status}.';
  }
}
