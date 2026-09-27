import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/helper/helper_fun.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/models/order_model.dart';
import 'stub_url_launcher.dart'
    if (dart.library.js_interop) 'web_url_launcher.dart' as web_launcher;

import '../domain/share_formatter_strategy.dart';

class OrderShareHelper {
  OrderShareHelper._();

  static const _courierSlipStrategy = CourierSlipShareStrategy();

  /// Build direct Google Maps search URL from shipping address
  static String buildGoogleMapsUrl(ShippingAddressModel addr) {
    return CourierSlipShareStrategy.buildGoogleMapsUrl(addr);
  }

  /// Generates clean, well-formatted plain text ready for delivery couriers
  static String generateCourierSlipText(OrderModel order) {
    return _courierSlipStrategy.format(order);
  }

  /// Generates consolidated, well-formatted plain text for multiple orders ready for delivery couriers
  static String generateBulkCourierSlipsText(List<OrderModel> orders) {
    if (orders.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('📦 كشف شحنات مجمعة - متجر EGO Store');
    buffer.writeln('عدد الشحنات: ${orders.length}');
    buffer.writeln('تاريخ التجهيز: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('═' * 38);
    for (int i = 0; i < orders.length; i++) {
      buffer.writeln('\n[شحنة #${i + 1}]');
      buffer.writeln(generateCourierSlipText(orders[i]));
      buffer.writeln('-' * 32);
    }
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
