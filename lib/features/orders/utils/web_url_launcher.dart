// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

/// Opens a URL in the browser using JavaScript window.open().
/// This must be called SYNCHRONOUSLY from a user gesture handler
/// to avoid popup blockers in Chrome/Edge/Safari.
bool openUrlInBrowser(String url, {String target = '_blank'}) {
  try {
    web.window.open(url, target);
    return true;
  } catch (_) {
    return false;
  }
}
