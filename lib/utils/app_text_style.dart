import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
  static double _getResponsiveFontSize(double baseSize) {
    const double baseScreenHeight = 844.0;

    double scaleFactor = Get.height / baseScreenHeight;

    return baseSize * scaleFactor.clamp(0.8, 1.5);
  }

  /// Poppins - Bold (FontWeight.w700)
  static TextStyle boldText({required double size, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: _getResponsiveFontSize(size),
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  /// Poppins - SemiBold (FontWeight.w600)
  static TextStyle semiBoldText({required double size, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: _getResponsiveFontSize(size),
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  /// Poppins - Medium (FontWeight.w500)
  static TextStyle mediumText({required double size, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: _getResponsiveFontSize(size),
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  /// Poppins - Regular (FontWeight.w400)
  static TextStyle regularText({required double size, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: _getResponsiveFontSize(size),
      fontWeight: FontWeight.w400,
      color: color,
    );
  }
}
