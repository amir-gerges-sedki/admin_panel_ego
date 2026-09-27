import 'package:flutter/foundation.dart';

/// Non-web fallback stub for printing HTML documents
bool printHtmlDocument(String htmlContent, {String title = 'Document'}) {
  debugPrint('HTML printing is only supported directly in web browser engine.');
  return false;
}
