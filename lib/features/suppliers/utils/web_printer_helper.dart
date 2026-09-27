// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web implementation for printing HTML documents cleanly using an invisible iframe
bool printHtmlDocument(String htmlContent, {String title = 'Document'}) {
  try {
    // 1. Remove previous print iframe if present
    final oldIframe = web.document.getElementById('ego_print_iframe');
    oldIframe?.remove();

    // 2. Create invisible iframe attached to DOM
    final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.id = 'ego_print_iframe';
    iframe.style.position = 'fixed';
    iframe.style.right = '0';
    iframe.style.bottom = '0';
    iframe.style.width = '0';
    iframe.style.height = '0';
    iframe.style.border = '0';
    iframe.style.visibility = 'hidden';

    web.document.body?.appendChild(iframe);

    // 3. Set content and trigger print dialog smoothly
    iframe.srcdoc = htmlContent.toJS;

    Future.delayed(const Duration(milliseconds: 300), () {
      final contentWin = iframe.contentWindow;
      if (contentWin != null) {
        contentWin.focus();
        contentWin.print();
      }
    });

    return true;
  } catch (e) {
    debugPrint('Web print document error: $e');
    // Fallback to window.open if iframe approach fails
    try {
      final printWindow = web.window.open('', '_blank');
      if (printWindow != null) {
        printWindow.document.documentElement?.innerHTML = htmlContent.toJS;
        Future.delayed(const Duration(milliseconds: 350), () {
          printWindow.focus();
          printWindow.print();
        });
        return true;
      }
    } catch (_) {}
  }
  return false;
}

