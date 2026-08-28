import 'package:flutter/material.dart';

/// Design tokens and semantic colors strictly matching UI_DESIGN_SYSTEM.md
class AppColor {
  AppColor._();

  // Primary & Accent Brand Tokens
  static const Color primary = Color(0xFF4B68FF); // Deep Royal Blue
  static const Color secondary = Color(0xFFFFE24B); // Vibrant Sun Yellow
  static const Color accent = Color(0xFFB0C7FF); // Soft Sky Blue

  // Dark Mode Surfaces
  static const Color darkCard = Color(0xFF141417);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSubCard = Color(0xFF1C1C22);
  static const Color darkChip = Color(0xFF222228);
  static const Color darkDialog = Color(0xFF16161A);
  static const Color darkDragHandle = Color(0xFF3F3F46);
  static const Color darkBorder = Color(0x14FFFFFF); // 8% White

  // Light Mode Surfaces
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F7FA);
  static const Color lightSubCard = Color(0xFFF9FAFB);
  static const Color lightChip = Color(0xFFF3F4F6);
  static const Color lightDialog = Color(0xFFFFFFFF);
  static const Color lightDragHandle = Color(0xFFD1D5DB);
  static const Color lightBorder = Color(0x14000000); // 8% Black

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF4F4F5);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color textMutedDark = Color(0xFF71717A);

  static const Color textPrimaryLight = Color(0xFF18181B);
  static const Color textSecondaryLight = Color(0xFF52525B);
  static const Color textMutedLight = Color(0xFFA1A1AA);

  // Order Status Semantic Tokens
  static const Color statusPending = Color(0xFFF97316); // Warm Orange
  static const Color statusProcessing = Color(0xFFA855F7); // Royal Purple
  static const Color statusShipped = Color(0xFF3B82F6); // Electric Blue
  static const Color statusOutForDelivery = Color(0xFFF59E0B); // Amber
  static const Color statusDelivered = Color(0xFF10B981); // Emerald Green
  static const Color statusCancelled = Color(0xFFEF4444); // Crimson Red

  // Additional Utilities
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
