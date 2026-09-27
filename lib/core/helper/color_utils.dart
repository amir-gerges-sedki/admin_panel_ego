import 'package:flutter/material.dart';
import '../algorithms/memoization_cache.dart';

class ColorUtils {
  static final MemoizationCache<String, List<Color>> _colorParseCache =
      MemoizationCache<String, List<Color>>(capacity: 250);
  static final MemoizationCache<Color, String> _hexConvertCache =
      MemoizationCache<Color, String>(capacity: 250);

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

  /// Extracts hex codes from a color text like "Carbon Black (#18181B)" or "Nebula (#8B5CF6/#EC4899)" with memoization.
  static List<Color> parseColorsFromText(String text) {
    return _colorParseCache.getOrCompute(text, (key) {
      final List<Color> colors = [];
      final regExp = RegExp(r'#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})');
      final matches = regExp.allMatches(key);

      for (final m in matches) {
        final hex = m.group(0);
        if (hex != null) {
          final c = parseHex(hex);
          if (c != null) colors.add(c);
        }
      }

      if (colors.isNotEmpty) return colors;

      // Fallback named colors
      final lower = key.toLowerCase();
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
    });
  }

  /// Converts a Flutter Color to a Hex string like `#18181B` with memoization.
  static String toHex(Color color, {bool includeAlpha = false}) {
    if (includeAlpha) {
      final a = ((color.a * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
      final r = ((color.r * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
      final g = ((color.g * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
      final b = ((color.b * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
      return '#$a$r$g$b'.toUpperCase();
    }

    return _hexConvertCache.getOrCompute(color, (c) {
      final r = ((c.r * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
      final g = ((c.g * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
      final b = ((c.b * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
      return '#$r$g$b'.toUpperCase();
    });
  }

  /// Returns a clean human-readable color label without ugly raw hex codes when possible
  static String getReadableColorName(String colorText) {
    final clean = colorText.trim();
    if (clean.isEmpty) return '';

    // If it has a name before parentheses like "Midnight Blue (#1E3A8A)"
    final parenMatch = RegExp(r'^(.*?)\s*\((#[0-9A-Fa-f]{3,8}(?:\/#[0-9A-Fa-f]{3,8})?)\)$').firstMatch(clean);
    if (parenMatch != null) {
      final name = parenMatch.group(1)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }

    // If it is just a hex code like "#18181B" or "#FFFFFF"
    if (clean.startsWith('#')) {
      final hex = clean.toUpperCase();
      if (hex == '#000000' || hex == '#18181B' || hex == '#0F172A' || hex == '#1E293B') return 'أسود (Black)';
      if (hex == '#FFFFFF' || hex == '#F8FAFC') return 'أبيض (White)';
      if (hex == '#94A3B8' || hex == '#CBD5E1' || hex == '#64748B') return 'فضي / رمادي (Silver)';
      if (hex == '#3B82F6' || hex == '#2563EB' || hex == '#1D4ED8' || hex == '#0EA5E9') return 'أزرق (Blue)';
      if (hex == '#EF4444' || hex == '#DC2626' || hex == '#B91C1C') return 'أحمر (Red)';
      if (hex == '#10B981' || hex == '#059669' || hex == '#047857') return 'أخضر (Green)';
      if (hex == '#8B5CF6' || hex == '#7C3AED' || hex == '#6366F1') return 'بنفسجي (Purple)';
      if (hex == '#EC4899' || hex == '#DB2777' || hex == '#F43F5E') return 'وردي (Pink)';
      if (hex == '#F59E0B' || hex == '#D97706' || hex == '#EAB308') return 'ذهبي / أصفر (Gold)';
      return clean;
    }

    return clean;
  }

  /// Builds a complete visual badge with the color circle preview + readable label
  static Widget buildColorBadge(
    String colorText, {
    double size = 14,
    bool isDark = false,
    bool showLabel = true,
  }) {
    final name = getReadableColorName(colorText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildColorIndicator(colorText, size: size),
          if (showLabel && name.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
          ],
        ],
      ),
    );
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
          border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.35),
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
        border: Border.all(
          color: color.computeLuminance() > 0.8
              ? Colors.black.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
