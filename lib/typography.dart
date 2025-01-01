import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class T {
  //--- WHITE ---
  static const Color white_0 = Color(0xFFFFFFFF);
  static const Color white_1 = Color(0xFFD9D9D9);

  //--- GREY ---
  static const Color grey_0 = Color(0xFFC8C8C8);
  static const Color grey_1 = Color(0xFF9B9BA1);

  //--- BLACK ---
  static const Color black_0 = Color(0xFF000000);
  static const Color black_1 = Color(0xFF1E1E1E);

  //--- PURPLE ---
  static const Color purple_0 = Color(0xFFEB15C0);
  static const Color purple_1 = Color(0xFFBC15EB);
  static const Color purple_2 = Color(0xFF9638A8);

  //--- VIOLET ---
  static const Color violet_0 = Color(0xFF7515EB);
  static const Color violet_1 = Color(0xFF5454B8);
  static const Color violet_2 = Color(0xFFA063EB);
  static const Color violet_3 = Color(0xFF2F1E66);

  //--- BLUE ---
  static const Color blue_0 = Color(0xFF1540EB);
  static const Color blue_1 = Color(0xFF2E15EB);

  //--- GRADIENT ---
  static const gradient_0 = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF2E15EB), // #2E15EB
      Color(0xFF7515EB), // #7515EB
      Color(0xFF9638A8), // #9638A8
    ],
    stops: [0.0, 0.485, 1.0],
  );

  static const gradient_1 = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF1D0D9A), // #1D0D9A
      Color(0xFF3D15EB), // #3D15EB
      Color(0xFF7515EB), // #7515EB
      Color(0xFF9638A8), // #9638A8
    ],
    stops: [0.0, 0.21, 0.455, 0.745],
  );
  //--- GRADIENT ---

  //--- HEADING ---
  static final TextStyle h1 = GoogleFonts.alegreya(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.3, // line-height: 44px / 34px = 1.3
    color: black_0,
  );

  static final TextStyle h2 = GoogleFonts.alegreya(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29, // line-height: 36px / 28px = 1.29
    color: black_0,
  );

  static final TextStyle h3 = GoogleFonts.alegreya(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.45, // line-height: 32px / 22px = 1.45
    color: black_0,
  );
  //--- HEADING ---

  //--- BODY ---
  static final TextStyle bodyLarge = GoogleFonts.alegreya(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.75, // line-height: 28px / 16px = 1.75
    color: black_0,
  );

  static final TextStyle bodyLargeBold = GoogleFonts.alegreya(
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    height: 1.75, // line-height: 28px / 16px = 1.75
    color: black_0,
  );

  static final TextStyle bodyRegular = GoogleFonts.alegreya(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.71, // line-height: 24px / 14px = 1.71
    color: black_0,
  );

  static final TextStyle bodyRegularBold = GoogleFonts.alegreya(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    height: 1.71, // line-height: 24px / 14px = 1.71
    color: black_0,
  );
  //--- BODY ---

  //--- CAPTION ---
  static final TextStyle captionSmall = GoogleFonts.alegreya(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.67, // line-height: 20px / 12px = 1.67
    color: black_0,
  );

  static final TextStyle captionSmallBold = GoogleFonts.alegreya(
    fontSize: 12.0,
    fontWeight: FontWeight.w700,
    height: 1.67, // line-height: 20px / 12px = 1.67
    color: black_0,
  );
  //--- CAPTION ---

  //--- BUTTON ---
  static ButtonStyle buttonStandard = ElevatedButton.styleFrom(
    backgroundColor: violet_0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  );

  //  static ButtonStyle buttonGradient = ElevatedButton.styleFrom(
  //   backgroundColor: Colors.transparent,
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.circular(12.0),
  //   ),
  //   overlayColor: MaterialStateProperty.all(Colors.transparent),
  // );
}
