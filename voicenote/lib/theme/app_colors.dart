import 'package:flutter/material.dart';

/// VoiceNote 墨綠主題色票。
///
/// 1:1 對應設計稿 `VoiceNote 操作流程概念圖.html` 的 Material 3 token，
/// 呼應「離線、隱私、沉穩」的產品定位（主色 #1F5D4C）。
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF1F5D4C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFB6F0D8);
  static const Color onPrimaryContainer = Color(0xFF00201A);

  // Secondary
  static const Color secondary = Color(0xFF4D6358);
  static const Color secondaryContainer = Color(0xFFCFE9D9);
  static const Color onSecondaryContainer = Color(0xFF0A1F17);

  // Tertiary
  static const Color tertiary = Color(0xFF3D6373);
  static const Color tertiaryContainer = Color(0xFFC1E8FB);

  // Surfaces
  static const Color surface = Color(0xFFF6FBF6);
  static const Color surfaceDim = Color(0xFFD6DBD5);
  static const Color surfaceBright = Color(0xFFFBFDF8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F5EF);
  static const Color surfaceContainer = Color(0xFFEAEFE9);
  static const Color surfaceContainerHigh = Color(0xFFE4EAE3);
  static const Color surfaceContainerHighest = Color(0xFFDFE4DD);

  // On-surface / outline
  static const Color onSurface = Color(0xFF181D1A);
  static const Color onSurfaceVariant = Color(0xFF404943);
  static const Color outline = Color(0xFF707974);
  static const Color outlineVariant = Color(0xFFC0C9C2);

  // Status
  static const Color error = Color(0xFFBA1A1A);

  // 報告頁背景（僅供概念圖；App 內使用 surface）
  static const Color pageBg = Color(0xFFEEF3EC);
}