
import 'package:flutter/material.dart';

import 'dart:ui';
const String primaryColorBlue = "006FDD";

class GradientHelper {
  /// Main App Gradient (Reusable everywhere)
  static LinearGradient mainGradient() {
    return const LinearGradient(
      colors: [
        Color(0xff6553A3),
        Color(0xff9451A0),
        Color(0xffC94B9B),
        Color(0xffEE346B),
        Color(0xffF15C22),
        Color(0xffF15C22),
        Color(0xffFECD06),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Reusable for different directions
  static LinearGradient customGradient({
    required List<Color> colors,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
    );
  }
}

class ColorUtils {
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  //
  static Color get primaryBlue => hexToColor(primaryColorBlue);

}


