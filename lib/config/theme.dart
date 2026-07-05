import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const purple = Color(0xFF6C5CE7);
  static const purpleLight = Color(0xFF8E7CF0);
  static const purpleDark = Color(0xFF5244C2);
  static const green = Color(0xFF4CAF82);
  static const greenLight = Color(0xFF6FC49D);
  static const black = Color(0xFF1A1A2E);
  static const grey = Color(0xFF8E8EA0);
  static const greyLight = Color(0xFFE0E0E6);
  static const white = Color(0xFFF7F7FA);
  static const whitePure = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF8E8EA0);
  static const textTertiary = Color(0xFFB0B0C0);
  static const surface = Color(0xFFF2F2F7);
  static const border = Color(0xFFE8E8ED);
}

class AppGradients {
  static const purpleGradient = LinearGradient(
    colors: [AppColors.purple, AppColors.purpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const greenGradient = LinearGradient(
    colors: [AppColors.green, AppColors.greenLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkOverlay = LinearGradient(
    colors: [Colors.transparent, Colors.black26, Colors.black54],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppDecorations {
  static BoxDecoration glass({
    double opacity = 0.15,
    double radius = 24,
  }) {
    return BoxDecoration(
      color: AppColors.whitePure.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.whitePure.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }

  static BoxDecoration glassDark({
    double opacity = 0.1,
    double radius = 24,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1,
      ),
    );
  }

  static BoxDecoration elevatedCard({Color? shadowColor, double radius = 24}) {
    return BoxDecoration(
      color: AppColors.whitePure,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: (shadowColor ?? AppColors.black).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static ButtonStyle get elevatedButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.purple,
    foregroundColor: Colors.white,
    elevation: 2,
    shadowColor: AppColors.purple.withValues(alpha: 0.3),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

class AppTheme {
  static ThemeData light() {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.white,
      textTheme: textTheme,
      colorScheme: ColorScheme.light(
        primary: AppColors.purple,
        secondary: AppColors.green,
        surface: AppColors.white,
        error: AppColors.green,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.black,
        ),
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      cardTheme: CardThemeData(
        color: AppColors.whitePure,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F8),
        hintStyle: GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.black.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.purple,
          side: const BorderSide(color: AppColors.purple, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purple,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      dividerColor: AppColors.greyLight,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppColors.black,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      ),
    );
  }

  static ThemeData dark() {
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      textTheme: textTheme,
      colorScheme: ColorScheme.dark(
        primary: AppColors.purpleLight,
        secondary: AppColors.green,
        surface: const Color(0xFF161B22),
        error: const Color(0xFFFB7185),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2333),
        hintStyle: GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.purpleLight, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purpleLight,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.black.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.purpleLight,
          side: const BorderSide(color: AppColors.purpleLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purpleLight,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      dividerColor: const Color(0xFF30363D),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white,
        contentTextStyle: GoogleFonts.poppins(color: AppColors.black, fontSize: 13),
      ),
    );
  }
}

class GlassWidget extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GlassWidget({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.15,
    this.radius = 24,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
