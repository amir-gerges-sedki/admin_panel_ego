// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Web browser implementation for automatic file download using HTMLAnchorElement
Future<bool> saveOrDownloadFile({
  required String fileName,
  required String content,
  String mimeType = 'text/csv;charset=utf-8',
}) async {
  try {
    final bytes = utf8.encode(content);
    // Add UTF-8 BOM so Excel opens Arabic and UTF-8 characters properly
    final bom = [0xEF, 0xBB, 0xBF];
    final allBytes = Uint8List.fromList([...bom, ...bytes]);
    final base64Data = base64Encode(allBytes);
    final dataUri = 'data:$mimeType;base64,$base64Data';

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = dataUri;
    anchor.download = fileName;
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    return true;
  } catch (_) {
    return false;
  }
}
