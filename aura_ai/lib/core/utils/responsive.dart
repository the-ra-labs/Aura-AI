import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet, desktop }

class Responsive {
  static ScreenType of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1100) return ScreenType.desktop;
    if (w >= 700) return ScreenType.tablet;
    return ScreenType.mobile;
  }
}