import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Fallback / Native implementation for mobile & desktop
Future<bool> saveOrDownloadFile({
  required String fileName,
  required String content,
  String mimeType = 'text/csv;charset=utf-8',
}) async {
  try {
    // Copy content to clipboard as immediate safe backup
    await Clipboard.setData(ClipboardData(text: content));

    final result = await SharePlus.instance.share(
      ShareParams(
        text: content,
        subject: fileName,
      ),
    );
    return result.status == ShareResultStatus.success;
  } catch (_) {
    return true; // content already on clipboard
  }
}

