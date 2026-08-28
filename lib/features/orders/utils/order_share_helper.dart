import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/formatters/formatters.dart';
import '../../../core/helper/helper_fun.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/models/order_model.dart';
import 'stub_url_launcher.dart'
    if (dart.library.js_interop) 'web_url_launcher.dart' as web_launcher;

class OrderShareHelper {
  OrderShareHelper._();

  /// Build direct Google Maps search URL from shipping address
  static String buildGoogleMapsUrl(ShippingAddressModel addr) {
    final queryParts = <String>[];
    if (addr.street.isNotEmpty) queryParts.add(addr.street);
    if (addr.landmark.isNotEmpty) queryParts.add(addr.landmark);
    if (addr.city.isNotEmpty) queryParts.add(addr.city);
    if (addr.governorate.isNotEmpty && addr.governorate.toLowerCase() != addr.city.toLowerCase()) {
      queryParts.add(addr.governorate);
    }
    if (addr.country.isNotEmpty) queryParts.add(addr.country);

    final query = queryParts.isNotEmpty ? queryParts.join(', ') : 'Cairo, Egypt';
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
  }

  /// Generates clean, well-formatted plain text ready for delivery couriers
  static String generateCourierSlipText(OrderModel order) {
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
    final govCity = addr.governorate.isNotEmpty && addr.city.isNotEmpty && addr.governorate.toLowerCase() != addr.city.toLowerCase()
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
    buffer.writeln('• مصاريف التوصيل: ${order.shippingCost == 0 ? "مجاني" : AppFormatters.formatEGP(order.shippingCost)}');
    if (order.discount > 0) {
      buffer.writeln('• الخصم: -${AppFormatters.formatEGP(order.discount)}');
    }

    final isPaid = order.paymentStatus.toLowerCase() == 'paid' ||
        order.paymentMethod.toLowerCase().contains('card') ||
        order.paymentMethod.toLowerCase().contains('visa') ||
        order.paymentMethod.toLowerCase().contains('wallet');

    if (isPaid) {
      buffer.writeln('💵 *المطلوب تحصيله:* *0.00 ج.م* (✅ مدفوع مسبقاً إلكترونياً - لا يتم تحصيل مبلغ)');
    } else {
      buffer.writeln('💵 *المطلوب تحصيله من العميل:* *${AppFormatters.formatEGP(order.totalAmount)}* (الدفع عند الاستلام - COD)');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.write('⚡ *EGO Vape Store Management*');

    return buffer.toString();
  }

  /// Launch WhatsApp with pre-filled courier message across Web, Desktop, and Mobile
  static Future<bool> launchWhatsApp({
    String? courierPhone,
    required String message,
  }) async {
    // 1. Copy to clipboard in background
    unawaited(Clipboard.setData(ClipboardData(text: message)));

    try {
      String cleanPhone = '';
      if (courierPhone != null && courierPhone.trim().isNotEmpty) {
        cleanPhone = courierPhone.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanPhone.startsWith('01') && cleanPhone.length == 11) {
          cleanPhone = '2$cleanPhone';
        }
      }

      final encoded = Uri.encodeComponent(message);

      // --- WEB: Use direct JavaScript window.open() to bypass popup blockers ---
      if (kIsWeb) {
        // Build the WhatsApp Web URL (wa.me is the most reliable universal link)
        final url = cleanPhone.isNotEmpty
            ? 'https://wa.me/$cleanPhone?text=$encoded'
            : 'https://wa.me/?text=$encoded';

        // Call window.open() SYNCHRONOUSLY — this is critical!
        // Because it's called within the same call stack as the user's click,
        // Chrome/Edge will NOT block it as a popup.
        return web_launcher.openUrlInBrowser(url, target: '_blank');
      }

      // --- MOBILE & DESKTOP NATIVE: Use url_launcher ---
      final queryParams = <String, String>{
        if (cleanPhone.isNotEmpty) 'phone': cleanPhone,
        'text': message,
      };

      final candidateUris = <Uri>[
        Uri(scheme: 'whatsapp', host: 'send', queryParameters: queryParams),
        Uri.https('wa.me', cleanPhone.isNotEmpty ? '/$cleanPhone' : '', {'text': message}),
        Uri.https('web.whatsapp.com', '/send', queryParams),
        Uri.https('api.whatsapp.com', '/send', queryParams),
      ];

      for (final uri in candidateUris) {
        try {
          if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            return true;
          }
        } catch (_) {}

        try {
          if (await launchUrl(uri, mode: LaunchMode.platformDefault)) {
            return true;
          }
        } catch (_) {}
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Launch Facebook share or native system share sheet
  static Future<bool> launchFacebookOrShare({
    required BuildContext context,
    required String message,
    String? subject,
  }) async {
    unawaited(Clipboard.setData(ClipboardData(text: message)));

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: subject ?? 'EGO Store Delivery Slip',
        ),
      );
      if (result.status == ShareResultStatus.success) {
        return true;
      }
    } catch (_) {}

    final encoded = Uri.encodeComponent(message);

    if (kIsWeb) {
      return web_launcher.openUrlInBrowser(
        'https://www.facebook.com/sharer/sharer.php?quote=$encoded',
        target: '_blank',
      );
    }

    final fbUri = Uri.parse('https://www.facebook.com/sharer/sharer.php?quote=$encoded');
    try {
      return await launchUrl(fbUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Launch Google Maps navigation in browser / app
  static Future<bool> launchGoogleMaps(ShippingAddressModel addr) async {
    try {
      final url = buildGoogleMapsUrl(addr);

      if (kIsWeb) {
        return web_launcher.openUrlInBrowser(url, target: '_blank');
      }

      final uri = Uri.parse(url);
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {}

      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  /// Launch Phone Dialer
  static Future<bool> launchPhoneCall(String phoneNumber) async {
    try {
      final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      if (kIsWeb) {
        return web_launcher.openUrlInBrowser('tel:$clean', target: '_self');
      }

      final uri = Uri.parse('tel:$clean');
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  /// Copy formatted courier slip to clipboard and show feedback alert
  static Future<void> copyToClipboard(BuildContext context, String text, {String? successMessage}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      HelperFun.showNotificationAlert(
        title: 'share_slip_copied'.tr,
        message: successMessage ?? 'copied_to_clipboard'.tr,
        context: context,
      );
    }
  }
}
