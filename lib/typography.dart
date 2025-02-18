import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A centralized style and color palette for consistent app theming.
class T {
  // White
  static const Color white_0 = Color(0xFFFFFFFF);
  static const Color white_1 = Color(0xFFD9D9D9);

  // Grey
  static const Color grey_0 = Color(0xFFC8C8C8);
  static const Color grey_1 = Color(0xFF9B9BA1);
  static const Color grey_2 = Color(0xFFEAECF0);

  // Black
  static const Color black_0 = Color(0xFF000000);
  static const Color black_1 = Color(0xFF1E1E1E);

  // Purple
  static const Color purple_0 = Color(0xFFEB15C0);
  static const Color purple_1 = Color(0xFFBC15EB);
  static const Color purple_2 = Color(0xFF9638A8);

  // Violet
  static const Color violet_0 = Color(0xFF7515EB);
  static const Color violet_1 = Color(0xFF5454B8);
  static const Color violet_2 = Color(0xFFA063EB);
  static const Color violet_3 = Color(0xFF2F1E66);

  // Blue
  static const Color blue_0 = Color(0xFF1540EB);
  static const Color blue_1 = Color(0xFF2E15EB);

  // Gradient
  static const gradient_0 = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF2E15EB),
      Color(0xFF7515EB),
      Color(0xFF9638A8),
    ],
    stops: [0.0, 0.485, 1.0],
  );

  // Headings
  static final TextStyle h1 = GoogleFonts.alegreya(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: black_0,
  );

  static final TextStyle h2 = GoogleFonts.alegreya(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29,
    color: black_0,
  );

  static final TextStyle h3 = GoogleFonts.alegreya(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: black_0,
  );

  // Body
  static final TextStyle bodyLarge = GoogleFonts.alegreya(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.75,
    color: black_0,
  );

  static final TextStyle bodyLargeBold = GoogleFonts.alegreya(
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    height: 1.75,
    color: black_0,
  );

  static final TextStyle bodyRegular = GoogleFonts.alegreya(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.71,
    color: black_0,
  );

  static final TextStyle bodyRegularBold = GoogleFonts.alegreya(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    height: 1.71,
    color: black_0,
  );

  // Captions
  static final TextStyle captionSmall = GoogleFonts.alegreya(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.67,
    color: black_0,
  );

  static final TextStyle captionSmallBold = GoogleFonts.alegreya(
    fontSize: 12.0,
    fontWeight: FontWeight.w700,
    height: 1.67,
    color: black_0,
  );

  // Used specifically for calendar day numbers
  static final TextStyle calendarNumbers = GoogleFonts.anonymousPro(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    height: 1.4,
    color: black_0,
  );

  // Button styles
  static ButtonStyle buttonStandard = ElevatedButton.styleFrom(
    backgroundColor: violet_0,
    foregroundColor: white_0,
    textStyle: h3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    minimumSize: const Size(350, 50),
  );
}


