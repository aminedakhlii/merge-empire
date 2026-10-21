import 'package:flutter/material.dart';

/// Cozy coffee-shop palette for Phase 1.
abstract final class MergeEmpireTheme {
  static const Color espresso = Color(0xFF2C1810);
  static const Color roast = Color(0xFF5C3A21);
  static const Color caramel = Color(0xFFB8793A);
  static const Color foam = Color(0xFFF3E6D4);
  static const Color cream = Color(0xFFFFF8EF);
  static const Color leaf = Color(0xFF3D6B4F);
  static const Color coin = Color(0xFFD4A017);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: roast,
        brightness: Brightness.light,
        primary: roast,
        secondary: caramel,
        surface: cream,
        onPrimary: cream,
        onSurface: espresso,
      ),
      scaffoldBackgroundColor: cream,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: espresso,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: espresso,
        displayColor: espresso,
      ),
    );
  }

  /// Ordered level hues (also labeled with level number / name in UI).
  static Color levelColor(int level, {String chainId = 'coffee'}) {
    if (chainId == 'pastry') {
      const pastry = <Color>[
        Color(0xFFE8D5B7),
        Color(0xFFD4A574),
        Color(0xFFC4894A),
        Color(0xFFB56B3A),
        Color(0xFFA0522D),
        Color(0xFF8B4513),
        Color(0xFFCD853F),
        Color(0xFFDEB887),
        Color(0xFFD2691E),
        Color(0xFF5C3A21),
      ];
      if (level < 1 || level > pastry.length) return caramel;
      return pastry[level - 1];
    }
    const palette = <Color>[
      Color(0xFF8B5E3C),
      Color(0xFF9A6B45),
      Color(0xFFB07A3A),
      Color(0xFFC48A4A),
      Color(0xFF6F4E37),
      Color(0xFF5A3A28),
      Color(0xFFD4A574),
      Color(0xFFE8C9A0),
      Color(0xFF3D6B4F),
      Color(0xFF2C1810),
    ];
    if (level < 1 || level > palette.length) return caramel;
    return palette[level - 1];
  }
}
