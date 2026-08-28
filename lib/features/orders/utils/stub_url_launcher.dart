/// Stub for non-web platforms. This file is never imported on web.
bool openUrlInBrowser(String url, {String target = '_blank'}) {
  // Not applicable on non-web platforms; use url_launcher instead.
  return false;
}
