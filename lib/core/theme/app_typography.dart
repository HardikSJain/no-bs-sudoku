import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // Numbers — DM Mono, the signature typeface
  static TextStyle number = GoogleFonts.dmMono(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
  );

  static TextStyle numberSmall = GoogleFonts.dmMono(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.1,
  );

  // UI text — Space Mono
  static TextStyle heading = GoogleFonts.spaceMono(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle label = GoogleFonts.spaceMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static TextStyle labelSmall = GoogleFonts.spaceMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  static TextStyle body = GoogleFonts.spaceMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle button = GoogleFonts.spaceMono(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle wordmark = GoogleFonts.dmMono(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
  );
}
