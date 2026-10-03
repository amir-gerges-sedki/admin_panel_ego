import 'package:flutter/material.dart';

/// Design tokens and semantic colors strictly matching UI_DESIGN_SYSTEM.md
class AppColor {
  AppColor._();

  // Primary & Accent Brand Tokens (Calm, modern slate indigo & gentle warm amber)
  static const Color primary = Color(0xFF4F46E5); // Refined Indigo (Tailwind Indigo-600)
  static const Color primarySurface = Color(0xFFEEF2FF); // Indigo-50 for surface tints
  static const Color secondary = Color(0xFFF59E0B); // Warm Amber
  static const Color accent = Color(0xFF818CF8); // Soft Indigo Accent

  // Dark Mode Surfaces (Eye-friendly deep slate tones)
  static const Color darkCard = Color(0xFF161922);
  static const Color darkSurface = Color(0xFF0F1117);
  static const Color darkSubCard = Color(0xFF1E2230);
  static const Color darkChip = Color(0xFF252A3B);
  static const Color darkDialog = Color(0xFF161922);
  static const Color darkDragHandle = Color(0xFF475569);
  static const Color darkBorder = Color(0x18FFFFFF); // Subtle White border

  // Light Mode Surfaces (Clean, soft slate tones avoiding glaring white)
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8FAFC); // Slate-50 soft surface
  static const Color lightSubCard = Color(0xFFF1F5F9); // Slate-100
  static const Color lightChip = Color(0xFFE2E8F0); // Slate-200
  static const Color lightDialog = Color(0xFFFFFFFF);
  static const Color lightDragHandle = Color(0xFFCBD5E1);
  static const Color lightBorder = Color(0xFFE2E8F0); // Crisp Slate-200 border

  // Text Colors (High readability without harsh piercing glare)
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate-50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate-400
  static const Color textMutedDark = Color(0xFF64748B); // Slate-500

  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate-900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate-600
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate-400

  // Order & Status Semantic Tokens
  static const Color statusPending = Color(0xFFF97316); // Warm Orange
  static const Color statusProcessing = Color(0xFF8B5CF6); // Soft Purple
  static const Color statusShipped = Color(0xFF3B82F6); // Balanced Blue
  static const Color statusOutForDelivery = Color(0xFFF59E0B); // Amber
  static const Color statusDelivered = Color(0xFF10B981); // Emerald Green
  static const Color statusCancelled = Color(0xFFEF4444); // Crimson Red

  // Additional Utilities
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
