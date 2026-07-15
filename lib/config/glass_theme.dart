import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTheme extends ThemeExtension<GlassTheme> {
  final Color glassColor;
  final Color glassBorderColor;
  final double glassOpacity;
  final double glassBorderOpacity;
  final double glassBlur;
  final double glassRadius;

  const GlassTheme({
    required this.glassColor,
    required this.glassBorderColor,
    required this.glassOpacity,
    required this.glassBorderOpacity,
    required this.glassBlur,
    required this.glassRadius,
  });

  static const light = GlassTheme(
    glassColor: Colors.white,
    glassBorderColor: Colors.white,
    glassOpacity: 0.15,
    glassBorderOpacity: 0.2,
    glassBlur: 10.0,
    glassRadius: 24.0,
  );

  static const dark = GlassTheme(
    glassColor: Colors.white,
    glassBorderColor: Colors.white,
    glassOpacity: 0.1,
    glassBorderOpacity: 0.08,
    glassBlur: 10.0,
    glassRadius: 24.0,
  );

  @override
  GlassTheme copyWith({
    Color? glassColor,
    Color? glassBorderColor,
    double? glassOpacity,
    double? glassBorderOpacity,
    double? glassBlur,
    double? glassRadius,
  }) {
    return GlassTheme(
      glassColor: glassColor ?? this.glassColor,
      glassBorderColor: glassBorderColor ?? this.glassBorderColor,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      glassBorderOpacity: glassBorderOpacity ?? this.glassBorderOpacity,
      glassBlur: glassBlur ?? this.glassBlur,
      glassRadius: glassRadius ?? this.glassRadius,
    );
  }

  @override
  GlassTheme lerp(GlassTheme? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      glassColor: Color.lerp(glassColor, other.glassColor, t) ?? glassColor,
      glassBorderColor: Color.lerp(glassBorderColor, other.glassBorderColor, t) ?? glassBorderColor,
      glassOpacity: lerpDouble(glassOpacity, other.glassOpacity, t) ?? glassOpacity,
      glassBorderOpacity: lerpDouble(glassBorderOpacity, other.glassBorderOpacity, t) ?? glassBorderOpacity,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t) ?? glassBlur,
      glassRadius: lerpDouble(glassRadius, other.glassRadius, t) ?? glassRadius,
    );
  }
}

class GlassWidget extends StatelessWidget {
  final Widget child;
  final double? blur;
  final double? opacity;
  final double? radius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GlassWidget({
    super.key,
    required this.child,
    this.blur,
    this.opacity,
    this.radius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassTheme>()!;
    final effectiveBlur = blur ?? glassTheme.glassBlur;
    final effectiveOpacity = opacity ?? glassTheme.glassOpacity;
    final effectiveRadius = radius ?? glassTheme.glassRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: glassTheme.glassColor.withValues(alpha: effectiveOpacity),
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: Border.all(
              color: glassTheme.glassBorderColor.withValues(alpha: glassTheme.glassBorderOpacity),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
