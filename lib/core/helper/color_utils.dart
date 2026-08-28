import 'package:flutter/material.dart';

class ColorUtils {
  /// Parses a hex color string (e.g. '#1E293B', '1E293B', or '#1E293BFF')
  static Color? parseHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    String clean = hexString.replaceAll('#', '').replaceAll(' ', '').trim().toUpperCase();
    if (clean.length == 6) {
      clean = 'FF$clean';
    } else if (clean.length == 3) {
      clean = 'FF${clean[0]}${clean[0]}${clean[1]}${clean[1]}${clean[2]}${clean[2]}';
    }
    if (clean.length != 8) return null;
    final val = int.tryParse(clean, radix: 16);
    if (val == null) return null;
    return Color(val);
  }

  /// Extracts hex codes from a color text like "Carbon Black (#18181B)" or "Nebula (#8B5CF6/#EC4899)"
  static List<Color> parseColorsFromText(String text) {
    final List<Color> colors = [];
    final regExp = RegExp(r'#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})');
    final matches = regExp.allMatches(text);

    for (final m in matches) {
      final hex = m.group(0);
      if (hex != null) {
        final c = parseHex(hex);
        if (c != null) colors.add(c);
      }
    }

    if (colors.isNotEmpty) return colors;

    // Fallback named colors
    final lower = text.toLowerCase();
    if (lower.contains('black') || lower.contains('obsidian') || lower.contains('dark')) {
      return [const Color(0xFF18181B)];
    } else if (lower.contains('silver') || lower.contains('chrome') || lower.contains('titanium') || lower.contains('grey') || lower.contains('gray')) {
      return [const Color(0xFF94A3B8)];
    } else if (lower.contains('blue') || lower.contains('navy') || lower.contains('cyan')) {
      return [const Color(0xFF3B82F6)];
    } else if (lower.contains('red') || lower.contains('crimson') || lower.contains('lava')) {
      return [const Color(0xFFEF4444)];
    } else if (lower.contains('green') || lower.contains('emerald') || lower.contains('mint')) {
      return [const Color(0xFF10B981)];
    } else if (lower.contains('purple') || lower.contains('violet') || lower.contains('nebula')) {
      return [const Color(0xFF8B5CF6)];
    } else if (lower.contains('pink') || lower.contains('rose')) {
      return [const Color(0xFFEC4899)];
    } else if (lower.contains('gold') || lower.contains('yellow') || lower.contains('amber') || lower.contains('sunset')) {
      return [const Color(0xFFF59E0B)];
    } else if (lower.contains('white') || lower.contains('pearl')) {
      return [const Color(0xFFF8FAFC)];
    }

    return [const Color(0xFF6366F1)]; // Default Indigo
  }

  /// Converts a Flutter Color to a Hex string like `#18181B`
  static String toHex(Color color, {bool includeAlpha = false}) {
    final a = ((color.a * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
    final r = ((color.r * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
    final g = ((color.g * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
    final b = ((color.b * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');

    if (includeAlpha) {
      return '#$a$r$g$b'.toUpperCase();
    }
    return '#$r$g$b'.toUpperCase();
  }

  /// Builds a visual circle or split gradient badge for single/dual mix colors
  static Widget buildColorIndicator(String colorText, {double size = 14}) {
    final colors = parseColorsFromText(colorText);

    if (colors.length >= 2) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors[0], colors[1]],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
    }

    final color = colors.isNotEmpty ? colors.first : const Color(0xFF6366F1);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
