/// Pure Dart Code-128 Barcode Generator (Subtype B/Auto)
/// Generates standard, crisp vector SVG barcodes scannable by any 1D/2D POS barcode scanner.
class Barcode128Generator {
  Barcode128Generator._();

  static const List<String> _patterns = [
    "212222", "222122", "222221", "121223", "121322", "131222", "122213", "122312", "132212", "221213", // 0-9
    "221312", "231212", "112232", "122132", "122231", "113222", "123122", "123221", "223211", "221132", // 10-19
    "221231", "213212", "223112", "312131", "311222", "321122", "321221", "312212", "322112", "322211", // 20-29
    "212123", "212321", "232121", "111323", "131123", "131321", "112313", "132113", "132311", "211313", // 30-39
    "231113", "231311", "112133", "112331", "132131", "113123", "113321", "133121", "313121", "211331", // 40-49
    "231131", "213113", "213311", "213131", "311123", "311321", "331121", "312113", "312311", "332111", // 50-59
    "314111", "221411", "431111", "111224", "111422", "121124", "121421", "141122", "141221", "112214", // 60-69
    "112412", "122114", "122411", "142112", "142211", "241211", "221114", "413111", "241112", "134111", // 70-79
    "111242", "121142", "121241", "114212", "124112", "124211", "411212", "421112", "421211", "212141", // 80-89
    "214121", "412121", "111143", "111341", "131141", "114113", "114311", "411113", "411311", "113141", // 90-99
    "114131", "311141", "411131", "211412", "211214", "211232", "2331112" // 100-106
  ];

  static const int _startB = 104;
  static const int _stop = 106;

  /// Generates clean vector SVG markup for the given text (SKU/Code)
  static String generateSvg(
    String rawText, {
    double width = 180,
    double height = 50,
    bool showText = true,
    double fontSize = 11,
    String barColor = '#000000',
    String backgroundColor = '#ffffff',
  }) {
    final text = rawText.trim().isEmpty ? '000000' : rawText.trim();
    final List<int> values = [];

    // Filter valid ASCII printable characters (32 to 126)
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 32 && code <= 126) {
        values.add(code - 32);
      } else {
        // Fallback for non-ascii characters
        values.add(0);
      }
    }

    if (values.isEmpty) {
      values.add(0);
    }

    // Calculate Code-128 checksum
    int checksum = _startB;
    for (int i = 0; i < values.length; i++) {
      checksum += values[i] * (i + 1);
    }
    checksum = checksum % 103;

    // Full symbol stream: [Start B, ...values, Checksum, Stop]
    final symbols = <int>[_startB, ...values, checksum, _stop];

    // Build binary module string (1 = bar, 0 = space)
    final modules = StringBuffer();
    for (final sym in symbols) {
      final pattern = _patterns[sym];
      bool isBar = true;
      for (int i = 0; i < pattern.length; i++) {
        final count = int.parse(pattern[i]);
        for (int c = 0; c < count; c++) {
          modules.write(isBar ? '1' : '0');
        }
        isBar = !isBar;
      }
    }

    final moduleString = modules.toString();
    final totalModules = moduleString.length;
    final quietZone = 10; // 10 modules margin on left & right
    final totalWidth = totalModules + (quietZone * 2);

    final barHeight = showText ? (height - fontSize - 6).clamp(15.0, height) : height;

    final svgBuffer = StringBuffer();
    svgBuffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalWidth $height" width="$width" height="$height" style="background-color: $backgroundColor; display: block; margin: 0 auto;">',
    );

    // Render bars
    int currentX = quietZone;
    for (int i = 0; i < totalModules; i++) {
      if (moduleString[i] == '1') {
        // Lookahead to combine adjacent 1s into single rect for performance & rendering sharpness
        int barWidth = 1;
        while (i + 1 < totalModules && moduleString[i + 1] == '1') {
          barWidth++;
          i++;
        }
        svgBuffer.writeln(
          '  <rect x="$currentX" y="2" width="$barWidth" height="$barHeight" fill="$barColor" shape-rendering="crispEdges" />',
        );
        currentX += barWidth;
      } else {
        currentX++;
      }
    }

    // Render readable alphanumeric text underneath
    if (showText) {
      final textY = height - 2;
      svgBuffer.writeln(
        '  <text x="${totalWidth / 2}" y="$textY" font-family="monospace, sans-serif" font-size="$fontSize" font-weight="700" fill="$barColor" text-anchor="middle" letter-spacing="1.5px">${_escapeXml(text)}</text>',
      );
    }

    svgBuffer.writeln('</svg>');
    return svgBuffer.toString();
  }

  static String _escapeXml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
