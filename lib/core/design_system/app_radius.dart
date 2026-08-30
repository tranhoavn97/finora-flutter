import 'package:flutter/material.dart';

class AppRadius {
  static const double xs = 10.0;
  static const double sm = 14.0;
  static const double md = 18.0;
  static const double lg = 22.0;
  static const double xl = 28.0;
  static const double xxl = 32.0;
  static const double pill = 50.0;

  // BorderRadius shortcuts
  static final BorderRadius radiusXS = BorderRadius.circular(xs);
  static final BorderRadius radiusSM = BorderRadius.circular(sm);
  static final BorderRadius radiusMD = BorderRadius.circular(md);
  static final BorderRadius radiusLG = BorderRadius.circular(lg);
  static final BorderRadius radiusXL = BorderRadius.circular(xl);
  static final BorderRadius radiusXXL = BorderRadius.circular(xxl);
  static final BorderRadius radiusPill = BorderRadius.circular(pill);

  // Component standard configurations
  static final BorderRadius button = BorderRadius.circular(20.0);
  static final BorderRadius input = BorderRadius.circular(20.0);
  static final BorderRadius card = BorderRadius.circular(24.0);
  static final BorderRadius cardLarge = BorderRadius.circular(28.0);
  static final BorderRadius modal = BorderRadius.circular(28.0);
  static final BorderRadius dialog = BorderRadius.circular(28.0);
  static final BorderRadius bottomSheet = const BorderRadius.only(
    topLeft: Radius.circular(30.0),
    topRight: Radius.circular(30.0),
  );
}
