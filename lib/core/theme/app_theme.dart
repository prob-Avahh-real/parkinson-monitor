import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 应用主题
class AppTheme {
  AppTheme._();

  // 品牌色
  static const Color primaryColor = Color(0xFF2E7D32); // 深绿 — 健康/行走
  static const Color secondaryColor = Color(0xFF66BB6A);
  static const Color accentColor = Color(0xFFFF6F00); // 橙色 — 警示
  static const Color dangerColor = Color(0xFFD32F2F); // 红色 — 严重
  static const Color warningColor = Color(0xFFFFA000);
  static const Color infoColor = Color(0xFF1976D2);

  // 运动障碍状态色
  static const Color fogColor = Color(0xFFD32F2F); // FoG - 红
  static const Color tremorColor = Color(0xFFFF6F00); // 震颤 - 橙
  static const Color bradyColor = Color(0xFFFDD835); // 运动迟缓 - 黄
  static const Color normalColor = Color(0xFF2E7D32); // 正常 - 绿

  // 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      textTheme: GoogleFonts.notoSansTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// 获取状态色
  static Color statusColor(String status) {
    switch (status) {
      case 'fog':
        return fogColor;
      case 'tremor':
        return tremorColor;
      case 'brady':
        return bradyColor;
      case 'normal':
        return normalColor;
      default:
        return Colors.grey;
    }
  }
}
