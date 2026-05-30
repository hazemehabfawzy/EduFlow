// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Central color palette for SkillNest.
/// All colors are defined here — never hardcode elsewhere.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF6C63FF); // indigo-violet
  static const Color primaryDark    = Color(0xFF4B44CC);
  static const Color secondary      = Color(0xFFFF6584); // coral accent
  static const Color accent         = Color(0xFF48CAE4); // sky blue

  // ── Gradient stops ────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light surface ─────────────────────────────────────────────────────────
  static const Color surfaceLight   = Color(0xFFF8F9FF);
  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color borderLight    = Color(0xFFE8E8F0);
  static const Color textPrimary    = Color(0xFF0D0D0D);
  static const Color textSecondary  = Color(0xFF4A5568);
  static const Color textHint       = Color(0xFFB0B8C4);

  // ── Dark surface ──────────────────────────────────────────────────────────
  static const Color surfaceDark    = Color(0xFF1A1A2E);
  static const Color cardDark       = Color(0xFF16213E);
  static const Color borderDark     = Color(0xFF2A2A4A);

  // ── Semantics ─────────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF10B981);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color error          = Color(0xFFEF4444);
  static const Color info           = Color(0xFF3B82F6);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const Color white          = Color(0xFFFFFFFF);
  static const Color black          = Color(0xFF000000);
  static const Color transparent    = Color(0x00000000);
  static const Color overlay        = Color(0x80000000);
}
