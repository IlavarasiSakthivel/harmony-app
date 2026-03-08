import 'package:flutter/material.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';

class TextStyles {
  // Font sizes matching Tailwind
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double base = 16.0;
  static const double lg = 18.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;

  // Common text styles
  static TextStyle titleLarge = TextStyle(
    fontSize: xxl,
    fontWeight: FontWeight.w700,
    color: TWColors.slate900,
  );

  static TextStyle titleMedium = TextStyle(
    fontSize: xl,
    fontWeight: FontWeight.w600,
    color: TWColors.slate800,
  );

  static TextStyle bodyLarge = TextStyle(
    fontSize: lg,
    fontWeight: FontWeight.w500,
    color: TWColors.slate700,
  );

  static TextStyle bodyMedium = TextStyle(
    fontSize: base,
    fontWeight: FontWeight.w400,
    color: TWColors.slate600,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: sm,
    fontWeight: FontWeight.w400,
    color: TWColors.slate500,
  );

  static TextStyle caption = TextStyle(
    fontSize: xs,
    fontWeight: FontWeight.w400,
    color: TWColors.slate400,
  );
}

// Alternative: Use functions like original TWText
class TWText {
  static TextStyle xs({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: 12,
      color: color ?? TWColors.slate400,
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }

  static TextStyle sm({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: 14,
      color: color ?? TWColors.slate500,
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }

  static TextStyle base({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: 16,
      color: color ?? TWColors.slate600,
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }

  static TextStyle lg({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: 18,
      color: color ?? TWColors.slate700,
      fontWeight: fontWeight ?? FontWeight.w500,
    );
  }

  static TextStyle xl({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: 20,
      color: color ?? TWColors.slate800,
      fontWeight: fontWeight ?? FontWeight.w600,
    );
  }

  static TextStyle xxl({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: 24,
      color: color ?? TWColors.slate900,
      fontWeight: fontWeight ?? FontWeight.w700,
    );
  }
}